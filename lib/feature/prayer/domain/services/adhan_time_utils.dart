import 'package:adhan_dart/adhan_dart.dart';
import 'package:tawaq/core/utils/prayer_extensions.dart';
import 'package:tawaq/feature/prayer/domain/prayer_slots.dart';
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

/// Returns true when [now] crossed [target] since [previous] and the crossing
/// is no more than [window] in the past and still before [cutoff].
///
/// [window] doubles as the catch-up budget: a crossing noticed late (after a
/// stall or the machine waking from sleep) still fires while it is within
/// [window], but a target further in the past is skipped rather than firing a
/// stale alert.
///
/// [cutoff] caps the catch-up at the onset of the next prayer: once [now]
/// reaches it the alert is stale and is dropped, so a slept-through maghrib is
/// never announced once isha has begun — even where the two are less than
/// [window] apart. Null disables the cap (the last prayer of the day, sunnah).
bool didCrossPrayerTime({
  required DateTime previous,
  required DateTime now,
  required DateTime target,
  Duration window = const Duration(seconds: 2),
  DateTime? cutoff,
}) {
  if (!previous.isBefore(target)) return false;
  if (now.isBefore(target)) return false;
  if (now.difference(target) > window) return false;
  if (cutoff != null && !now.isBefore(cutoff)) return false;
  return true;
}
