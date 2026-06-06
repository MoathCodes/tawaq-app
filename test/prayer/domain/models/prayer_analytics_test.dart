import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_analytics.dart';

void main() {
  group('PrayerAnalyticsPeriod', () {
    group('duration', () {
      // test('daily returns 1 day', () {
      //   expect(PrayerAnalyticsPeriod.daily.duration, 
      //const Duration(days: 1));
      // });

      test('weekly returns 7 days', () {
        expect(PrayerAnalyticsPeriod.weekly.duration, const Duration(days: 7));
      });

      test('monthly returns 30 days', () {
        expect(
          PrayerAnalyticsPeriod.monthly.duration,
          const Duration(days: 30),
        );
      });

      test('yearly returns 365 days', () {
        expect(
          PrayerAnalyticsPeriod.yearly.duration,
          const Duration(days: 365),
        );
      });
    });

    group('values', () {
      test('has 4 periods', () {
        expect(PrayerAnalyticsPeriod.values, hasLength(4));
      });

      test('contains all expected periods', () {
        expect(
          PrayerAnalyticsPeriod.values,
          containsAll([
            // PrayerAnalyticsPeriod.daily,
            PrayerAnalyticsPeriod.weekly,
            PrayerAnalyticsPeriod.monthly,
            PrayerAnalyticsPeriod.yearly,
          ]),
        );
      });
    });
  });

  group('PrayerAnalytics', () {
    group('empty factory', () {
      test('returns analytics with all zeros', () {
        final analytics = PrayerAnalytics.empty();

        expect(analytics.period, PrayerAnalyticsPeriod.weekly);
        expect(analytics.completionPercentage, 0);
        expect(analytics.currentStreak, 0);
        expect(analytics.bestStreak, 0);
        expect(analytics.jamaahPercentage, 0);
        expect(analytics.onTimePercentage, 0);
        expect(analytics.missedPercentage, 0);
        expect(analytics.latePercentage, 0);
      });
    });

    group('constructor', () {
      test('creates analytics with all fields', () {
        const analytics = PrayerAnalytics(
          period: PrayerAnalyticsPeriod.monthly,
          completionPercentage: 0.85,
          currentStreak: 7,
          bestStreak: 14,
          jamaahPercentage: 0.5,
          onTimePercentage: 0.35,
          missedPercentage: 0.1,
          latePercentage: 0.05,
        );

        expect(analytics.period, PrayerAnalyticsPeriod.monthly);
        expect(analytics.completionPercentage, 0.85);
        expect(analytics.currentStreak, 7);
        expect(analytics.bestStreak, 14);
        expect(analytics.jamaahPercentage, 0.5);
        expect(analytics.onTimePercentage, 0.35);
        expect(analytics.missedPercentage, 0.1);
        expect(analytics.latePercentage, 0.05);
      });
    });

    group('copyWith', () {
      // test('updates period while preserving other fields', () {
      //   final original = PrayerAnalytics.empty();

      //   final updated = original.copyWith(period: 
      // PrayerAnalyticsPeriod.daily);

      //   expect(updated.period, PrayerAnalyticsPeriod.daily);
      //   expect(updated.completionPercentage, original.completionPercentage);
      // });

      test('updates streaks', () {
        final original = PrayerAnalytics.empty();

        final updated = original.copyWith(currentStreak: 5, bestStreak: 10);

        expect(updated.currentStreak, 5);
        expect(updated.bestStreak, 10);
      });

      test('updates percentages', () {
        final original = PrayerAnalytics.empty();

        final updated = original.copyWith(
          completionPercentage: 0.9,
          jamaahPercentage: 0.6,
          onTimePercentage: 0.3,
          latePercentage: 0.05,
          missedPercentage: 0.05,
        );

        expect(updated.completionPercentage, 0.9);
        expect(updated.jamaahPercentage, 0.6);
        expect(updated.onTimePercentage, 0.3);
        expect(updated.latePercentage, 0.05);
        expect(updated.missedPercentage, 0.05);
      });
    });

    group('equality', () {
      test('two analytics with same values are equal', () {
        const a = PrayerAnalytics(
          period: PrayerAnalyticsPeriod.weekly,
          completionPercentage: 0.8,
          currentStreak: 3,
          bestStreak: 5,
          jamaahPercentage: 0.4,
          onTimePercentage: 0.4,
          missedPercentage: 0.1,
          latePercentage: 0.1,
        );
        const b = PrayerAnalytics(
          period: PrayerAnalyticsPeriod.weekly,
          completionPercentage: 0.8,
          currentStreak: 3,
          bestStreak: 5,
          jamaahPercentage: 0.4,
          onTimePercentage: 0.4,
          missedPercentage: 0.1,
          latePercentage: 0.1,
        );

        expect(a, equals(b));
      });

      test('analytics with different values are not equal', () {
        const a = PrayerAnalytics(
          period: PrayerAnalyticsPeriod.weekly,
          completionPercentage: 0.8,
          currentStreak: 3,
          bestStreak: 5,
          jamaahPercentage: 0.4,
          onTimePercentage: 0.4,
          missedPercentage: 0.1,
          latePercentage: 0.1,
        );
        const b = PrayerAnalytics(
          period: PrayerAnalyticsPeriod.monthly, // Different period
          completionPercentage: 0.8,
          currentStreak: 3,
          bestStreak: 5,
          jamaahPercentage: 0.4,
          onTimePercentage: 0.4,
          missedPercentage: 0.1,
          latePercentage: 0.1,
        );

        expect(a, isNot(equals(b)));
      });
    });
  });
}
