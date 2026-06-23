import 'package:adhan_dart/adhan_dart.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_day_snapshot.dart';
import 'package:tawaq/feature/prayer/domain/prayer_extensions.dart';
import 'package:timezone/timezone.dart';

/// Resolves the display/alert time for [prayer] at [snapshot.now].
///
/// [Prayer.ishaBefore] and [Prayer.fajrAfter] are night-window slots in
/// adhan_dart whose [PrayerTimes] fields are *not* last-third / middle-of-night;
/// those come from [SunnahTimes] on the timeline instead.
DateTime resolveSunnahTime({
  required Prayer prayer,
  required PrayerDaySnapshot snapshot,
}) {
  final timeline = snapshot.timeline;
  final now = snapshot.now;
  final location = snapshot.location;
  final beforeFajr = now.isBefore(timeline.fajrToday);

  return switch (prayer) {
    Prayer.ishaBefore => _normalizeNightSunnah(
      sunnahTime: beforeFajr
          ? timeline.lastThirdYesterday
          : timeline.lastThirdToday,
      ishaAnchor: beforeFajr ? timeline.ishaYesterday : timeline.ishaToday,
      location: location,
    ),
    Prayer.fajrAfter => _normalizeNightSunnah(
      sunnahTime: beforeFajr
          ? timeline.middleOfNightYesterday
          : timeline.middleOfNightToday,
      ishaAnchor: beforeFajr ? timeline.ishaYesterday : timeline.ishaToday,
      location: location,
    ),
    _ => snapshot.today.getTimesForPrayer(prayer, location),
  };
}

DateTime _normalizeNightSunnah({
  required DateTime sunnahTime,
  required DateTime ishaAnchor,
  required Location location,
}) {
  final local = TZDateTime.from(sunnahTime, location);
  final isha = TZDateTime.from(ishaAnchor, location);
  return local.isBefore(isha) ? local.add(const Duration(days: 1)) : local;
}
