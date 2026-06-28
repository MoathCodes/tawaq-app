import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/feature/prayer/domain/prayer_calendar.dart';
import 'package:tawaq/feature/prayer/domain/services/adhan_time_utils.dart';

void main() {
  group('adhan time utils', () {
    test('applyAdhanAdjustment adds minutes', () {
      final base = DateTime(2026, 6, 9, 12);
      final adjusted = applyAdhanAdjustment(
        prayerTime: base,
        prayer: Prayer.dhuhr,
        adjustments: {Prayer.dhuhr: 5},
      );
      expect(adjusted, base.add(const Duration(minutes: 5)));
    });

    test('didCrossPrayerTime detects boundary within window', () {
      final target = DateTime(2026, 6, 9, 12);
      expect(
        didCrossPrayerTime(
          previous: target.subtract(const Duration(seconds: 1)),
          now: target.add(const Duration(seconds: 1)),
          target: target,
        ),
        isTrue,
      );
      expect(
        didCrossPrayerTime(
          previous: target.subtract(const Duration(minutes: 5)),
          now: target.add(const Duration(minutes: 5)),
          target: target,
        ),
        isFalse,
      );
    });

    test('didCrossPrayerTime does not fire twice after crossing', () {
      final target = DateTime(2026, 6, 9, 5, 30);
      expect(
        didCrossPrayerTime(
          previous: target.add(const Duration(seconds: 1)),
          now: target.add(const Duration(seconds: 2)),
          target: target,
        ),
        isFalse,
      );
    });

    test('didCrossPrayerTime fires late within the catch-up window', () {
      final target = DateTime(2026, 6, 9, 5, 30);
      expect(
        didCrossPrayerTime(
          previous: target.subtract(const Duration(seconds: 1)),
          now: target.add(const Duration(minutes: 3)),
          target: target,
          window: const Duration(minutes: 5),
        ),
        isTrue,
      );
    });

    test('didCrossPrayerTime skips crossings older than the window', () {
      final target = DateTime(2026, 6, 9, 5, 30);
      expect(
        didCrossPrayerTime(
          previous: target.subtract(const Duration(minutes: 1)),
          now: target.add(const Duration(minutes: 30)),
          target: target,
          window: const Duration(minutes: 5),
        ),
        isFalse,
      );
    });

    test('didCrossPrayerTime ignores a target still in the future', () {
      final target = DateTime(2026, 6, 9, 5, 30);
      expect(
        didCrossPrayerTime(
          previous: target.subtract(const Duration(minutes: 2)),
          now: target.subtract(const Duration(seconds: 1)),
          target: target,
          window: const Duration(minutes: 5),
        ),
        isFalse,
      );
    });

    test('didCrossPrayerTime drops a catch-up once the next prayer begins', () {
      final maghrib = DateTime(2026, 6, 9, 19);
      final isha = maghrib.add(const Duration(minutes: 10));
      // Woke 12 min after maghrib: within the flat 20 min window, but isha has
      // already begun, so maghrib must not fire.
      expect(
        didCrossPrayerTime(
          previous: maghrib.subtract(const Duration(minutes: 1)),
          now: maghrib.add(const Duration(minutes: 12)),
          target: maghrib,
          window: const Duration(minutes: 20),
          cutoff: isha,
        ),
        isFalse,
      );
    });

    test('didCrossPrayerTime catches up while before the next prayer', () {
      final maghrib = DateTime(2026, 6, 9, 19);
      final isha = maghrib.add(const Duration(minutes: 10));
      expect(
        didCrossPrayerTime(
          previous: maghrib.subtract(const Duration(minutes: 1)),
          now: maghrib.add(const Duration(minutes: 8)),
          target: maghrib,
          window: const Duration(minutes: 20),
          cutoff: isha,
        ),
        isTrue,
      );
    });

    test('calendarDayKeyFromDate is stable per calendar day', () {
      expect(calendarDayKeyFromDate(DateTime(2026, 6, 9)), 20260609);
    });
  });
}
