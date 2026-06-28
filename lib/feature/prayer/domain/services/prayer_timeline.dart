import 'package:adhan_dart/adhan_dart.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_day_snapshot.dart';
import 'package:tawaq/feature/prayer/domain/prayer_extensions.dart';
import 'package:timezone/timezone.dart';

/// Normalizes sunnah times that fall before their isha anchor to the next day.
TZDateTime normalizeNightAfterIsha({
  required DateTime sunnahTime,
  required DateTime ishaAnchor,
  required Location location,
}) {
  final local = TZDateTime.from(sunnahTime, location);
  final isha = TZDateTime.from(ishaAnchor, location);
  return local.isBefore(isha) ? local.add(const Duration(days: 1)) : local;
}

/// Resolves the display/alert time for [prayer] at [snapshot.now].
///
/// [Prayer.ishaBefore] and [Prayer.fajrAfter] use [SunnahTimes] on the
/// timeline; other prayers use [PrayerDaySnapshot.today].
DateTime resolveSunnahTime({
  required Prayer prayer,
  required PrayerDaySnapshot snapshot,
}) {
  final timeline = snapshot.timeline;
  final now = snapshot.now;
  final location = snapshot.location;
  final beforeFajr = now.isBefore(timeline.fajrToday);

  return switch (prayer) {
    Prayer.ishaBefore => normalizeNightAfterIsha(
      sunnahTime: beforeFajr
          ? timeline.lastThirdYesterday
          : timeline.lastThirdToday,
      ishaAnchor: beforeFajr ? timeline.ishaYesterday : timeline.ishaToday,
      location: location,
    ),
    Prayer.fajrAfter => normalizeNightAfterIsha(
      sunnahTime: beforeFajr
          ? timeline.middleOfNightYesterday
          : timeline.middleOfNightToday,
      ishaAnchor: beforeFajr ? timeline.ishaYesterday : timeline.ishaToday,
      location: location,
    ),
    _ => snapshot.today.getTimesForPrayer(prayer, location),
  };
}

/// Returns the active prayer slot for [currentTime], including night windows
/// ([Prayer.fajrAfter], [Prayer.ishaBefore]) between Isha and Fajr.
Prayer getCurrentPrayer({
  required DateTime currentTime,
  required Location location,
  required PrayerDayTimeline timeline,
}) {
  final beforeFajr = currentTime.isBefore(timeline.fajrToday);

  final nIsha = beforeFajr ? timeline.ishaYesterday : timeline.ishaToday;
  final nMiddle = normalizeNightAfterIsha(
    sunnahTime: beforeFajr
        ? timeline.middleOfNightYesterday
        : timeline.middleOfNightToday,
    ishaAnchor: nIsha,
    location: location,
  );
  final nLastThird = normalizeNightAfterIsha(
    sunnahTime: beforeFajr
        ? timeline.lastThirdYesterday
        : timeline.lastThirdToday,
    ishaAnchor: nIsha,
    location: location,
  );

  final tMiddle = normalizeNightAfterIsha(
    sunnahTime: timeline.middleOfNightToday,
    ishaAnchor: timeline.ishaToday,
    location: location,
  );
  final tLastThird = normalizeNightAfterIsha(
    sunnahTime: timeline.lastThirdToday,
    ishaAnchor: timeline.ishaToday,
    location: location,
  );

  late final List<DateTime> pts;
  late final List<Prayer> labels;
  if (beforeFajr) {
    pts = [
      nIsha,
      nMiddle,
      nLastThird,
      timeline.fajrToday,
      timeline.sunriseToday,
      timeline.dhuhrToday,
      timeline.asrToday,
      timeline.maghribToday,
      timeline.ishaToday,
      tMiddle,
      tLastThird,
      timeline.fajrToday.add(const Duration(days: 1)),
    ];
    labels = const [
      Prayer.isha,
      Prayer.fajrAfter,
      Prayer.ishaBefore,
      Prayer.fajr,
      Prayer.sunrise,
      Prayer.dhuhr,
      Prayer.asr,
      Prayer.maghrib,
      Prayer.isha,
      Prayer.fajrAfter,
      Prayer.ishaBefore,
    ];
  } else {
    pts = [
      timeline.fajrToday,
      timeline.sunriseToday,
      timeline.dhuhrToday,
      timeline.asrToday,
      timeline.maghribToday,
      timeline.ishaToday,
      tMiddle,
      tLastThird,
      timeline.fajrToday.add(const Duration(days: 1)),
    ];
    labels = const [
      Prayer.fajr,
      Prayer.sunrise,
      Prayer.dhuhr,
      Prayer.asr,
      Prayer.maghrib,
      Prayer.isha,
      Prayer.fajrAfter,
      Prayer.ishaBefore,
    ];
  }

  for (var i = 0; i < labels.length; i++) {
    final start = pts[i];
    final end = pts[i + 1];
    if ((currentTime.isAtSameMomentAs(start) || currentTime.isAfter(start)) &&
        currentTime.isBefore(end)) {
      return labels[i];
    }
  }

  var idx = -1;
  for (var i = 0; i < pts.length; i++) {
    final p = pts[i];
    if (p.isBefore(currentTime) || p.isAtSameMomentAs(currentTime)) {
      idx = i;
    } else {
      break;
    }
  }
  if (idx == -1) return labels.first;
  if (idx >= labels.length) idx = labels.length - 1;
  return labels[idx];
}

/// Active prayer slot from a live [snapshot].
Prayer currentPrayerFromSnapshot(PrayerDaySnapshot snapshot) {
  return getCurrentPrayer(
    currentTime: snapshot.now,
    location: snapshot.location,
    timeline: snapshot.timeline,
  );
}
