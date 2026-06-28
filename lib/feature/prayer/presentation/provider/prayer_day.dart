import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/logging/logger_provider.dart';
import 'package:tawaq/core/utils/date_formatter.dart';
import 'package:tawaq/feature/prayer/data/repository/prayer_repo.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_day_bundle.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_day_snapshot.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_time_inputs.dart';
import 'package:tawaq/feature/prayer/domain/prayer_calendar.dart';
import 'package:tawaq/feature/prayer/domain/prayer_slots.dart';
import 'package:tawaq/feature/prayer/domain/services/prayer_day_computer.dart';
import 'package:tawaq/feature/settings/data/models/prayer_settings_model.dart';
import 'package:tawaq/feature/settings/presentation/provider/prayer_settings_provider.dart';
import 'package:timezone/timezone.dart';

part 'prayer_day.g.dart';

const _tickInterval = Duration(seconds: 1);

/// Synchronous prayer settings safe for time math and completions.
///
/// Returns the hydrated settings when location is ready, otherwise the last
/// good stored settings. Null when no valid coordinates exist yet.
@Riverpod(keepAlive: true)
PrayerSettings? effectivePrayerSettings(Ref ref) {
  ref.watch(prayerSettingsProvider);
  final current = ref.read(prayerSettingsProvider).value;
  if (current != null && current.isLocationReady) return current;
  final lastGood = ref.read(prayerSettingsProvider.notifier).lastGood;
  if (lastGood.isLocationReady) return lastGood;
  return null;
}

/// Whether settings have loaded but coordinates are still unset (0,0 sentinel).
@Riverpod(keepAlive: true)
bool prayerLocationSetupNeeded(Ref ref) {
  final settings = ref.watch(prayerSettingsProvider);
  if (settings.isLoading) return false;
  return ref.watch(effectivePrayerSettingsProvider) == null;
}

/// Narrow projection of persisted prayer settings used for time math.
@Riverpod(keepAlive: true)
PrayerTimeInputs? prayerTimeInputs(Ref ref) {
  final settings = ref.watch(effectivePrayerSettingsProvider);
  if (settings == null) return null;
  return PrayerTimeInputs(
    method: settings.method,
    coordinates: settings.coordinates,
    location: settings.location,
  );
}

/// Single live source for “now”, timezone, and today/yesterday prayer times.
///
/// Ticks once per second app-wide. Features that need live updates (hero card,
/// schedule, fortress recommendations) should watch this instead of running
/// their own timers.
@Riverpod(keepAlive: true)
class PrayerDay extends _$PrayerDay {
  PrayerDayBundle? _cache;
  PrayerTimeInputs? _cachedInputs;
  TZDateTime? _cachedAnchorDate;

  @override
  Stream<PrayerDaySnapshot> build() async* {
    ref.watch(prayerTimeInputsProvider);
    final repo = ref.watch(prayerRepoProvider);
    final log = ref.read(loggerProvider);

    final inputs = ref.read(prayerTimeInputsProvider);
    if (inputs == null) {
      return;
    }

    PrayerDaySnapshot? snapshot() {
      final inputs = ref.read(prayerTimeInputsProvider);
      if (inputs == null) return null;

      final now = TZDateTime.now(inputs.location);
      final bundle = _ensureCache(inputs, now, repo, log);
      if (bundle == null) return null;

      return PrayerDaySnapshot(
        now: now,
        location: inputs.location,
        bundle: bundle,
      );
    }

    PrayerDaySnapshot? safeSnapshot() {
      try {
        return snapshot();
      } on Object catch (error, stack) {
        log.e('PrayerDay tick failed', error: error, stackTrace: stack);
        return null;
      }
    }

    final initial = safeSnapshot();
    if (initial != null) yield initial;

    while (true) {
      await Future<void>.delayed(_tickInterval);
      final next = safeSnapshot();
      if (next != null) yield next;
    }
  }

  PrayerDayBundle? _ensureCache(
    PrayerTimeInputs inputs,
    TZDateTime now,
    PrayerRepo repo,
    Logger log,
  ) {
    final anchorDate = TZDateTime(
      inputs.location,
      now.year,
      now.month,
      now.day,
    );

    final needsRefresh =
        _cache == null ||
        _cachedInputs != inputs ||
        _cachedAnchorDate != anchorDate;

    if (!needsRefresh) return _cache;

    final bundle = computePrayerDayBundle(
      inputs: inputs,
      anchorNow: now,
      log: log,
    );
    if (bundle == null) return _cache;

    _cache = bundle;
    _cachedInputs = inputs;
    _cachedAnchorDate = anchorDate;
    return _cache;
  }
}

/// Live today/yesterday bundle from [PrayerDay] without 1 Hz rebuilds.
@Riverpod(keepAlive: true)
PrayerDayBundle? todayPrayerDayBundle(Ref ref) {
  ref
    ..watch(prayerCalendarDayKeyProvider)
    ..watch(prayerTimeInputsProvider);
  return ref.read(prayerDayProvider).value?.bundle;
}

/// Prayer bundle for a calendar date via the shared computation engine.
@riverpod
PrayerDayBundle? prayerDayBundleForDate(Ref ref, DateTime date) {
  final inputs = ref.watch(prayerTimeInputsProvider);
  if (inputs == null) return null;

  final normalized = DateTime(date.year, date.month, date.day);
  final todayKey = ref.watch(prayerCalendarDayKeyProvider);
  if (todayKey != 0 && calendarDayKeyFromDate(normalized) == todayKey) {
    return ref.watch(todayPrayerDayBundleProvider);
  }

  final anchor = TZDateTime(
    inputs.location,
    date.year,
    date.month,
    date.day,
    12,
  );
  return computePrayerDayBundle(
    inputs: inputs,
    anchorNow: anchor,
  );
}

/// Cross-feature alias: calendar day key from the live prayer-day stream.
@riverpod
int prayerCalendarDayKey(Ref ref) {
  return ref.watch(prayerDayProvider).value?.calendarDayKey ?? 0;
}

/// Cross-feature alias: minute bucket from the live prayer-day stream.
@riverpod
int currentMinuteBucket(Ref ref) {
  final now = ref.watch(prayerDayProvider).value?.now;
  return (now?.millisecondsSinceEpoch ?? 0) ~/ 60000;
}

/// Whether the live prayer-day stream has yet to produce its first snapshot.
@riverpod
bool prayerDayIsLoading(Ref ref) {
  final inputs = ref.watch(prayerTimeInputsProvider);
  if (inputs != null) {
    final day = ref.watch(prayerDayProvider);
    return day.isLoading || !day.hasValue;
  }
  return ref.watch(prayerSettingsProvider).isLoading;
}

/// Formatted sunnah time labels (sunrise / fajrAfter / ishaBefore).
@riverpod
({String sunrise, String fajrAfter, String ishaBefore})? sunnahTimeLabels(
  Ref ref,
) {
  ref.watch(currentMinuteBucketProvider);
  final day = ref.read(prayerDayProvider).value;
  if (day == null) return null;
  final formatter = ref.watch(timeFormatterProvider);
  String label(Prayer prayer) =>
      formatter.format(resolveSunnahTime(prayer: prayer, snapshot: day));
  return (
    sunrise: label(Prayer.sunrise),
    fajrAfter: label(Prayer.fajrAfter),
    ishaBefore: label(Prayer.ishaBefore),
  );
}
