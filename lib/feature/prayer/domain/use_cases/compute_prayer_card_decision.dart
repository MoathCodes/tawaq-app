import 'package:adhan_dart/adhan_dart.dart';
import 'package:hasanat/core/utils/prayer_extensions.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_card_decision.dart';
import 'package:timezone/timezone.dart';

PrayerCardDecision computePrayerCardDecision({
  required DateTime currentTime,
  required Location location,
  required PrayerTimesData todaysPrayerTimes,
  required PrayerTimesData yesterdaysPrayerTimes,
  required SunnahTimes todaysSunnahTimes,
  required SunnahTimes yesterdaysSunnahTimes,
}) {
  final DateTime fajrToday = todaysPrayerTimes.fajr.toLocation(location);
  final bool useTodayNight = !currentTime.isBefore(fajrToday);

  final nightPrayerTimes = useTodayNight
      ? todaysPrayerTimes
      : yesterdaysPrayerTimes;
  final nightSunnahTimes = useTodayNight
      ? todaysSunnahTimes
      : yesterdaysSunnahTimes;

  // Build an ordered cycle of prayers.
  const orderedPrayers = <Prayer>[
    Prayer.isha,
    Prayer.fajrAfter,
    Prayer.ishaBefore,
    Prayer.fajr,
    Prayer.sunrise,
    Prayer.dhuhr,
    Prayer.asr,
    Prayer.maghrib,
  ];

  DateTime timeOf(Prayer p) => switch (p) {
    Prayer.isha => nightPrayerTimes.isha.toLocation(location),
    Prayer.fajrAfter => nightSunnahTimes.middleOfTheNight.toLocation(location),
    Prayer.ishaBefore => nightSunnahTimes.lastThirdOfTheNight.toLocation(
      location,
    ),
    Prayer.fajr => fajrToday,
    _ => todaysPrayerTimes.getTimesForPrayer(p, location),
  };

  final cp = getCurrentPrayer(
    currentTime: currentTime,
    location: location,
    todaysPrayerTimes: todaysPrayerTimes,
    todaysSunnahTimes: todaysSunnahTimes,
    yesterdaysPrayerTimes: yesterdaysPrayerTimes,
    yesterdaysSunnahTimes: yesterdaysSunnahTimes,
  );

  int currentIdx = orderedPrayers.indexOf(cp);
  if (currentIdx == -1) currentIdx = 0; // Defensive: should not happen.
  final nextIdx = (currentIdx + 1) % orderedPrayers.length;

  DateTime currentRef = timeOf(orderedPrayers[currentIdx]);
  DateTime nextRef = timeOf(orderedPrayers[nextIdx]);

  // Ensure forward progression when the cycle wraps (e.g., lastThird -> fajr).
  if (!nextRef.isAfter(currentRef)) {
    nextRef = nextRef.add(const Duration(days: 1));
  }
  // Clamp currentRef to now if the slot hasn't started yet.
  if (currentTime.isBefore(currentRef)) currentRef = currentTime;

  final totalSeconds = nextRef.difference(currentRef).inSeconds;
  final remainingSeconds = nextRef.difference(currentTime).inSeconds;
  final showNext = remainingSeconds * 2 <= totalSeconds;

  return showNext
      ? PrayerCardDecision(
          referenceTime: nextRef,
          prayer: orderedPrayers[nextIdx],
          isCountdown: true,
        )
      : PrayerCardDecision(
          referenceTime: currentRef,
          prayer: orderedPrayers[currentIdx],
          isCountdown: false,
        );
}

Prayer getCurrentPrayer({
  required DateTime currentTime,
  required Location location,
  required PrayerTimesData todaysPrayerTimes,
  required SunnahTimes todaysSunnahTimes,
  required PrayerTimesData yesterdaysPrayerTimes,
  required SunnahTimes yesterdaysSunnahTimes,
}) {
  final tFajr = todaysPrayerTimes.fajr.toLocation(location);
  final bool beforeFajr = currentTime.isBefore(tFajr);

  // Night anchors (yesterday vs today) and day anchors (today)
  final nIsha = (beforeFajr ? yesterdaysPrayerTimes : todaysPrayerTimes).isha
      .toLocation(location);
  final nMiddle = (beforeFajr ? yesterdaysSunnahTimes : todaysSunnahTimes)
      .middleOfTheNight
      .toLocation(location);
  final nLastThird = (beforeFajr ? yesterdaysSunnahTimes : todaysSunnahTimes)
      .lastThirdOfTheNight
      .toLocation(location);

  final tSunrise = todaysPrayerTimes.sunrise.toLocation(location);
  final tDhuhr = todaysPrayerTimes.dhuhr.toLocation(location);
  final tAsr = todaysPrayerTimes.asr.toLocation(location);
  final tMaghrib = todaysPrayerTimes.maghrib.toLocation(location);
  final tIsha = todaysPrayerTimes.isha.toLocation(location);
  final tMiddle = todaysSunnahTimes.middleOfTheNight.toLocation(location);
  final tLastThird = todaysSunnahTimes.lastThirdOfTheNight.toLocation(location);

  // Construct an ordered timeline of [start) -> end events with labels.
  // Use start-inclusive, end-exclusive ranges.
  late final List<DateTime> pts;
  late final List<Prayer> labels;
  if (beforeFajr) {
    pts = [
      nIsha,
      nMiddle,
      nLastThird,
      tFajr,
      tSunrise,
      tDhuhr,
      tAsr,
      tMaghrib,
      tIsha,
      tMiddle,
      tLastThird,
      tFajr.add(const Duration(days: 1)),
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
      tFajr,
      tSunrise,
      tDhuhr,
      tAsr,
      tMaghrib,
      tIsha,
      tMiddle,
      tLastThird,
      tFajr.add(const Duration(days: 1)),
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

  // Fallback: pick the last start that is <= now.
  int idx = -1;
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
