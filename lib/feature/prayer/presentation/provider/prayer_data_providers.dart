import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/logging/logger_provider.dart';
import 'package:tawaq/core/utils/date_formatter.dart';
import 'package:tawaq/feature/prayer/data/repository/prayer_repo.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_day_bundle.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_day_snapshot.dart';
import 'package:tawaq/feature/prayer/domain/services/prayer_day_computer.dart';
import 'package:tawaq/feature/prayer/domain/services/prayer_time_resolver.dart';
import 'package:tawaq/feature/settings/data/models/prayer_settings_model.dart';
import 'package:tawaq/feature/settings/presentation/provider/prayer_settings_provider.dart';
import 'package:timezone/timezone.dart';

part 'prayer_data_providers.g.dart';

const _tickInterval = Duration(seconds: 1);

/// Single live source for “now”, timezone, and today/yesterday prayer times.
///
/// Ticks once per second app-wide. Features that need live updates (hero card,
/// schedule, fortress recommendations) should watch this instead of running
/// their own timers.
@Riverpod(keepAlive: true)
class PrayerDay extends _$PrayerDay {
  PrayerDayBundle? _cache;
  PrayerSettings? _cachedSettings;
  TZDateTime? _cachedAnchorDate;

  @override
  Stream<PrayerDaySnapshot> build() async* {
    ref.watch(effectivePrayerSettingsProvider);
    final repo = ref.watch(prayerRepoProvider);
    final log = ref.read(loggerProvider);

    PrayerDaySnapshot? snapshot() {
      final settings = ref.read(effectivePrayerSettingsProvider);
      if (settings == null) return null;

      final now = TZDateTime.now(settings.location);
      final bundle = _ensureCache(settings, now, repo, log);
      if (bundle == null) return null;

      return PrayerDaySnapshot(
        now: now,
        location: settings.location,
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
    PrayerSettings settings,
    TZDateTime now,
    PrayerRepo repo,
    Logger log,
  ) {
    if (!settings.isLocationReady) return _cache;

    final anchorDate = TZDateTime(
      settings.location,
      now.year,
      now.month,
      now.day,
    );

    final needsRefresh =
        _cache == null ||
        _cachedSettings != settings ||
        _cachedAnchorDate != anchorDate;

    if (!needsRefresh) return _cache;

    final bundle = computePrayerDayBundle(
      settings: settings,
      anchorNow: now,
      repo: repo,
      log: log,
    );
    if (bundle == null) return _cache;

    _cache = bundle;
    _cachedSettings = settings;
    _cachedAnchorDate = anchorDate;
    return _cache;
  }
}

/// Prayer bundle for a calendar date via the shared computation engine.
@riverpod
PrayerDayBundle? prayerDayBundleForDate(Ref ref, DateTime date) {
  final settings = ref.watch(effectivePrayerSettingsProvider);
  if (settings == null) return null;

  final repo = ref.watch(prayerRepoProvider);
  final anchor = TZDateTime(
    settings.location,
    date.year,
    date.month,
    date.day,
    12,
  );
  return computePrayerDayBundle(
    settings: settings,
    anchorNow: anchor,
    repo: repo,
  );
}

/// Prayer times for a specific calendar date (no live tick).
@riverpod
PrayerTimes? prayerTimesForDate(Ref ref, DateTime date) {
  return ref.watch(prayerDayBundleForDateProvider(date))?.today;
}

/// Calendar day key from [prayerDayProvider]; stable within a day so dependents
/// are not notified on every clock tick.
@riverpod
int prayerCalendarDayKey(Ref ref) {
  return ref.watch(prayerDayProvider).value?.calendarDayKey ?? 0;
}

/// Current instant in the user's prayer timezone from [prayerDayProvider].
@riverpod
TZDateTime? currentLocationTime(Ref ref) {
  return ref.watch(prayerDayProvider).value?.now;
}

/// Current time bucketed to whole minutes (epoch minutes) from
/// [prayerDayProvider].
///
/// Lets minute-resolution consumers (current-prayer slot, time-of-day
/// recommendations) recompute at most once per minute instead of on every 1 Hz
/// tick. Prayer boundaries have minute resolution, so this is exact for them.
@riverpod
int currentMinuteBucket(Ref ref) {
  final now = ref.watch(prayerDayProvider).value?.now;
  return (now?.millisecondsSinceEpoch ?? 0) ~/ 60000;
}

/// Formatted sunnah time labels (sunrise / fajrAfter / ishaBefore).
///
/// Recomputed on each 1 Hz tick but returned as a value-equal record, so
/// dependents rebuild only when a displayed label actually changes (≈ at the
/// fajr crossing or midnight) rather than every second.
@riverpod
({String sunrise, String fajrAfter, String ishaBefore})? sunnahTimeLabels(
  Ref ref,
) {
  final day = ref.watch(prayerDayProvider).value;
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
