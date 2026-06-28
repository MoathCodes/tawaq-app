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
import 'package:tawaq/feature/prayer/domain/services/prayer_day_computer.dart';
import 'package:tawaq/feature/prayer/domain/services/prayer_timeline.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_effective_settings_provider.dart';
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
  PrayerTimeInputs? _cachedInputs;
  TZDateTime? _cachedAnchorDate;

  @override
  Stream<PrayerDaySnapshot> build() async* {
    // Re-run when inputs hydrate (no busy-wait loop — that blocked stream
    // cancellation and left isLoading stuck true).
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
      repo: repo,
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
///
/// Recomputes when the calendar day or [prayerTimeInputsProvider] changes, or
/// when [PrayerDay] emits a new bundle reference (midnight / location change).
@Riverpod(keepAlive: true)
PrayerDayBundle? todayPrayerDayBundle(Ref ref) {
  ref
    ..watch(prayerCalendarDayKeyProvider)
    ..watch(prayerTimeInputsProvider);
  // Read (don't watch) so dependents are not rebuilt on every 1 Hz tick;
  // calendar day key and inputs changes cover midnight and location updates.
  return ref.read(prayerDayProvider).value?.bundle;
}

/// Prayer bundle for a calendar date via the shared computation engine.
@riverpod
PrayerDayBundle? prayerDayBundleForDate(Ref ref, DateTime date) {
  final inputs = ref.watch(prayerTimeInputsProvider);
  if (inputs == null) return null;

  final normalized = DateTime(date.year, date.month, date.day);
  final todayKey = ref.watch(prayerCalendarDayKeyProvider);
  if (todayKey != 0 &&
      calendarDayKeyFromDate(normalized) == todayKey) {
    return ref.watch(todayPrayerDayBundleProvider);
  }

  final repo = ref.watch(prayerRepoProvider);
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
    repo: repo,
  );
}

/// Prayer times for a specific calendar date (no live tick).
@riverpod
PrayerTimes? prayerTimesForDate(Ref ref, DateTime date) {
  return ref.watch(prayerDayBundleForDateProvider(date))?.today;
}

/// Derived [prayerDayProvider] projections — watch policy:
///
/// - Prefer [prayerCalendarDayKeyProvider] or [currentMinuteBucketProvider]
///   over the 1 Hz stream when minute/day resolution is enough.
/// - Use `ref.read(prayerDayProvider)` inside providers that only need stable
///   bundle data within a calendar day.
/// - Watch [prayerDayProvider] directly only for live clock UI (countdowns).
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

/// Whether the live prayer-day stream has yet to produce its first snapshot.
///
/// Projects [prayerDayProvider] to a `bool` so the hero skeleton toggles only
/// at the load boundary rather than rebuilding on every 1 Hz tick.
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
///
/// Recomputed once per minute when labels may change (fajr crossing, midnight).
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
