import 'dart:io';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hasanat/feature/prayer/data/database/prayer_database.dart';
import 'package:hasanat/feature/prayer/data/repository/prayer_repo.dart';
import 'package:hasanat/feature/prayer/domain/services/prayer_service.dart';
import 'package:hasanat/feature/settings/data/models/prayer_settings_model.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart';

void main() {
  setUpAll(tz.initializeTimeZones);

  group('Prayer Card Decision Tests', () {
    late Location location;
    late PrayerService service;

    setUpAll(() async {
      location = getLocation('Asia/Riyadh');

      // Set up service like in the original test
      final database = LazyDatabase(() async {
        final dbFolder = await getApplicationDocumentsDirectory();
        final file = File(p.join(dbFolder.path, 'prayer_test.db'));
        return NativeDatabase(file);
      });
      final talker = TalkerFlutter.init();
      service = PrayerService(
          PrayerRepo(
              prayerDatabase: PrayerDatabase(database, talker), talker: talker),
          PrayerSettings.defaultSettings(),
          talker);
    });

    test(
        'Prayer decision at 11:15 PM should show midnight as next prayer with correct time source',
        () {
      // Create specific time for 11:15 PM (matching the original bug report)
      final testTime = TZDateTime(location, 2024, 1, 15, 23, 15);

      // Get prayer times using the service (same as original test)
      final todaysPrayerTimes = service.getTodaysPrayerTimes(testTime);
      final yesterdaysPrayerTimes = service
          .getTodaysPrayerTimes(testTime.subtract(const Duration(days: 1)));
      final todaysSunnahTimes = service.getSunnahTime(todaysPrayerTimes);
      final yesterdaysSunnahTimes =
          service.getSunnahTime(yesterdaysPrayerTimes);

      // Call the decision function
      final decision = computePrayerCardDecision(
        currentTime: testTime,
        location: location,
        todaysPrayerTimes: todaysPrayerTimes,
        yesterdaysPrayerTimes: yesterdaysPrayerTimes,
        todaysSunnahTimes: todaysSunnahTimes,
        yesterdaysSunnahTimes: yesterdaysSunnahTimes,
      );

      // Debug output
      print(
          'Test time: ${testTime.hour}:${testTime.minute.toString().padLeft(2, '0')}');
      print('Decision prayer: ${decision.prayer}');
      print('Reference time: ${decision.referenceTime}');
      print('Is countdown: ${decision.isCountdown}');
      print(
          'Expected midnight time: ${TZDateTime.from(todaysSunnahTimes.middleOfTheNight, location)}');

      // At 11:15 PM, next prayer should be fajrAfter (midnight)
      expect(decision.prayer, equals(Prayer.fajrAfter));
      expect(decision.isCountdown, isTrue);

      // The reference time should be from SunnahTimes.middleOfTheNight
      final expectedMidnightTime =
          TZDateTime.from(todaysSunnahTimes.middleOfTheNight, location);
      expect(decision.referenceTime, equals(expectedMidnightTime));

      // Ensure the time is not negative (future time)
      final duration = decision.referenceTime.difference(testTime);
      expect(duration.isNegative, isFalse);
      expect(duration.inHours, greaterThan(0));

      // Verify the midnight time is sourced from SunnahTimes, not PrayerTimesData
      // This is the key fix - ensuring we use the correct time source
      expect(decision.referenceTime,
          isNot(equals(TZDateTime.from(todaysPrayerTimes.fajr, location))));
    });

    test('Prayer decision after midnight should show last third of night', () {
      // Create specific time for 12:30 AM (after midnight, before fajr)
      final testTime = TZDateTime(location, 2024, 1, 16, 0, 30);

      final todaysPrayerTimes = service.getTodaysPrayerTimes(testTime);
      final yesterdaysPrayerTimes = service
          .getTodaysPrayerTimes(testTime.subtract(const Duration(days: 1)));
      final todaysSunnahTimes = service.getSunnahTime(todaysPrayerTimes);
      final yesterdaysSunnahTimes =
          service.getSunnahTime(yesterdaysPrayerTimes);

      final decision = computePrayerCardDecision(
        currentTime: testTime,
        location: location,
        todaysPrayerTimes: todaysPrayerTimes,
        yesterdaysPrayerTimes: yesterdaysPrayerTimes,
        todaysSunnahTimes: todaysSunnahTimes,
        yesterdaysSunnahTimes: yesterdaysSunnahTimes,
      );

      // After midnight but before fajr, should show last third of night
      expect(decision.prayer, equals(Prayer.ishaBefore));
      expect(decision.isCountdown, isFalse);

      // The reference time should be from SunnahTimes.lastThirdOfTheNight
      final expectedLastThirdTime =
          TZDateTime.from(todaysSunnahTimes.lastThirdOfTheNight, location);
      expect(decision.referenceTime, equals(expectedLastThirdTime));
    });
  });
}
