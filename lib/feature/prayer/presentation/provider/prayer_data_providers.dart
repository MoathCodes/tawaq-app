import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/logging/logger_provider.dart';
import 'package:tawaq/feature/prayer/data/repository/prayer_repo.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_day_snapshot.dart';
import 'package:tawaq/feature/prayer/domain/services/prayer_service.dart';
import 'package:tawaq/feature/settings/data/models/prayer_settings_model.dart';
import 'package:tawaq/feature/settings/presentation/provider/prayer_settings_provider.dart';
import 'package:timezone/timezone.dart';

part 'prayer_data_providers.g.dart';

/// Provider for the [PrayerService].
@riverpod
PrayerService prayerService(Ref ref) {
  final repo = ref.watch(prayerRepoProvider);
  final log = ref.read(loggerProvider);
  final settings = ref.watch(prayerSettingsProvider);

  // While loading or after an error, build from the last good settings rather
  // than (0,0) defaults — a (0,0) service computes null-island times that get
  // baked into [PrayerDay]'s cache and fire alerts hours off.
  return settings.when(
    data: (d) => PrayerService(repo, d, log),
    loading: () => PrayerService(repo, lastGoodPrayerSettings(), log),
    error: (e, st) {
      log.e('Error loading settings', error: e, stackTrace: st);
      return PrayerService(repo, lastGoodPrayerSettings(), log);
    },
  );
}

const _tickInterval = Duration(seconds: 1);

class _PrayerDayCache {
  _PrayerDayCache({
    required this.anchorDate,
    required this.today,
    required this.yesterday,
    required this.todaySunnah,
    required this.yesterdaySunnah,
    required this.timeline,
  });

  final TZDateTime anchorDate;
  final PrayerTimes today;
  final PrayerTimes yesterday;
  final SunnahTimes todaySunnah;
  final SunnahTimes yesterdaySunnah;
  final PrayerDayTimeline timeline;
}

/// Single live source for “now”, timezone, and today/yesterday prayer times.
///
/// Ticks once per second app-wide. Features that need live updates (hero card,
/// schedule, fortress recommendations) should watch this instead of running
/// their own timers.
@Riverpod(keepAlive: true)
class PrayerDay extends _$PrayerDay {
  _PrayerDayCache? _cache;
  PrayerSettings? _cachedSettings;

  @override
  Stream<PrayerDaySnapshot> build() async* {
    ref.watch(prayerSettingsProvider);
    final service = ref.watch(prayerServiceProvider);
    final log = ref.read(loggerProvider);

    PrayerDaySnapshot snapshot() {
      final settings =
          ref.read(prayerSettingsProvider).value ?? lastGoodPrayerSettings();
      final now = TZDateTime.now(settings.location);
      _ensureCache(settings, now, service);
      final cache = _cache!;

      return PrayerDaySnapshot(
        now: now,
        location: settings.location,
        today: cache.today,
        yesterday: cache.yesterday,
        todaySunnah: cache.todaySunnah,
        yesterdaySunnah: cache.yesterdaySunnah,
        timeline: cache.timeline,
      );
    }

    // A transient failure in [snapshot] — most likely the day-boundary
    // recompute in [_ensureCache], or a hiccup right after the machine wakes
    // from sleep — must never terminate the clock. If the generator stops, the
    // stream completes and every dependant (the prayer card, the alert
    // scheduler) freezes on a stale `now` until the app restarts. So a bad tick
    // is logged and skipped, and the loop keeps ticking.
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

  void _ensureCache(
    PrayerSettings settings,
    TZDateTime now,
    PrayerService service,
  ) {
    // (0,0) is the "no location set" sentinel. Computing from it yields
    // null-island times (~2-3h off) which, once cached, persist for the day and
    // fire alerts at the wrong time. Refuse to compute/cache from it: keep any
    // previously cached good times and wait for real coordinates to arrive (the
    // settings change then triggers a refresh below).
    final coords = settings.coordinates;
    if (coords.latitude == 0 && coords.longitude == 0) return;

    final anchorDate = TZDateTime(
      settings.location,
      now.year,
      now.month,
      now.day,
    );

    final needsRefresh =
        _cache == null ||
        _cachedSettings != settings ||
        _cache!.anchorDate != anchorDate;

    if (!needsRefresh) return;

    final localNow = TZDateTime.from(now, settings.location);
    final today = service.getTodaysPrayerTimes(
      localNow,
      roundToMinutes: false,
    );
    final yesterday = service.getTodaysPrayerTimes(
      localNow.subtract(const Duration(days: 1)),
      roundToMinutes: false,
    );
    final todaySunnah = service.getSunnahTime(today);
    final yesterdaySunnah = service.getSunnahTime(yesterday);

    final timeline = PrayerDayTimeline(
      fajrToday: TZDateTime.from(today.fajr, settings.location),
      sunriseToday: TZDateTime.from(today.sunrise, settings.location),
      dhuhrToday: TZDateTime.from(today.dhuhr, settings.location),
      asrToday: TZDateTime.from(today.asr, settings.location),
      maghribToday: TZDateTime.from(today.maghrib, settings.location),
      ishaToday: TZDateTime.from(today.isha, settings.location),
      ishaYesterday: TZDateTime.from(yesterday.isha, settings.location),
      middleOfNightToday: TZDateTime.from(
        todaySunnah.middleOfTheNight,
        settings.location,
      ),
      middleOfNightYesterday: TZDateTime.from(
        yesterdaySunnah.middleOfTheNight,
        settings.location,
      ),
      lastThirdToday: TZDateTime.from(
        todaySunnah.lastThirdOfTheNight,
        settings.location,
      ),
      lastThirdYesterday: TZDateTime.from(
        yesterdaySunnah.lastThirdOfTheNight,
        settings.location,
      ),
    );

    _cache = _PrayerDayCache(
      anchorDate: anchorDate,
      today: today,
      yesterday: yesterday,
      todaySunnah: todaySunnah,
      yesterdaySunnah: yesterdaySunnah,
      timeline: timeline,
    );
    _cachedSettings = settings;
  }
}

/// Prayer times for a specific calendar date (no live tick).
@riverpod
PrayerTimes prayerTimesForDate(Ref ref, DateTime date) {
  final service = ref.watch(prayerServiceProvider);
  final settings =
      ref.read(prayerSettingsProvider).value ?? lastGoodPrayerSettings();
  final anchor = TZDateTime(
    settings.location,
    date.year,
    date.month,
    date.day,
  );
  return service.getTodaysPrayerTimes(anchor);
}

/// Calendar day key from [prayerDayProvider]; stable within a day so dependents
/// are not notified on every clock tick.
@riverpod
int prayerCalendarDayKey(Ref ref) {
  return ref.watch(prayerDayProvider).value?.calendarDayKey ?? 0;
}

/// Today's prayer times derived from [prayerDayProvider].
///
/// Pass [forDate] to resolve times for another calendar day without the live
/// tick stream.
@riverpod
PrayerTimes currentPrayerTimes(Ref ref, {DateTime? forDate}) {
  if (forDate != null) {
    return ref.watch(
      prayerTimesForDateProvider(
        DateTime(forDate.year, forDate.month, forDate.day),
      ),
    );
  }

  final snapshot = ref.watch(prayerDayProvider).value;
  if (snapshot != null) return snapshot.today;

  final service = ref.watch(prayerServiceProvider);
  return service.getTodaysPrayerTimes(null);
}

/// Current instant in the user's prayer timezone from [prayerDayProvider].
@riverpod
TZDateTime currentLocationTime(Ref ref) {
  final snapshot = ref.watch(prayerDayProvider).value;
  if (snapshot != null) return snapshot.now;

  final settings =
      ref.read(prayerSettingsProvider).value ?? lastGoodPrayerSettings();
  return TZDateTime.now(settings.location);
}
