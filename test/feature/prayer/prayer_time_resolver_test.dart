import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_day_bundle.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_day_snapshot.dart';
import 'package:tawaq/core/utils/prayer_extensions.dart';
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
    coordinates: const Coordinates(24.7136, 46.6753),
    calculationMethod: const UmmAlQura(),
  );
  final yesterday = PrayerTimes(
    date: yesterdayDate,
    coordinates: const Coordinates(24.7136, 46.6753),
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

  group('resolveSunnahTime', () {
    test('before fajr uses yesterday last third for ishaBefore', () {
      final location = getLocation('Asia/Riyadh');
      final snapshot = _buildSnapshot(
        now: TZDateTime(location, 2026, 6, 9, 3),
        location: location,
      );

      expect(
        resolveSunnahTime(
          prayer: Prayer.ishaBefore,
          snapshot: snapshot,
        ),
        snapshot.timeline.lastThirdYesterday,
      );
    });

    test('before fajr uses yesterday middle of night for fajrAfter', () {
      final location = getLocation('Asia/Riyadh');
      final snapshot = _buildSnapshot(
        now: TZDateTime(location, 2026, 6, 9, 3),
        location: location,
      );

      expect(
        resolveSunnahTime(
          prayer: Prayer.fajrAfter,
          snapshot: snapshot,
        ),
        snapshot.timeline.middleOfNightYesterday,
      );
    });

    test('after fajr uses today last third, not ishaBefore field', () {
      final location = getLocation('Asia/Riyadh');
      final snapshot = _buildSnapshot(
        now: TZDateTime(location, 2026, 6, 9, 12),
        location: location,
      );

      final resolved = resolveSunnahTime(
        prayer: Prayer.ishaBefore,
        snapshot: snapshot,
      );

      expect(resolved, snapshot.timeline.lastThirdToday);
      expect(
        resolved,
        isNot(snapshot.today.getTimesForPrayer(Prayer.ishaBefore, location)),
      );
      expect(
        resolved,
        isNot(snapshot.today.getTimesForPrayer(Prayer.isha, location)),
      );
    });

    test('after fajr uses today middle of night for fajrAfter', () {
      final location = getLocation('Asia/Riyadh');
      final snapshot = _buildSnapshot(
        now: TZDateTime(location, 2026, 6, 9, 12),
        location: location,
      );

      expect(
        resolveSunnahTime(
          prayer: Prayer.fajrAfter,
          snapshot: snapshot,
        ),
        snapshot.timeline.middleOfNightToday,
      );
    });
  });
}
