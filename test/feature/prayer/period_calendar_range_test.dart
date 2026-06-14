import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_analytics.dart';
import 'package:tawaq/feature/prayer/domain/services/prayer_analytics_calculator.dart';

void main() {
  group('PrayerAnalyticsCalculator.periodCalendarRange', () {
    final anchor = DateTime(2026, 1, 29, 15, 30);

    test('weekly range is 7 inclusive calendar days', () {
      final range = PrayerAnalyticsCalculator.periodCalendarRange(
        PrayerAnalyticsPeriod.weekly,
        anchor,
      );

      expect(range.start, DateTime(2026, 1, 23));
      expect(range.end.day, 29);
      expect(
        PrayerAnalyticsCalculator.calendarDaysInPeriod(
          PrayerAnalyticsPeriod.weekly,
          anchor,
        ),
        7,
      );
    });

    test('monthly range is 30 inclusive calendar days', () {
      final range = PrayerAnalyticsCalculator.periodCalendarRange(
        PrayerAnalyticsPeriod.monthly,
        anchor,
      );

      expect(range.start, DateTime(2025, 12, 31));
      expect(
        PrayerAnalyticsCalculator.calendarDaysInPeriod(
          PrayerAnalyticsPeriod.monthly,
          anchor,
        ),
        30,
      );
    });

    test('yearly range starts 11 months before anchor month', () {
      final range = PrayerAnalyticsCalculator.periodCalendarRange(
        PrayerAnalyticsPeriod.yearly,
        anchor,
      );

      expect(range.start, DateTime(2025, 2));
      expect(range.end.day, 29);
    });

    test('expected prayers uses same calendar day count as range', () {
      final firstRecorded = DateTime(2025);
      final expected = PrayerAnalyticsCalculator.calculateExpectedPrayers(
        period: PrayerAnalyticsPeriod.weekly,
        firstRecordedDate: firstRecorded,
        now: anchor,
      );

      expect(expected, 7 * PrayerAnalyticsCalculator.prayersPerDay);
    });
  });
}
