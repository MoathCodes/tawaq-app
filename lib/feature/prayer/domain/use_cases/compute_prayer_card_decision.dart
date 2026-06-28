import 'package:adhan_dart/adhan_dart.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_card_decision.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_day_snapshot.dart';
import 'package:tawaq/feature/prayer/domain/prayer_extensions.dart';
import 'package:tawaq/feature/prayer/domain/services/prayer_timeline.dart';
import 'package:timezone/timezone.dart';

/// Picks the hero card prayer and whether to count down or up.
///
/// Switches to the next prayer in the cycle when less than half of the current
/// slot remains ([PrayerCardDecision.isCountdown] becomes `true`).
PrayerCardDecision computePrayerCardDecision({
  required PrayerDaySnapshot snapshot,
}) {
  return computePrayerCardDecisionFromParts(
    currentTime: snapshot.now,
    location: snapshot.location,
    timeline: snapshot.timeline,
    todaysPrayerTimes: snapshot.today,
  );
}

/// Same as [computePrayerCardDecision] with explicit parts (for tests).
PrayerCardDecision computePrayerCardDecisionFromParts({
  required DateTime currentTime,
  required Location location,
  required PrayerDayTimeline timeline,
  required PrayerTimes todaysPrayerTimes,
}) {
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
    Prayer.isha => currentTime.isBefore(timeline.fajrToday)
        ? timeline.ishaYesterday
        : timeline.ishaToday,
    Prayer.fajrAfter => normalizeNightAfterIsha(
      sunnahTime: currentTime.isBefore(timeline.fajrToday)
          ? timeline.middleOfNightYesterday
          : timeline.middleOfNightToday,
      ishaAnchor: currentTime.isBefore(timeline.fajrToday)
          ? timeline.ishaYesterday
          : timeline.ishaToday,
      location: location,
    ),
    Prayer.ishaBefore => normalizeNightAfterIsha(
      sunnahTime: currentTime.isBefore(timeline.fajrToday)
          ? timeline.lastThirdYesterday
          : timeline.lastThirdToday,
      ishaAnchor: currentTime.isBefore(timeline.fajrToday)
          ? timeline.ishaYesterday
          : timeline.ishaToday,
      location: location,
    ),
    Prayer.fajr => timeline.fajrToday,
    _ => todaysPrayerTimes.getTimesForPrayer(p, location),
  };

  final cp = getCurrentPrayer(
    currentTime: currentTime,
    location: location,
    timeline: timeline,
  );

  var currentIdx = orderedPrayers.indexOf(cp);
  if (currentIdx == -1) currentIdx = 0;
  final nextIdx = (currentIdx + 1) % orderedPrayers.length;

  var currentRef = timeOf(orderedPrayers[currentIdx]);
  var nextRef = timeOf(orderedPrayers[nextIdx]);

  if (!nextRef.isAfter(currentRef)) {
    nextRef = nextRef.add(const Duration(days: 1));
  }
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
