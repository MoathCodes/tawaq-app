import 'dart:math' as math;

import 'package:tawaq/core/utils/date_extensions.dart';
import 'package:tawaq/core/utils/prayer_extensions.dart';
import 'package:tawaq/feature/prayer/domain/completion_dedup.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_analysis_section.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_analytics.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_completion.dart';
import 'package:timezone/timezone.dart';

/// Pure functions for prayer analytics and trend aggregation.
class PrayerAnalyticsCalculator {
  const PrayerAnalyticsCalculator._();

  /// Number of obligatory prayers per day.
  static const int prayersPerDay = 5;

  /// Inclusive calendar-day bounds for a period (matches trend chart buckets).
  static ({DateTime start, DateTime end}) periodCalendarRange(
    PrayerAnalyticsPeriod period,
    DateTime anchor,
  ) {
    final todayStart = DateTime(anchor.year, anchor.month, anchor.day);
    final todayEnd = todayStart
        .add(const Duration(days: 1))
        .subtract(const Duration(milliseconds: 1));

    final start = switch (period) {
      PrayerAnalyticsPeriod.weekly => todayStart.subtract(
        const Duration(days: 6),
      ),
      PrayerAnalyticsPeriod.monthly => todayStart.subtract(
        const Duration(days: 29),
      ),
      PrayerAnalyticsPeriod.yearly => DateTime(
        todayStart.year,
        todayStart.month - 11,
      ),
    };

    return (start: start, end: todayEnd);
  }

  /// Number of inclusive calendar days in [periodCalendarRange].
  static int calendarDaysInPeriod(
    PrayerAnalyticsPeriod period,
    DateTime anchor,
  ) {
    final range = periodCalendarRange(period, anchor);
    final startDay = DateTime(
      range.start.year,
      range.start.month,
      range.start.day,
    );
    final endDay = DateTime(range.end.year, range.end.month, range.end.day);
    return endDay.difference(startDay).inDays + 1;
  }

  /// Weighted performance score from 0.0 to 1.0 for today's counts.
  ///
  /// Jamaah = 1.0, OnTime = 0.85, Late = 0.5, Missed = 0.
  static double calculatePerformanceScore(Map<CompletionStatus, int> counts) {
    final jamaah = counts[CompletionStatus.jamaah] ?? 0;
    final onTime = counts[CompletionStatus.onTime] ?? 0;
    final late = counts[CompletionStatus.late] ?? 0;
    if (prayersPerDay == 0) return 0;

    final totalScore = (jamaah * 1.0) + (onTime * 0.85) + (late * 0.5);
    return (totalScore / prayersPerDay).clamp(0.0, 1.0);
  }

  /// Empty status counts for trend buckets.
  static Map<CompletionStatus, int> emptyStatusCounts() {
    return {
      for (final status in CompletionStatus.values) status: 0,
    };
  }

  /// Initializes empty trend buckets for [period] over [rangeStart, rangeEnd].
  static List<PrayerTrendBucket> initializeTrendBuckets({
    required PrayerAnalyticsPeriod period,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    final buckets = <PrayerTrendBucket>[];

    switch (period) {
      case PrayerAnalyticsPeriod.weekly:
        for (var i = 0; i < 7; i++) {
          final dayStart = rangeStart.add(Duration(days: i));
          final dayEnd = dayStart
              .add(const Duration(days: 1))
              .subtract(const Duration(milliseconds: 1));
          buckets.add(
            PrayerTrendBucket(
              start: dayStart,
              end: dayEnd,
              statusCounts: emptyStatusCounts(),
            ),
          );
        }
      case PrayerAnalyticsPeriod.monthly:
        var cursor = rangeStart;
        while (cursor.isBefore(rangeEnd) || cursor.isSameDate(rangeEnd)) {
          final bucketEnd =
              cursor.add(const Duration(days: 6)).isBefore(rangeEnd)
              ? cursor
                    .add(const Duration(days: 6))
                    .add(const Duration(days: 1))
                    .subtract(const Duration(milliseconds: 1))
              : rangeEnd;
          buckets.add(
            PrayerTrendBucket(
              start: cursor,
              end: bucketEnd,
              statusCounts: emptyStatusCounts(),
            ),
          );
          cursor = bucketEnd.add(const Duration(milliseconds: 1));
        }
      case PrayerAnalyticsPeriod.yearly:
        for (var i = 11; i >= 0; i--) {
          final monthStart = DateTime(
            rangeEnd.year,
            rangeEnd.month - i,
          );
          final monthEnd = DateTime(
            monthStart.year,
            monthStart.month + 1,
          ).subtract(const Duration(milliseconds: 1));
          buckets.add(
            PrayerTrendBucket(
              start: monthStart,
              end: monthEnd,
              statusCounts: emptyStatusCounts(),
            ),
          );
        }
    }

    return buckets;
  }

  /// Fills trend buckets from deduped [completions] in [location].
  static List<PrayerTrendBucket> buildTrendBuckets({
    required PrayerAnalyticsPeriod period,
    required List<PrayerCompletion> completions,
    required Location location,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    final buckets = initializeTrendBuckets(
      period: period,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );

    for (var i = 0; i < buckets.length; i++) {
      final bucket = buckets[i];
      final bucketCompletions = completions
          .where(
            (c) => completionCalendarDay(
              c.completionTime,
              location,
            ).isBetween(bucket.start, bucket.end),
          )
          .toList();
      buckets[i] = PrayerTrendBucket(
        start: bucket.start,
        end: bucket.end,
        statusCounts: countDedupedStatuses(bucketCompletions, location),
        prayer: bucket.prayer,
      );
    }

    return buckets;
  }

  /// Updates a single weekly bucket after a completion change on [date].
  static List<PrayerTrendBucket> updateTrendBucketForDate({
    required List<PrayerTrendBucket> buckets,
    required DateTime date,
    required List<PrayerCompletion> completions,
    required Location location,
  }) {
    final bucketIndex = buckets.indexWhere(
      (bucket) => date.isBetween(bucket.start, bucket.end),
    );
    if (bucketIndex == -1) return buckets;

    final bucket = buckets[bucketIndex];
    final dayCompletions = completions
        .where(
          (c) => c.completionTime.isSameCalendarDay(date, location),
        )
        .toList();
    final updated = [...buckets];
    updated[bucketIndex] = PrayerTrendBucket(
      start: bucket.start,
      end: bucket.end,
      statusCounts: countDedupedStatuses(dayCompletions, location),
      prayer: bucket.prayer,
    );
    return updated;
  }

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

    final firstDay = DateTime(
      firstRecordedDate.year,
      firstRecordedDate.month,
      firstRecordedDate.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    final daysSinceFirst = today.difference(firstDay).inDays + 1;
    final periodDays = calendarDaysInPeriod(period, now);

    final effectiveDays = math.min(periodDays, daysSinceFirst);

    return effectiveDays * prayersPerDay;
  }

  /// Computes current and best prayer streaks from fully completed days.
  ///
  /// A day is considered "fully completed" if all 5 obligatory prayers
  /// were performed with a positive status (jamaah, onTime, or late).
  ///
  /// The [fullyCompletedDays] list must be sorted in ascending order.
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
        currentStreak = 1;
      } else if (_isSameDate(day, previousDay.add(const Duration(days: 1)))) {
        currentStreak++;
      } else {
        if (currentStreak > bestStreak) {
          bestStreak = currentStreak;
        }
        currentStreak = 1;
      }
      previousDay = day;
    }

    if (currentStreak > bestStreak) {
      bestStreak = currentStreak;
    }

    var activeStreak = 0;
    if (previousDay != null) {
      final todayNormalized = DateTime(today.year, today.month, today.day);
      final lastDayNormalized = DateTime(
        previousDay.year,
        previousDay.month,
        previousDay.day,
      );
      final daysDiff = todayNormalized.difference(lastDayNormalized).inDays;

      if (daysDiff >= 0 && daysDiff <= 1) {
        activeStreak = currentStreak;
      }
    }

    return (current: activeStreak, best: bestStreak);
  }

  /// Calculates all analytics metrics at once.
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

  static double _formatPercentage(double value) {
    return double.parse(value.toStringAsFixed(1));
  }

  static bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
