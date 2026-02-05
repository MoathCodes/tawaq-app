import 'package:flutter_test/flutter_test.dart';
import 'package:hasanat/feature/prayer/data/models/prayer_completion.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_analytics.dart';
import 'package:hasanat/feature/prayer/domain/services/prayer_analytics_calculator.dart';

void main() {
  group('PrayerAnalyticsCalculator', () {
    group('calculateCompletionPercentage', () {
      test('returns 0 when no prayers expected', () {
        final result = PrayerAnalyticsCalculator.calculateCompletionPercentage(
          statusCounts: {
            CompletionStatus.jamaah: 5,
            CompletionStatus.onTime: 3,
          },
          expectedPrayers: 0,
        );

        expect(result, 0.0);
      });

      test('returns 0 when expectedPrayers is negative', () {
        final result = PrayerAnalyticsCalculator.calculateCompletionPercentage(
          statusCounts: {
            CompletionStatus.jamaah: 5,
          },
          expectedPrayers: -5,
        );

        expect(result, 0.0);
      });

      test('returns 0 when no prayers completed', () {
        final result = PrayerAnalyticsCalculator.calculateCompletionPercentage(
          statusCounts: {},
          expectedPrayers: 35,
        );

        expect(result, 0.0);
      });

      test('returns 1.0 when all prayers are jamaah', () {
        final result = PrayerAnalyticsCalculator.calculateCompletionPercentage(
          statusCounts: {
            CompletionStatus.jamaah: 35,
          },
          expectedPrayers: 35,
        );

        expect(result, 1.0);
      });

      test('returns correct percentage for mixed jamaah and onTime', () {
        final result = PrayerAnalyticsCalculator.calculateCompletionPercentage(
          statusCounts: {
            CompletionStatus.jamaah: 15,
            CompletionStatus.onTime: 10,
          },
          expectedPrayers: 50,
        );

        expect(result, 0.5); // 25/50 = 0.5
      });

      test('does not count missed or late as completed', () {
        final result = PrayerAnalyticsCalculator.calculateCompletionPercentage(
          statusCounts: {
            CompletionStatus.jamaah: 10,
            CompletionStatus.onTime: 5,
            CompletionStatus.late: 10,
            CompletionStatus.missed: 10,
          },
          expectedPrayers: 35,
        );

        // Only jamaah (10) + onTime (5) = 15 out of 35
        expect(result, closeTo(0.4286, 0.001));
      });

      test('clamps result to 1.0 when count exceeds expected', () {
        final result = PrayerAnalyticsCalculator.calculateCompletionPercentage(
          statusCounts: {
            CompletionStatus.jamaah: 50,
          },
          expectedPrayers: 35,
        );

        expect(result, 1.0);
      });
    });

    group('calculateStatusPercentage', () {
      test('returns 0 when expectedPrayers is 0', () {
        final result = PrayerAnalyticsCalculator.calculateStatusPercentage(
          count: 10,
          expectedPrayers: 0,
        );

        expect(result, 0.0);
      });

      test('returns 0 when count is 0', () {
        final result = PrayerAnalyticsCalculator.calculateStatusPercentage(
          count: 0,
          expectedPrayers: 35,
        );

        expect(result, 0.0);
      });

      test('returns correct percentage', () {
        final result = PrayerAnalyticsCalculator.calculateStatusPercentage(
          count: 7,
          expectedPrayers: 35,
        );

        expect(result, 0.2);
      });

      test('clamps to 1.0 when count exceeds expected', () {
        final result = PrayerAnalyticsCalculator.calculateStatusPercentage(
          count: 50,
          expectedPrayers: 35,
        );

        expect(result, 1.0);
      });
    });

    group('calculateExpectedPrayers', () {
      test('returns 0 when firstRecordedDate is null', () {
        final result = PrayerAnalyticsCalculator.calculateExpectedPrayers(
          period: PrayerAnalyticsPeriod.weekly,
          firstRecordedDate: null,
          now: DateTime(2026, 1, 29),
        );

        expect(result, 0);
      });

      test('returns 5 for 1 day (first day of recording)', () {
        final now = DateTime(2026, 1, 29);
        final result = PrayerAnalyticsCalculator.calculateExpectedPrayers(
          period: PrayerAnalyticsPeriod.weekly,
          firstRecordedDate: now,
          now: now,
        );

        expect(result, 5); // 1 day * 5 prayers
      });

      test('clamps to days since first recorded if less than period', () {
        final now = DateTime(2026, 1, 29);
        final firstRecorded = DateTime(2026, 1, 27); // 3 days ago
        final result = PrayerAnalyticsCalculator.calculateExpectedPrayers(
          period: PrayerAnalyticsPeriod.weekly, // 7 days
          firstRecordedDate: firstRecorded,
          now: now,
        );

        expect(result, 15); // 3 days * 5 prayers (not 7 * 5 = 35)
      });

      test('returns period * 5 when more days have passed than period', () {
        final now = DateTime(2026, 1, 29);
        final firstRecorded = DateTime(2026); // 29 days ago
        final result = PrayerAnalyticsCalculator.calculateExpectedPrayers(
          period: PrayerAnalyticsPeriod.weekly, // 7 days
          firstRecordedDate: firstRecorded,
          now: now,
        );

        expect(result, 35); // 7 days * 5 prayers
      });

      test('handles daily period correctly', () {
        final now = DateTime(2026, 1, 29);
        final firstRecorded = DateTime(2026, 1, 25);
        final result = PrayerAnalyticsCalculator.calculateExpectedPrayers(
          period: PrayerAnalyticsPeriod.daily, // 1 day
          firstRecordedDate: firstRecorded,
          now: now,
        );

        expect(result, 5); // 1 day * 5 prayers
      });

      test('handles monthly period correctly', () {
        final now = DateTime(2026, 1, 29);
        final firstRecorded = DateTime(2025, 12); // ~60 days ago
        final result = PrayerAnalyticsCalculator.calculateExpectedPrayers(
          period: PrayerAnalyticsPeriod.monthly, // 30 days
          firstRecordedDate: firstRecorded,
          now: now,
        );

        expect(result, 150); // 30 days * 5 prayers
      });
    });

    group('computeStreaks', () {
      test('returns (0, 0) for empty list', () {
        final result = PrayerAnalyticsCalculator.computeStreaks(
          fullyCompletedDays: [],
          today: DateTime(2026, 1, 29),
        );

        expect(result.current, 0);
        expect(result.best, 0);
      });

      test('returns (1, 1) for single day (today)', () {
        final today = DateTime(2026, 1, 29);
        final result = PrayerAnalyticsCalculator.computeStreaks(
          fullyCompletedDays: [today],
          today: today,
        );

        expect(result.current, 1);
        expect(result.best, 1);
      });

      test('returns (1, 1) for single day (yesterday)', () {
        final today = DateTime(2026, 1, 29);
        final yesterday = DateTime(2026, 1, 28);
        final result = PrayerAnalyticsCalculator.computeStreaks(
          fullyCompletedDays: [yesterday],
          today: today,
        );

        expect(result.current, 1);
        expect(result.best, 1);
      });

      test('current streak is 0 when last day was 2+ days ago', () {
        final today = DateTime(2026, 1, 29);
        final result = PrayerAnalyticsCalculator.computeStreaks(
          fullyCompletedDays: [
            DateTime(2026, 1, 25),
            DateTime(2026, 1, 26),
            DateTime(2026, 1, 27), // 2 days ago - streak broken
          ],
          today: today,
        );

        expect(result.current, 0, reason: 'Streak should be broken');
        expect(result.best, 3);
      });

      test('correctly identifies consecutive days', () {
        final today = DateTime(2026, 1, 29);
        final result = PrayerAnalyticsCalculator.computeStreaks(
          fullyCompletedDays: [
            DateTime(2026, 1, 25),
            DateTime(2026, 1, 26),
            DateTime(2026, 1, 27),
            DateTime(2026, 1, 28),
            DateTime(2026, 1, 29), // today
          ],
          today: today,
        );

        expect(result.current, 5);
        expect(result.best, 5);
      });

      test('finds best streak across multiple gaps', () {
        final today = DateTime(2026, 1, 29);
        final result = PrayerAnalyticsCalculator.computeStreaks(
          fullyCompletedDays: [
            // First streak: 3 days
            DateTime(2026, 1, 10),
            DateTime(2026, 1, 11),
            DateTime(2026, 1, 12),
            // Gap
            // Second streak: 5 days (BEST)
            DateTime(2026, 1, 15),
            DateTime(2026, 1, 16),
            DateTime(2026, 1, 17),
            DateTime(2026, 1, 18),
            DateTime(2026, 1, 19),
            // Gap
            // Third streak: 2 days (current)
            DateTime(2026, 1, 28),
            DateTime(2026, 1, 29),
          ],
          today: today,
        );

        expect(result.current, 2, reason: 'Current streak is 2 days');
        expect(result.best, 5, reason: 'Best streak is 5 days in the middle');
      });

      test('handles single day gaps correctly', () {
        final today = DateTime(2026, 1, 29);
        final result = PrayerAnalyticsCalculator.computeStreaks(
          fullyCompletedDays: [
            DateTime(2026, 1, 25),
            DateTime(2026, 1, 26),
            // Gap on 27
            DateTime(2026, 1, 28),
            DateTime(2026, 1, 29),
          ],
          today: today,
        );

        expect(result.current, 2);
        expect(result.best, 2);
      });

      test('alternating days do not form a streak', () {
        final today = DateTime(2026, 1, 29);
        final result = PrayerAnalyticsCalculator.computeStreaks(
          fullyCompletedDays: [
            DateTime(2026, 1, 23), // Day 1
            // Gap
            DateTime(2026, 1, 25), // Day 3
            // Gap
            DateTime(2026, 1, 27), // Day 5
            // Gap
            DateTime(2026, 1, 29), // Day 7 (today)
          ],
          today: today,
        );

        expect(result.current, 1);
        expect(result.best, 1);
      });
    });

    group('calculateAnalytics', () {
      test('returns correct analytics object', () {
        final result = PrayerAnalyticsCalculator.calculateAnalytics(
          period: PrayerAnalyticsPeriod.weekly,
          statusCounts: {
            CompletionStatus.jamaah: 20,
            CompletionStatus.onTime: 10,
            CompletionStatus.late: 3,
            CompletionStatus.missed: 2,
          },
          expectedPrayers: 35,
          currentStreak: 5,
          bestStreak: 10,
        );

        expect(result.period, PrayerAnalyticsPeriod.weekly);
        expect(result.currentStreak, 5);
        expect(result.bestStreak, 10);
        expect(result.completionPercentage, closeTo(0.9, 0.001)); // 30/35
        expect(result.jamaahPercentage, closeTo(0.6, 0.001)); // 20/35
        expect(result.onTimePercentage, closeTo(0.3, 0.001)); // 10/35
        expect(result.latePercentage, closeTo(0.1, 0.001)); // 3/35
        expect(result.missedPercentage, closeTo(0.1, 0.001)); // 2/35
      });

      test('handles empty status counts', () {
        final result = PrayerAnalyticsCalculator.calculateAnalytics(
          period: PrayerAnalyticsPeriod.daily,
          statusCounts: {},
          expectedPrayers: 5,
          currentStreak: 0,
          bestStreak: 0,
        );

        expect(result.completionPercentage, 0.0);
        expect(result.jamaahPercentage, 0.0);
        expect(result.onTimePercentage, 0.0);
        expect(result.latePercentage, 0.0);
        expect(result.missedPercentage, 0.0);
      });

      test('handles zero expected prayers', () {
        final result = PrayerAnalyticsCalculator.calculateAnalytics(
          period: PrayerAnalyticsPeriod.weekly,
          statusCounts: {
            CompletionStatus.jamaah: 10,
          },
          expectedPrayers: 0,
          currentStreak: 0,
          bestStreak: 0,
        );

        expect(result.completionPercentage, 0.0);
        expect(result.jamaahPercentage, 0.0);
      });
    });
  });
}
