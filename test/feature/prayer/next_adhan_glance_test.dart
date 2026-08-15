import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_day_models.dart';
import 'package:tawaq/feature/prayer/domain/prayer_slots.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart';

PrayerDaySnapshot _buildSnapshot({
  required TZDateTime now,
  Location? location,
}) {
  location ??= getLocation('Asia/Riyadh');
  final todayDate = TZDateTime(location, now.year, now.month, now.day);
  final yesterdayDate = todayDate.subtract(const Duration(days: 1));

  final today = PrayerTimes(
    date: todayDate,
    coordinates: Coordinates(24.7136, 46.6753),
    calculationMethod: const UmmAlQura(),
  );
  final yesterday = PrayerTimes(
    date: yesterdayDate,
    coordinates: Coordinates(24.7136, 46.6753),
    calculationMethod: const UmmAlQura(),
  );
  final todaySunnah = SunnahTimes(today);
  final yesterdaySunnah = SunnahTimes(yesterday);

  final timeline = PrayerDayTimeline(
    fajrToday: TZDateTime.from(today.fajr, location),
    sunriseToday: TZDateTime.from(today.sunrise, location),
    dhuhrToday: TZDateTime.from(today.dhuhr, location),
    asrToday: TZDateTime.from(today.asr, location),
    maghribToday: TZDateTime.from(today.maghrib, location),
    ishaToday: TZDateTime.from(today.isha, location),
    ishaYesterday: TZDateTime.from(yesterday.isha, location),
    middleOfNightToday: TZDateTime.from(
      todaySunnah.middleOfTheNight,
      location,
    ),
    middleOfNightYesterday: TZDateTime.from(
      yesterdaySunnah.middleOfTheNight,
      location,
    ),
    lastThirdToday: TZDateTime.from(
      todaySunnah.lastThirdOfTheNight,
      location,
    ),
    lastThirdYesterday: TZDateTime.from(
      yesterdaySunnah.lastThirdOfTheNight,
      location,
    ),
  );

  return PrayerDaySnapshot(
    now: now,
    location: location,
    bundle: PrayerDayBundle(
      today: today,
      yesterday: yesterday,
      todaySunnah: todaySunnah,
      yesterdaySunnah: yesterdaySunnah,
      timeline: timeline,
    ),
  );
}

void main() {
  setUpAll(tz.initializeTimeZones);

  group('resolveNextAdhanGlance', () {
    test('before fajr returns fajr today', () {
      final location = getLocation('Asia/Riyadh');
      final snapshot = _buildSnapshot(
        now: TZDateTime(location, 2026, 6, 9, 3),
        location: location,
      );

      final glance = resolveNextAdhanGlance(snapshot);
      expect(glance, isNotNull);
      expect(glance!.prayer, Prayer.fajr);
      expect(glance.adhanTime, snapshot.timeline.fajrToday);
    });

    test('after dhuhr returns asr', () {
      final location = getLocation('Asia/Riyadh');
      final snapshot = _buildSnapshot(
        now: TZDateTime(location, 2026, 6, 9, 13),
        location: location,
      );

      final glance = resolveNextAdhanGlance(snapshot);
      expect(glance, isNotNull);
      expect(glance!.prayer, Prayer.asr);
      expect(glance.adhanTime, snapshot.timeline.asrToday);
    });

    test('after isha wraps to tomorrow fajr', () {
      final location = getLocation('Asia/Riyadh');
      final snapshot = _buildSnapshot(
        now: TZDateTime(location, 2026, 6, 9, 23),
        location: location,
      );

      final glance = resolveNextAdhanGlance(snapshot);
      expect(glance, isNotNull);
      expect(glance!.prayer, Prayer.fajr);
      expect(
        glance.adhanTime,
        snapshot.timeline.fajrToday.add(const Duration(days: 1)),
      );
    });
  });

  group('formatTrayRemaining', () {
    test('formats hours and minutes', () {
      expect(
        formatTrayRemaining(const Duration(hours: 2, minutes: 14)),
        '2h 14m',
      );
      expect(formatTrayRemaining(const Duration(hours: 1)), '1h');
      expect(formatTrayRemaining(const Duration(minutes: 14)), '14m');
      expect(formatTrayRemaining(const Duration(seconds: 30)), '<1m');
    });
  });
}
