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
  required PrayerTimes todaysPrayerTimes,
  required PrayerTimes yesterdaysPrayerTimes,
  required SunnahTimes todaysSunnahTimes,
  required SunnahTimes yesterdaysSunnahTimes,
}) {
  // -------------------------------------------------------------------------
  // 1️⃣  Determine the current context with today's timings.
  // -------------------------------------------------------------------------
  final currentPrayerTime =
      todaysPrayerTimes.getCurrentPrayerDateTime(location);
  final currentPrayer = todaysPrayerTimes.currentPrayer(date: currentTime);
  final nextPrayer = todaysPrayerTimes.nextPrayer(date: currentTime);

  // Grace period: show the *current* prayer for up to 30 min after its time.
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
  //      the short window *before* (Fajr − 1 h).
  // -------------------------------------------------------------------------
  final fajrHour = todaysPrayerTimes.fajr.toLocation(location).hour;
  final beforeFajrMinusOneHour = currentTime.hour < fajrHour - 1;

  final effectivePrayerTimes =
      beforeFajrMinusOneHour ? yesterdaysPrayerTimes : todaysPrayerTimes;
  final effectiveSunnahTimes =
      beforeFajrMinusOneHour ? yesterdaysSunnahTimes : todaysSunnahTimes;

  // -------------------------------------------------------------------------
  // 3️⃣  Special night-time cases.
  // -------------------------------------------------------------------------
  final isBeforeMidnight = nextPrayer == Prayer.fajrAfter;
  final isAfterMidnightAndBeforeFajr = currentPrayer == Prayer.ishaBefore &&
      todaysPrayerTimes.fajr
              .toLocation(location)
              .difference(currentTime)
              .inHours >=
          1;

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
      isCountdown: true,
    );
  }

  // -------------------------------------------------------------------------
  // 4️⃣  Default – show the *next* prayer.
  // -------------------------------------------------------------------------
  return PrayerCardDecision(
    referenceTime: effectivePrayerTimes.getNextPrayerDateTime(location),
    prayer: nextPrayer,
    isCountdown: true,
  );
}
