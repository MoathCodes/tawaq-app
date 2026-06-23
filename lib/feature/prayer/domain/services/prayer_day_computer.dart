import 'package:adhan_dart/adhan_dart.dart';
import 'package:hijri_date/hijri.dart';
import 'package:logger/logger.dart';
import 'package:tawaq/feature/prayer/data/repository/prayer_repo.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_day_bundle.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_day_snapshot.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_time_inputs.dart';
import 'package:timezone/timezone.dart';

/// Shared rounding policy for all prayer-time reads (live and historical).
const kPrayerTimesRoundToMinutes = false;

/// Computes prayer times for [anchor] using [inputs].
PrayerTimes? computePrayerTimesForAnchor({
  required PrayerTimeInputs inputs,
  required DateTime anchor,
  required PrayerRepo repo,
  Logger? log,
}) {
  var times = repo.getPrayerTimes(
    anchor,
    inputs.coordinates,
    inputs.method,
    roundToMinutes: kPrayerTimesRoundToMinutes,
  );

  if (HijriDate.fromDate(anchor).hMonth == 9 && inputs.method is UmmAlQura) {
    log?.d('Adjusting Isha for Ramadan');
    times = times.copyWith(isha: times.isha.add(const Duration(minutes: 30)));
  }

  return times;
}

/// Builds today/yesterday prayer bundles for the calendar day of [anchorNow].
PrayerDayBundle? computePrayerDayBundle({
  required PrayerTimeInputs inputs,
  required TZDateTime anchorNow,
  required PrayerRepo repo,
  Logger? log,
}) {
  final location = inputs.location;
  final localNow = TZDateTime.from(anchorNow, location);

  final today = computePrayerTimesForAnchor(
    inputs: inputs,
    anchor: localNow,
    repo: repo,
    log: log,
  );
  final yesterday = computePrayerTimesForAnchor(
    inputs: inputs,
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
