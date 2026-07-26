import 'package:adhan_dart/adhan_dart.dart';
import 'package:hijri_date/hijri.dart';
import 'package:logger/logger.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_day_bundle.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_day_snapshot.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_time_inputs.dart';
import 'package:tawaq/feature/prayer/domain/services/adhan_time_utils.dart';
import 'package:timezone/timezone.dart';

/// Shared rounding policy for all prayer-time reads (live and historical).
const kPrayerTimesRoundToMinutes = false;

/// Computes prayer times for [anchor] using [inputs].
///
/// Does **not** apply user [PrayerTimeInputs.adhanAdjustments] — those are
/// baked into the day timeline by [computePrayerDayBundle] after sunnah times
/// are derived from the raw schedule.
PrayerTimes computePrayerTimesForAnchor({
  required PrayerTimeInputs inputs,
  required DateTime anchor,
  Logger? log,
}) {
  var times = PrayerTimes(
    date: anchor,
    coordinates: inputs.coordinates,
    calculationMethod: inputs.method,
    roundToMinutes: kPrayerTimesRoundToMinutes,
  );

  if (HijriDate.fromDate(anchor).hMonth == 9 && inputs.method is UmmAlQura) {
    log?.d('Adjusting Isha for Ramadan');
    times = times.copyWith(isha: times.isha.add(const Duration(minutes: 30)));
  }

  return times;
}

/// Builds today/yesterday prayer bundles for the calendar day of [anchorNow].
///
/// Obligatory adhan times in [PrayerDayBundle.today] / [PrayerDayBundle.yesterday]
/// and [PrayerDayTimeline] include [PrayerTimeInputs.adhanAdjustments].
/// Sunnah night windows stay derived from the **unadjusted** schedule so
/// middle/last-third of night do not shift with per-prayer adhan offsets.
PrayerDayBundle computePrayerDayBundle({
  required PrayerTimeInputs inputs,
  required TZDateTime anchorNow,
  Logger? log,
}) {
  final location = inputs.location;
  final localNow = TZDateTime.from(anchorNow, location);

  final rawToday = computePrayerTimesForAnchor(
    inputs: inputs,
    anchor: localNow,
    log: log,
  );
  final rawYesterday = computePrayerTimesForAnchor(
    inputs: inputs,
    anchor: localNow.subtract(const Duration(days: 1)),
    log: log,
  );

  // Sunnah from raw times — adjustments must not move night windows.
  final todaySunnah = SunnahTimes(rawToday);
  final yesterdaySunnah = SunnahTimes(rawYesterday);

  final today = _applyAdhanAdjustments(rawToday, inputs.adhanAdjustments);
  final yesterday = _applyAdhanAdjustments(
    rawYesterday,
    inputs.adhanAdjustments,
  );

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

PrayerTimes _applyAdhanAdjustments(
  PrayerTimes times,
  Map<Prayer, int> adjustments,
) {
  if (adjustments.isEmpty) return times;
  return times.copyWith(
    fajr: applyAdhanAdjustment(
      prayerTime: times.fajr,
      prayer: Prayer.fajr,
      adjustments: adjustments,
    ),
    dhuhr: applyAdhanAdjustment(
      prayerTime: times.dhuhr,
      prayer: Prayer.dhuhr,
      adjustments: adjustments,
    ),
    asr: applyAdhanAdjustment(
      prayerTime: times.asr,
      prayer: Prayer.asr,
      adjustments: adjustments,
    ),
    maghrib: applyAdhanAdjustment(
      prayerTime: times.maghrib,
      prayer: Prayer.maghrib,
      adjustments: adjustments,
    ),
    isha: applyAdhanAdjustment(
      prayerTime: times.isha,
      prayer: Prayer.isha,
      adjustments: adjustments,
    ),
  );
}
