import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/logging/logger_provider.dart';
import 'package:tawaq/core/utils/date_formatter.dart';
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
    adhanAdjustments: settings.adhanAdjustments,
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
    final log = ref.read(loggerProvider);

    final inputs = ref.read(prayerTimeInputsProvider);
    if (inputs == null) {
      return;
    }

    PrayerDaySnapshot? snapshot() {
      final inputs = ref.read(prayerTimeInputsProvider);
      if (inputs == null) return null;

      final now = TZDateTime.now(inputs.location);
      final bundle = _ensureCache(inputs, now, log);

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
      if (!ref.mounted) return;
      final next = safeSnapshot();
      if (next != null) yield next;
    }
  }

  PrayerDayBundle _ensureCache(
    PrayerTimeInputs inputs,
    TZDateTime now,
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

    if (!needsRefresh) return _cache!;

    final bundle = computePrayerDayBundle(
      inputs: inputs,
      anchorNow: now,
      log: log,
    );

    _cache = bundle;
    _cachedInputs = inputs;
    _cachedAnchorDate = anchorDate;
    return bundle;
  }
}

/// Prayer bundle for a calendar date via the shared computation engine.
@riverpod
PrayerDayBundle? prayerDayBundleForDate(Ref ref, DateTime date) {
  final inputs = ref.watch(prayerTimeInputsProvider);
  if (inputs == null) return null;

  final normalized = DateTime(date.year, date.month, date.day);
  final todayKey = ref.watch(prayerCalendarDayKeyProvider);
  if (todayKey != 0 && calendarDayKeyFromDate(normalized) == todayKey) {
    // Day-key watch above already throttles; read cached bundle non-reactively.
    return ref.read(prayerDayProvider).value?.bundle;
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

/// Day-boundary signal from the live prayer-day stream.
///
/// Kept as a named provider so listeners/tests can subscribe to calendar-day
/// changes without rebuilding on every 1 Hz tick.
@riverpod
int prayerCalendarDayKey(Ref ref) {
  return ref.watch(
    prayerDayProvider.select(
      (asyncDay) => asyncDay.value?.calendarDayKey ?? 0,
    ),
  );
}

/// Minute-bucket signal from the live prayer-day stream.
///
/// Perf gate: schedule/card/fortress UIs watch this instead of the 1 Hz stream
/// so they recompute at most once per minute.
@riverpod
int currentMinuteBucket(Ref ref) {
  return ref.watch(
    prayerDayProvider.select(
      (asyncDay) =>
          (asyncDay.value?.now.millisecondsSinceEpoch ?? 0) ~/ 60000,
    ),
  );
}

/// Whether the live prayer-day stream has yet to produce its first snapshot.
@riverpod
bool prayerDayIsLoading(Ref ref) {
  final inputs = ref.watch(prayerTimeInputsProvider);
  if (inputs != null) {
    return ref.watch(
      prayerDayProvider.select((day) => day.isLoading || !day.hasValue),
    );
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
