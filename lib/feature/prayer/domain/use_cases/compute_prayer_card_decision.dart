import 'package:adhan_dart/adhan_dart.dart';
import 'package:hasanat/core/utils/prayer_extensions.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_card_decision.dart';
import 'package:timezone/timezone.dart';

/// Pure, synchronous port of the decision-making logic that lives inside the
/// streaming loop of `PrayerCard.build()`.
///
/// Keeping it completely side-effect free (no Riverpod, no I/O) makes it
/// simplicity itself to unit-test.
PrayerCardDecision computePrayerCardDecision({
  required DateTime currentTime,
  required Location location,
  required PrayerTimesData todaysPrayerTimes,
  required PrayerTimesData yesterdaysPrayerTimes,
  required SunnahTimes todaysSunnahTimes,
  required SunnahTimes yesterdaysSunnahTimes,
}) {
  // -------------------------------------------------------------------------
  // 1️⃣  Determine the current context with today's timings.
  // -------------------------------------------------------------------------
  final currentPrayerTime =
      todaysPrayerTimes.getCurrentPrayerDateTime(location);
  final currentPrayer = todaysPrayerTimes.currentPrayer(date: currentTime);

  // Grace period: show the *current* prayer for up to 30 min after its time.
  final minutesSinceCurrentPrayer =
      currentTime.difference(currentPrayerTime).inMinutes;
  final withinGracePeriod =
      minutesSinceCurrentPrayer >= 0 && minutesSinceCurrentPrayer <= 30;
  if (withinGracePeriod) {
    return PrayerCardDecision(
      referenceTime: currentPrayerTime,
      prayer: currentPrayer,
      isCountdown: false,
    );
  }

  // -------------------------------------------------------------------------
  // 2️⃣  Decide whether we should look at yesterday's timings. This happens for
  //      the short window *before* (Fajr − 1 h), but only in very early hours.
  // -------------------------------------------------------------------------
  final todaysFajr = todaysPrayerTimes.fajr.toLocation(location);
  final beforeTodaysFajr = currentTime.isBefore(todaysFajr);
  final veryEarlyMorning =
      currentTime.hour <= 2; // Only very early morning hours (1-2 AM)
  final shouldUseYesterday = beforeTodaysFajr && veryEarlyMorning;

  final effectivePrayerTimes =
      shouldUseYesterday ? yesterdaysPrayerTimes : todaysPrayerTimes;
  final effectiveSunnahTimes =
      shouldUseYesterday ? yesterdaysSunnahTimes : todaysSunnahTimes;

  // print(
  //     "shouldUseYesterday: $shouldUseYesterday (current: ${currentTime.hour}:${currentTime.minute}, fajr: ${todaysFajr.hour}:${todaysFajr.minute})");

  // -------------------------------------------------------------------------
  // 3️⃣  Special night-time cases.
  // -------------------------------------------------------------------------
  final effectiveNextPrayer =
      effectivePrayerTimes.nextPrayer(date: currentTime);

  final isBeforeMidnight =
      currentPrayer == Prayer.fajrAfter && effectiveNextPrayer == Prayer.fajr;
  final isAfterMidnightAndBeforeFajr = currentPrayer == Prayer.ishaBefore &&
      todaysPrayerTimes.fajr
              .toLocation(location)
              .difference(currentTime)
              .inHours >=
          1;

  // print("Effective prayer: $effectiveNextPrayer");
  // print("current prayer $currentPrayer");

  if (isBeforeMidnight) {
    return PrayerCardDecision(
      referenceTime: effectiveSunnahTimes.middleOfTheNight.toLocation(location),
      prayer: Prayer.fajrAfter,
      isCountdown: true,
    );
  }

  if (isAfterMidnightAndBeforeFajr) {
    return PrayerCardDecision(
      referenceTime:
          effectiveSunnahTimes.lastThirdOfTheNight.toLocation(location),
      prayer: Prayer.ishaBefore,
      isCountdown: false,
    );
  }

  // -------------------------------------------------------------------------
  // 4️⃣  Default – show the *next* prayer.
  // -------------------------------------------------------------------------
  // Use the effective prayer times to determine the next prayer
  final nextPrayerDateTime = switch (effectiveNextPrayer) {
    Prayer.fajr => effectivePrayerTimes.fajr.toLocation(location),
    Prayer.sunrise => effectivePrayerTimes.sunrise.toLocation(location),
    Prayer.dhuhr => effectivePrayerTimes.dhuhr.toLocation(location),
    Prayer.asr => effectivePrayerTimes.asr.toLocation(location),
    Prayer.maghrib => effectivePrayerTimes.maghrib.toLocation(location),
    Prayer.isha => effectivePrayerTimes.isha.toLocation(location),
    Prayer.ishaBefore =>
      effectiveSunnahTimes.lastThirdOfTheNight.toLocation(location),
    Prayer.fajrAfter =>
      effectiveSunnahTimes.middleOfTheNight.toLocation(location),
  };

  return PrayerCardDecision(
    referenceTime: nextPrayerDateTime,
    prayer: effectiveNextPrayer,
    isCountdown: true,
  );
}
