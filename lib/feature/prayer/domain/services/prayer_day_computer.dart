import 'package:adhan_dart/adhan_dart.dart';
import 'package:hijri_date/hijri.dart';
import 'package:logger/logger.dart';
import 'package:tawaq/feature/prayer/data/repository/prayer_repo.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_day_bundle.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_day_snapshot.dart';
import 'package:tawaq/feature/settings/data/models/prayer_settings_model.dart';
import 'package:timezone/timezone.dart';

/// Shared rounding policy for all prayer-time reads (live and historical).
const kPrayerTimesRoundToMinutes = false;

/// Computes prayer times for [anchor] using [settings].
///
/// Returns null when [settings] coordinates are the (0,0) sentinel.
PrayerTimes? computePrayerTimesForAnchor({
  required PrayerSettings settings,
  required DateTime anchor,
  required PrayerRepo repo,
  Logger? log,
}) {
  if (!settings.isLocationReady) return null;

  var times = repo.getPrayerTimes(
    anchor,
    settings.coordinates,
    settings.method,
    roundToMinutes: kPrayerTimesRoundToMinutes,
  );

  if (HijriDate.fromDate(anchor).hMonth == 9 && settings.method is UmmAlQura) {
    log?.d('Adjusting Isha for Ramadan');
    times = times.copyWith(isha: times.isha.add(const Duration(minutes: 30)));
  }

  return times;
}

/// Builds today/yesterday prayer bundles for the calendar day of [anchorNow].
///
/// Returns null when location is not ready (0,0 coordinates).
PrayerDayBundle? computePrayerDayBundle({
  required PrayerSettings settings,
  required TZDateTime anchorNow,
  required PrayerRepo repo,
  Logger? log,
}) {
  if (!settings.isLocationReady) return null;

  final location = settings.location;
  final localNow = TZDateTime.from(anchorNow, location);

  final today = computePrayerTimesForAnchor(
    settings: settings,
    anchor: localNow,
    repo: repo,
    log: log,
  );
  final yesterday = computePrayerTimesForAnchor(
    settings: settings,
    anchor: localNow.subtract(const Duration(days: 1)),
    repo: repo,
    log: log,
  );
  if (today == null || yesterday == null) return null;

  final todaySunnah = repo.getSunnahTime(today);
  final yesterdaySunnah = repo.getSunnahTime(yesterday);

  final timeline = PrayerDayTimeline(
    fajrToday: TZDateTime.from(today.fajr, location),
    sunriseToday: TZDateTime.from(today.sunrise, location),
    dhuhrToday: TZDateTime.from(today.dhuhr, location),
    asrToday: TZDateTime.from(today.asr, location),
    maghribToday: TZDateTime.from(today.maghrib, location),
    ishaToday: TZDateTime.from(today.isha, location),
    ishaYesterday: TZDateTime.from(yesterday.isha, location),
    middleOfNightToday: TZDateTime.from(
      todaySunnah.middleOfTheNight,
      location,
    ),
    middleOfNightYesterday: TZDateTime.from(
      yesterdaySunnah.middleOfTheNight,
      location,
    ),
    lastThirdToday: TZDateTime.from(
      todaySunnah.lastThirdOfTheNight,
      location,
    ),
    lastThirdYesterday: TZDateTime.from(
      yesterdaySunnah.lastThirdOfTheNight,
      location,
    ),
  );

  return PrayerDayBundle(
    today: today,
    yesterday: yesterday,
    todaySunnah: todaySunnah,
    yesterdaySunnah: yesterdaySunnah,
    timeline: timeline,
  );
}
