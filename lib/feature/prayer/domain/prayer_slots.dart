import 'package:adhan_dart/adhan_dart.dart';
import 'package:tawaq/core/utils/prayer_extensions.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_card_decision.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_day_snapshot.dart';
import 'package:timezone/timezone.dart';

/// The five obligatory prayers used across schedule, analytics, and alerts.
const List<Prayer> kObligatoryPrayers = [
  Prayer.fajr,
  Prayer.dhuhr,
  Prayer.asr,
  Prayer.maghrib,
  Prayer.isha,
];

/// Obligatory prayers that can trigger adhan — alias for scheduler use.
const List<Prayer> obligatoryAdhanPrayers = kObligatoryPrayers;

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

DateTime _slotTimeOf({
  required Prayer prayer,
  required DateTime currentTime,
  required Location location,
  required PrayerDayTimeline timeline,
  required PrayerTimes todaysPrayerTimes,
}) {
  return switch (prayer) {
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
    _ => todaysPrayerTimes.getTimesForPrayer(prayer, location),
  };
}

/// Returns the active prayer slot for [currentTime], including night windows.
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

/// Picks the hero card prayer and whether to count down or up.
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

  final cp = getCurrentPrayer(
    currentTime: currentTime,
    location: location,
    timeline: timeline,
  );

  var currentIdx = orderedPrayers.indexOf(cp);
  if (currentIdx == -1) currentIdx = 0;
  final nextIdx = (currentIdx + 1) % orderedPrayers.length;

  var currentRef = _slotTimeOf(
    prayer: orderedPrayers[currentIdx],
    currentTime: currentTime,
    location: location,
    timeline: timeline,
    todaysPrayerTimes: todaysPrayerTimes,
  );
  var nextRef = _slotTimeOf(
    prayer: orderedPrayers[nextIdx],
    currentTime: currentTime,
    location: location,
    timeline: timeline,
    todaysPrayerTimes: todaysPrayerTimes,
  );

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

/// Whether [rowPrayer] is the highlighted row for [currentPrayer].
bool isScheduleRowCurrent({
  required Prayer rowPrayer,
  required Prayer currentPrayer,
}) {
  if (currentPrayer.isObligatory) {
    return rowPrayer == currentPrayer;
  }
  if (currentPrayer == Prayer.ishaBefore || currentPrayer == Prayer.fajrAfter) {
    return rowPrayer == Prayer.fajr;
  }
  return rowPrayer == Prayer.dhuhr;
}

/// Next obligatory prayer after [currentPrayer] in the schedule list.
Prayer? scheduleNextPrayer(Prayer currentPrayer) {
  final currentIdx = kObligatoryPrayers.indexWhere(
    (prayer) => isScheduleRowCurrent(
      rowPrayer: prayer,
      currentPrayer: currentPrayer,
    ),
  );
  if (currentIdx == -1 || currentIdx + 1 >= kObligatoryPrayers.length) {
    return null;
  }
  return kObligatoryPrayers[currentIdx + 1];
}
