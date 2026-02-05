import 'dart:math' as math;

import 'package:hasanat/feature/prayer/data/models/prayer_completion.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_analytics.dart';

/// A utility class containing pure functions for calculating prayer analytics.
///
/// All methods are static and pure (no side effects), making them easy to test.
/// This class extracts calculation logic from the provider layer for better
/// testability and separation of concerns.
class PrayerAnalyticsCalculator {
  const PrayerAnalyticsCalculator._();

  /// Number of obligatory prayers per day.
  static const int prayersPerDay = 5;

  /// Calculates the completion percentage for a period.
  ///
  /// Only counts [CompletionStatus.jamaah] and [CompletionStatus.onTime]
  /// as "completed" prayers.
  ///
  /// Returns a value between 0.0 and 1.0.
  static double calculateCompletionPercentage({
    required Map<CompletionStatus, int> statusCounts,
    required int expectedPrayers,
  }) {
    if (expectedPrayers <= 0) return 0;

    final jamaahCount = statusCounts[CompletionStatus.jamaah] ?? 0;
    final onTimeCount = statusCounts[CompletionStatus.onTime] ?? 0;
    final completedCount = jamaahCount + onTimeCount;

    return (completedCount / expectedPrayers).clamp(0.0, 1.0);
  }

  /// Calculates the percentage for a specific completion status.
  ///
  /// Returns a value between 0.0 and 1.0.
  static double calculateStatusPercentage({
    required int count,
    required int expectedPrayers,
  }) {
    if (expectedPrayers <= 0) return 0;
    return (count / expectedPrayers).clamp(0.0, 1.0);
  }

  /// Calculates the expected number of prayers for a given period.
  ///
  /// Clamps to the number of days since the first recorded prayer if that
  /// is less than the period duration. This prevents inflated expected counts
  /// for new users.
  ///
  /// Returns 0 if [firstRecordedDate] is null (no prayers recorded yet).
  static int calculateExpectedPrayers({
    required PrayerAnalyticsPeriod period,
    required DateTime? firstRecordedDate,
    required DateTime now,
  }) {
    if (firstRecordedDate == null) return 0;

    final daysSinceFirst = now.difference(firstRecordedDate).inDays + 1;
    final periodDays = period.duration.inDays;

    // Clamp to the minimum of period days or days since first recorded
    final effectiveDays = math.min(periodDays, daysSinceFirst);

    return effectiveDays * prayersPerDay;
  }

  /// Computes current and best prayer streaks from fully completed days.
  ///
  /// A day is considered "fully completed" if all 5 obligatory prayers
  /// were performed with a positive status (jamaah, onTime, or late).
  ///
  /// The [fullyCompletedDays] list must be sorted in ascending order.
  ///
  /// - `current`: The current ongoing streak (includes today or yesterday).
  ///              Returns 0 if the streak is broken (last day was 2+ days ago).
  /// - `best`: The longest streak ever recorded.
  static ({int current, int best}) computeStreaks({
    required List<DateTime> fullyCompletedDays,
    required DateTime today,
  }) {
    if (fullyCompletedDays.isEmpty) {
      return (current: 0, best: 0);
    }

    var bestStreak = 0;
    var currentStreak = 0;
    DateTime? previousDay;

    for (final day in fullyCompletedDays) {
      if (previousDay == null) {
        // First day in the list
        currentStreak = 1;
      } else if (_isSameDate(day, previousDay.add(const Duration(days: 1)))) {
        // Consecutive day
        currentStreak++;
      } else {
        // Gap detected - save best and reset
        if (currentStreak > bestStreak) {
          bestStreak = currentStreak;
        }
        currentStreak = 1;
      }
      previousDay = day;
    }

    // Check final streak
    if (currentStreak > bestStreak) {
      bestStreak = currentStreak;
    }

    // Determine if current streak is still active
    var activeStreak = 0;
    if (previousDay != null) {
      final todayNormalized = DateTime(today.year, today.month, today.day);
      final lastDayNormalized = DateTime(
        previousDay.year,
        previousDay.month,
        previousDay.day,
      );
      final daysDiff = todayNormalized.difference(lastDayNormalized).inDays;

      // Streak is active if last completed day was today or yesterday
      if (daysDiff <= 1) {
        activeStreak = currentStreak;
      }
    }

    return (current: activeStreak, best: bestStreak);
  }

  /// Calculates all analytics metrics at once.
  ///
  /// This is a convenience method that calls all individual calculation
  /// methods and returns a complete [PrayerAnalytics] object.
  static PrayerAnalytics calculateAnalytics({
    required PrayerAnalyticsPeriod period,
    required Map<CompletionStatus, int> statusCounts,
    required int expectedPrayers,
    required int currentStreak,
    required int bestStreak,
  }) {
    final jamaahCount = statusCounts[CompletionStatus.jamaah] ?? 0;
    final onTimeCount = statusCounts[CompletionStatus.onTime] ?? 0;
    final lateCount = statusCounts[CompletionStatus.late] ?? 0;
    final missedCount = statusCounts[CompletionStatus.missed] ?? 0;

    final completionPct = calculateCompletionPercentage(
      statusCounts: statusCounts,
      expectedPrayers: expectedPrayers,
    );

    return PrayerAnalytics(
      period: period,
      completionPercentage: _formatPercentage(completionPct),
      jamaahPercentage: _formatPercentage(
        calculateStatusPercentage(
          count: jamaahCount,
          expectedPrayers: expectedPrayers,
        ),
      ),
      onTimePercentage: _formatPercentage(
        calculateStatusPercentage(
          count: onTimeCount,
          expectedPrayers: expectedPrayers,
        ),
      ),
      latePercentage: _formatPercentage(
        calculateStatusPercentage(
          count: lateCount,
          expectedPrayers: expectedPrayers,
        ),
      ),
      missedPercentage: _formatPercentage(
        calculateStatusPercentage(
          count: missedCount,
          expectedPrayers: expectedPrayers,
        ),
      ),
      currentStreak: currentStreak,
      bestStreak: bestStreak,
    );
  }

  /// Formats a percentage value to a fixed precision (1 decimal place).
  static double _formatPercentage(double value) {
    return double.parse(value.toStringAsFixed(1));
  }

  /// Checks if two dates represent the same calendar day.
  static bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
