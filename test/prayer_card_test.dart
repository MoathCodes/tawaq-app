import 'dart:io';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:hasanat/core/utils/prayer_extensions.dart';
import 'package:hasanat/feature/prayer/data/database/prayer_database.dart';
import 'package:hasanat/feature/prayer/data/repository/prayer_repo.dart';
import 'package:hasanat/feature/prayer/domain/services/prayer_service.dart';
import 'package:hasanat/feature/settings/data/models/prayer_settings_model.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart';

// BEGIN TESTABLE LOGIC ------------------------------------------------------

void main() async {
  tz.initializeTimeZones();
  final database = LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'prayer.db'));
    return NativeDatabase(file);
  });
  final talker = TalkerFlutter.init();
  final service = PrayerService(
      PrayerRepo(prayerDatabase: PrayerDatabase(database), talker: talker),
      PrayerSettings.defaultSettings(),
      talker);
  final location = getLocation('Asia/Riyadh');

  // final currentTime = DateTime.now().toLocation(location);
  final currentTime = DateTime(2025, 6, 21, 3, 12, 0).toLocation(location);
  final todaysPrayerTimes = service.getTodaysPrayerTimes(currentTime);
  final yesterdaysPrayerTimes = service
      .getTodaysPrayerTimes(currentTime.subtract(const Duration(days: 1)));
  final todaysSunnahTimes = service.getSunnahTime(todaysPrayerTimes);
  final yesterdaysSunnahTimes = service.getSunnahTime(yesterdaysPrayerTimes);

  final decision = computePrayerCardDecision(
    currentTime: currentTime,
    location: location,
    todaysPrayerTimes: todaysPrayerTimes,
    yesterdaysPrayerTimes: yesterdaysPrayerTimes,
    todaysSunnahTimes: todaysSunnahTimes,
    yesterdaysSunnahTimes: yesterdaysSunnahTimes,
  );

  print(decision);
}

/// Pure, synchronous and side-effect-free port of the decision making that is
/// currently performed inside the [PrayerCard.build] streaming loop.
///
/// * **No** access to Riverpod, Services or logging.
/// * Accepts all required data as parameters, making it trivial to unit-test.
/// * Returns a [PrayerCardDecision] that the caller can then map to a concrete
///   [PrayerCardInfo] through the existing `_generateCard` helper (or any other
///   means in tests).
PrayerCardDecision computePrayerCardDecision({
  required DateTime currentTime,
  required Location location,
  required PrayerTimes todaysPrayerTimes,
  required PrayerTimes yesterdaysPrayerTimes,
  required SunnahTimes todaysSunnahTimes,
  required SunnahTimes yesterdaysSunnahTimes,
}) {
  // -----------------------------------------------------------------------
  // 1. Figure out what the "current" and "next" prayers are for `currentTime`.
  // -----------------------------------------------------------------------
  final DateTime currentPrayerTime =
      todaysPrayerTimes.getCurrentPrayerDateTime(location);
  final bool isCurrentPrayerFinished = currentTime.isAfter(currentPrayerTime);
  final Prayer currentPrayer =
      todaysPrayerTimes.currentPrayer(date: currentTime);
  final Prayer nextPrayer = todaysPrayerTimes.nextPrayer(date: currentTime);

  final bool isBeforeMidnight = nextPrayer == Prayer.fajrAfter;
  final bool isAfterMidnightAndBeforeFajr =
      currentPrayer == Prayer.ishaBefore &&
          todaysPrayerTimes.fajr
                  .toLocation(location)
                  .difference(currentTime)
                  .inHours >=
              1;

  // -----------------------------------------------------------------------
  // 2. Case A – show information about the *current* prayer for up to 30 min
  //    after its time has passed.
  // -----------------------------------------------------------------------
  if (isCurrentPrayerFinished &&
      currentPrayerTime.difference(currentTime).inMinutes.abs() <= 30) {
    print("showing current prayer");
    return PrayerCardDecision(
      referenceTime: currentPrayerTime,
      prayer: currentPrayer,
      reverseTime: false,
    );
  }

  // -----------------------------------------------------------------------
  // 3. We are *before* the next prayer. Decide which PrayerTimes/SunnahTimes
  //    dataset to look at (today vs. yesterday) – this mirrors the original
  //    `thisPrayerTimes` / `thisSunnahTimes` handling in `build()`.
  // -----------------------------------------------------------------------
  late final PrayerTimes effectivePrayerTimes;
  late final SunnahTimes effectiveSunnahTimes;

  if (currentTime.hour <
      (todaysPrayerTimes.fajr.toLocation(location).hour - 1)) {
    // Before (Fajr ‑ 1h) ⇒ use *yesterday's* timings.
    effectivePrayerTimes = yesterdaysPrayerTimes;
    effectiveSunnahTimes = yesterdaysSunnahTimes;
  } else {
    // Otherwise stick to today's timings.
    effectivePrayerTimes = todaysPrayerTimes;
    effectiveSunnahTimes = todaysSunnahTimes;
  }

  // -----------------------------------------------------------------------
  // 4. Case B – Special handling around midnight / last third of the night.
  // -----------------------------------------------------------------------
  if (isBeforeMidnight) {
    print("showing middle of the night");
    return PrayerCardDecision(
      referenceTime: effectiveSunnahTimes.middleOfTheNight.toLocation(location),
      prayer: Prayer.fajrAfter,
      reverseTime: true,
    );
  } else if (isAfterMidnightAndBeforeFajr) {
    print("showing last third of the night");
    return PrayerCardDecision(
      referenceTime:
          effectiveSunnahTimes.lastThirdOfTheNight.toLocation(location),
      prayer: Prayer.ishaBefore,
      reverseTime: false,
    );
  }

  // -----------------------------------------------------------------------
  // 5. Default – display the *next* prayer.
  // -----------------------------------------------------------------------
  print("showing next prayer");
  return PrayerCardDecision(
    referenceTime: effectivePrayerTimes.getNextPrayerDateTime(location),
    prayer: nextPrayer,
    reverseTime: true,
  );
}

/// A small DTO that captures the information required to render a single
/// prayer card. This is intentionally minimal so it can be easily asserted
/// against in unit-tests **without** touching any presentation concerns.
class PrayerCardDecision {
  /// The point in time the card should count **to** (if [reverseTime] is
  /// true) or **from** (if it is false).
  final DateTime referenceTime;

  /// Which prayer the card is about.
  final Prayer prayer;

  /// Whether the countdown should be reversed (i.e. [referenceTime] lies in
  /// the future) or shown as time elapsed (lies in the past).
  final bool reverseTime;

  const PrayerCardDecision({
    required this.referenceTime,
    required this.prayer,
    required this.reverseTime,
  });

  @override
  String toString() =>
      'PrayerCardDecision(prayer: $prayer, reverseTime: $reverseTime, referenceTime: $referenceTime)';
}

// END TESTABLE LOGIC --------------------------------------------------------
