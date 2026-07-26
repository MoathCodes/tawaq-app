import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_day_snapshot.dart';
import 'package:tawaq/feature/prayer/domain/prayer_slots.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart';

PrayerDayTimeline _buildTimeline({
  required Location location,
  required PrayerTimes todaysPrayerTimes,
  required PrayerTimes yesterdaysPrayerTimes,
  required SunnahTimes todaysSunnahTimes,
  required SunnahTimes yesterdaysSunnahTimes,
}) {
  return PrayerDayTimeline(
    fajrToday: TZDateTime.from(todaysPrayerTimes.fajr, location),
    sunriseToday: TZDateTime.from(todaysPrayerTimes.sunrise, location),
    dhuhrToday: TZDateTime.from(todaysPrayerTimes.dhuhr, location),
    asrToday: TZDateTime.from(todaysPrayerTimes.asr, location),
    maghribToday: TZDateTime.from(todaysPrayerTimes.maghrib, location),
    ishaToday: TZDateTime.from(todaysPrayerTimes.isha, location),
    ishaYesterday: TZDateTime.from(yesterdaysPrayerTimes.isha, location),
    middleOfNightToday: TZDateTime.from(
      todaysSunnahTimes.middleOfTheNight,
      location,
    ),
    middleOfNightYesterday: TZDateTime.from(
      yesterdaysSunnahTimes.middleOfTheNight,
      location,
    ),
    lastThirdToday: TZDateTime.from(
      todaysSunnahTimes.lastThirdOfTheNight,
      location,
    ),
    lastThirdYesterday: TZDateTime.from(
      yesterdaysSunnahTimes.lastThirdOfTheNight,
      location,
    ),
  );
}

void main() {
  setUpAll(tz.initializeTimeZones);

  group('getCurrentPrayer', () {
    late Location location;
    late PrayerTimes todaysPrayerTimes;
    late PrayerTimes yesterdaysPrayerTimes;
    late SunnahTimes todaysSunnahTimes;
    late SunnahTimes yesterdaysSunnahTimes;

    late PrayerDayTimeline timeline;

    setUp(() {
      location = getLocation('Asia/Riyadh');

      // Create prayer times for a known date
      final today = TZDateTime(location, 2024, 6, 15);
      final yesterday = today.subtract(const Duration(days: 1));

      todaysPrayerTimes = PrayerTimes(
        date: today,
        coordinates: Coordinates(24.7136, 46.6753), // Riyadh
        calculationMethod: const UmmAlQura(),
      );
      yesterdaysPrayerTimes = PrayerTimes(
        date: yesterday,
        coordinates: Coordinates(24.7136, 46.6753),
        calculationMethod: const UmmAlQura(),
      );
      todaysSunnahTimes = SunnahTimes(todaysPrayerTimes);
      yesterdaysSunnahTimes = SunnahTimes(yesterdaysPrayerTimes);
      timeline = _buildTimeline(
        location: location,
        todaysPrayerTimes: todaysPrayerTimes,
        yesterdaysPrayerTimes: yesterdaysPrayerTimes,
        todaysSunnahTimes: todaysSunnahTimes,
        yesterdaysSunnahTimes: yesterdaysSunnahTimes,
      );
    });

    test('returns fajr when current time is during fajr', () {
      // Time after fajr but before sunrise
      final fajrTime = TZDateTime.from(todaysPrayerTimes.fajr, location);
      final testTime = fajrTime.add(const Duration(minutes: 15));

      final result = getCurrentPrayer(
        currentTime: testTime,
        location: location,
        timeline: timeline,
      );

      expect(result, Prayer.fajr);
    });

    test('returns sunrise when current time is after sunrise', () {
      final sunriseTime = TZDateTime.from(todaysPrayerTimes.sunrise, location);
      final testTime = sunriseTime.add(const Duration(minutes: 30));

      final result = getCurrentPrayer(
        currentTime: testTime,
        location: location,
        timeline: timeline,
      );

      expect(result, Prayer.sunrise);
    });

    test('returns dhuhr when current time is during dhuhr', () {
      final dhuhrTime = TZDateTime.from(todaysPrayerTimes.dhuhr, location);
      final testTime = dhuhrTime.add(const Duration(minutes: 30));

      final result = getCurrentPrayer(
        currentTime: testTime,
        location: location,
        timeline: timeline,
      );

      expect(result, Prayer.dhuhr);
    });

    test('returns asr when current time is during asr', () {
      final asrTime = TZDateTime.from(todaysPrayerTimes.asr, location);
      final testTime = asrTime.add(const Duration(minutes: 30));

      final result = getCurrentPrayer(
        currentTime: testTime,
        location: location,
        timeline: timeline,
      );

      expect(result, Prayer.asr);
    });

    test('returns maghrib when current time is during maghrib', () {
      final maghribTime = TZDateTime.from(todaysPrayerTimes.maghrib, location);
      final testTime = maghribTime.add(const Duration(minutes: 15));

      final result = getCurrentPrayer(
        currentTime: testTime,
        location: location,
        timeline: timeline,
      );

      expect(result, Prayer.maghrib);
    });

    test('returns isha when current time is during isha', () {
      final ishaTime = TZDateTime.from(todaysPrayerTimes.isha, location);
      final testTime = ishaTime.add(const Duration(minutes: 30));

      final result = getCurrentPrayer(
        currentTime: testTime,
        location: location,
        timeline: timeline,
      );

      expect(result, Prayer.isha);
    });

    test(
      'returns fajrAfter (midnight) when current time is after midnight',
      () {
        final middleOfNight = TZDateTime.from(
          todaysSunnahTimes.middleOfTheNight,
          location,
        );
        final testTime = middleOfNight.add(const Duration(minutes: 30));

        final result = getCurrentPrayer(
          currentTime: testTime,
          location: location,
          timeline: timeline,
        );

        expect(result, Prayer.fajrAfter);
      },
    );

    test('returns ishaBefore (last third) when in last third of night', () {
      final lastThird = TZDateTime.from(
        todaysSunnahTimes.lastThirdOfTheNight,
        location,
      );
      final testTime = lastThird.add(const Duration(minutes: 30));

      final result = getCurrentPrayer(
        currentTime: testTime,
        location: location,
        timeline: timeline,
      );

      expect(result, Prayer.ishaBefore);
    });

    test('handles early morning before fajr correctly', () {
      // 3 AM - should be in the night period using yesterday's times
      final testTime = TZDateTime(location, 2024, 6, 15, 3);

      final result = getCurrentPrayer(
        currentTime: testTime,
        location: location,
        timeline: timeline,
      );

      // Should be in last third or fajrAfter depending on exact times
      expect(
        [Prayer.fajrAfter, Prayer.ishaBefore].contains(result),
        isTrue,
        reason: 'Early morning should be in night prayer periods',
      );
    });

    test('handles exact prayer time boundary', () {
      final dhuhrTime = TZDateTime.from(todaysPrayerTimes.dhuhr, location);

      final result = getCurrentPrayer(
        currentTime: dhuhrTime,
        location: location,
        timeline: timeline,
      );

      expect(result, Prayer.dhuhr);
    });
  });

  group('computePrayerCardDecision', () {
    late Location location;
    late PrayerTimes todaysPrayerTimes;
    late PrayerTimes yesterdaysPrayerTimes;
    late SunnahTimes todaysSunnahTimes;
    late SunnahTimes yesterdaysSunnahTimes;

    late PrayerDayTimeline timeline;

    setUp(() {
      location = getLocation('Asia/Riyadh');

      final today = TZDateTime(location, 2024, 6, 15);
      final yesterday = today.subtract(const Duration(days: 1));

      todaysPrayerTimes = PrayerTimes(
        date: today,
        coordinates: Coordinates(24.7136, 46.6753),
        calculationMethod: const UmmAlQura(),
      );
      yesterdaysPrayerTimes = PrayerTimes(
        date: yesterday,
        coordinates: Coordinates(24.7136, 46.6753),
        calculationMethod: const UmmAlQura(),
      );
      todaysSunnahTimes = SunnahTimes(todaysPrayerTimes);
      yesterdaysSunnahTimes = SunnahTimes(yesterdaysPrayerTimes);
      timeline = _buildTimeline(
        location: location,
        todaysPrayerTimes: todaysPrayerTimes,
        yesterdaysPrayerTimes: yesterdaysPrayerTimes,
        todaysSunnahTimes: todaysSunnahTimes,
        yesterdaysSunnahTimes: yesterdaysSunnahTimes,
      );
    });

    test('returns countdown when closer to next prayer', () {
      // Just before dhuhr
      final dhuhrTime = TZDateTime.from(todaysPrayerTimes.dhuhr, location);
      final testTime = dhuhrTime.subtract(const Duration(minutes: 5));

      final result = computePrayerCardDecisionFromParts(
        currentTime: testTime,
        location: location,
        timeline: timeline,
        todaysPrayerTimes: todaysPrayerTimes,
      );

      expect(result.isCountdown, isTrue);
      expect(result.prayer, Prayer.dhuhr);
    });

    test('returns elapsed time when closer to current prayer', () {
      // Right after dhuhr starts
      final dhuhrTime = TZDateTime.from(todaysPrayerTimes.dhuhr, location);
      final testTime = dhuhrTime.add(const Duration(minutes: 5));

      final result = computePrayerCardDecisionFromParts(
        currentTime: testTime,
        location: location,
        timeline: timeline,
        todaysPrayerTimes: todaysPrayerTimes,
      );

      expect(result.isCountdown, isFalse);
      expect(result.prayer, Prayer.dhuhr);
    });

    test('switches to countdown at midpoint of prayer window', () {
      // Get dhuhr and asr times
      final dhuhrTime = TZDateTime.from(todaysPrayerTimes.dhuhr, location);
      final asrTime = TZDateTime.from(todaysPrayerTimes.asr, location);

      // Calculate midpoint
      final midpoint = dhuhrTime.add(
        Duration(
          milliseconds: (asrTime.difference(dhuhrTime).inMilliseconds / 2)
              .round(),
        ),
      );

      // Just after midpoint should show countdown to asr
      final testTime = midpoint.add(const Duration(minutes: 1));

      final result = computePrayerCardDecisionFromParts(
        currentTime: testTime,
        location: location,
        timeline: timeline,
        todaysPrayerTimes: todaysPrayerTimes,
      );

      expect(result.isCountdown, isTrue);
      expect(result.prayer, Prayer.asr);
    });

    test('referenceTime is in the future for countdown', () {
      final dhuhrTime = TZDateTime.from(todaysPrayerTimes.dhuhr, location);
      final testTime = dhuhrTime.subtract(const Duration(minutes: 10));

      final result = computePrayerCardDecisionFromParts(
        currentTime: testTime,
        location: location,
        timeline: timeline,
        todaysPrayerTimes: todaysPrayerTimes,
      );

      if (result.isCountdown) {
        expect(
          result.referenceTime.isAfter(testTime),
          isTrue,
          reason: 'Countdown reference should be in the future',
        );
      }
    });

    test('handles night prayer transitions correctly', () {
      // Late at night (11 PM)
      final testTime = TZDateTime(location, 2024, 6, 15, 23);

      final result = computePrayerCardDecisionFromParts(
        currentTime: testTime,
        location: location,
        timeline: timeline,
        todaysPrayerTimes: todaysPrayerTimes,
      );

      // Should be in isha or approaching midnight
      expect(
        [Prayer.isha, Prayer.fajrAfter].contains(result.prayer),
        isTrue,
        reason: 'Late night should show isha or midnight',
      );
    });
  });
}
