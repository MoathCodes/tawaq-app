import 'package:adhan_dart/adhan_dart.dart';

/// Applies per-prayer adhan minute adjustments from settings.
///
/// Used only when baking adjustments into the shared day timeline in
/// `computePrayerDayBundle`. Call sites must not re-apply at the edge.
DateTime applyAdhanAdjustment({
  required DateTime prayerTime,
  required Prayer prayer,
  required Map<Prayer, int> adjustments,
}) {
  final minutes = adjustments[prayer] ?? 0;
  if (minutes == 0) return prayerTime;
  return prayerTime.add(Duration(minutes: minutes));
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
/// [window] apart. Null disables the cap (the last prayer of the day, sunnah,
/// or iqamah past the next obligatory onset).
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
