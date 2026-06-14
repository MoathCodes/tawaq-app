import 'package:adhan_dart/adhan_dart.dart';
import 'package:tawaq/feature/prayer/domain/prayer_extensions.dart';
import 'package:timezone/timezone.dart';

/// Applies per-prayer adhan minute adjustments from settings.
DateTime applyAdhanAdjustment({
  required DateTime prayerTime,
  required Prayer prayer,
  required Map<Prayer, int> adjustments,
}) {
  final minutes = adjustments[prayer] ?? 0;
  if (minutes == 0) return prayerTime;
  return prayerTime.add(Duration(minutes: minutes));
}

/// Obligatory prayers that can trigger adhan.
const List<Prayer> obligatoryAdhanPrayers = [
  Prayer.fajr,
  Prayer.dhuhr,
  Prayer.asr,
  Prayer.maghrib,
  Prayer.isha,
];

/// Builds adjusted adhan [DateTime]s for [date]'s obligatory prayers.
Map<Prayer, DateTime> adjustedAdhanTimesForDay({
  required PrayerTimes times,
  required Location location,
  required Map<Prayer, int> adjustments,
}) {
  return {
    for (final prayer in obligatoryAdhanPrayers)
      prayer: applyAdhanAdjustment(
        prayerTime: times.getTimesForPrayer(prayer, location),
        prayer: prayer,
        adjustments: adjustments,
      ),
  };
}

/// Returns true when [now] crossed [target] since [previous] within [window].
bool didCrossPrayerTime({
  required DateTime previous,
  required DateTime now,
  required DateTime target,
  Duration window = const Duration(seconds: 2),
}) {
  return previous.isBefore(target) &&
      !now.isBefore(target) &&
      now.difference(target) <= window;
}

/// Calendar day key `yyyyMMdd` for dedupe storage.
int adhanDayKey(DateTime date) =>
    date.year * 10000 + date.month * 100 + date.day;
