import 'package:adhan_dart/adhan_dart.dart';
import 'package:tawaq/feature/prayer/data/models/prayer_completion.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_analytics.dart';
import 'package:tawaq/feature/prayer/domain/prayer_slots.dart';
import 'package:tawaq/feature/prayer/domain/services/prayer_analytics_calculator.dart';

export 'package:tawaq/feature/prayer/domain/prayer_slots.dart' show kObligatoryPrayers;

/// Trend bucket containing aggregated prayer status counts.
class PrayerTrendBucket {
  /// Creates a trend bucket that covers a single time range.
  const PrayerTrendBucket({
    required this.start,
    required this.end,
    required this.statusCounts,
    this.prayer,
  });

  /// Start time of the bucket.
  final DateTime start;

  /// End time of the bucket.
  final DateTime end;

  /// Aggregated prayer completion counts for the bucket.
  final Map<CompletionStatus, int> statusCounts;

  /// The prayer associated with the bucket, when it represents one prayer.
  final Prayer? prayer;
}

/// Whether every obligatory prayer was logged with a positive status.
bool isFullyCompletedBucket(PrayerTrendBucket bucket) {
  final positive =
      (bucket.statusCounts[CompletionStatus.jamaah] ?? 0) +
      (bucket.statusCounts[CompletionStatus.onTime] ?? 0) +
      (bucket.statusCounts[CompletionStatus.late] ?? 0);
  return positive >= PrayerAnalyticsCalculator.prayersPerDay;
}

/// View data for the analysis section.
class PrayerAnalysisSectionData {
  /// Creates a prayer analysis snapshot for the selected period.
  const PrayerAnalysisSectionData({
    required this.period,
    required this.todayStatusCounts,
    required this.todayPrayerStatuses,
    required this.todayPerformanceScore,
    required this.periodAnalytics,
    required this.trendBuckets,
  });

  /// Creates an empty analysis snapshot for the given period.
  factory PrayerAnalysisSectionData.empty(PrayerAnalyticsPeriod period) {
    return PrayerAnalysisSectionData(
      period: period,
      todayStatusCounts: _emptyCounts(),
      todayPrayerStatuses: _emptyPrayerStatuses(),
      todayPerformanceScore: 0,
      periodAnalytics: PrayerAnalytics.empty().copyWith(period: period),
      trendBuckets: const [],
    );
  }

  /// The analytics period used to build this section.
  final PrayerAnalyticsPeriod period;

  /// Completion counts for the current day.
  final Map<CompletionStatus, int> todayStatusCounts;

  /// Per-prayer completion status for the current day.
  final Map<Prayer, CompletionStatus> todayPrayerStatuses;

  /// Performance score from 0.0 to 1.0 based on weighted prayer completions.
  /// Jamaah = 1.0, OnTime = 0.85, Late = 0.5, Missed = 0.
  final double todayPerformanceScore;

  /// Aggregated analytics for the selected period, including streaks.
  final PrayerAnalytics periodAnalytics;

  /// Historical trend buckets for the selected analytics period.
  final List<PrayerTrendBucket> trendBuckets;

  static Map<CompletionStatus, int> _emptyCounts() {
    return {
      for (final status in CompletionStatus.values) status: 0,
    };
  }

  static Map<Prayer, CompletionStatus> _emptyPrayerStatuses() {
    return {
      for (final prayer in kObligatoryPrayers) prayer: CompletionStatus.none,
    };
  }
}
