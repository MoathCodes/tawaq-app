import 'package:adhan_dart/adhan_dart.dart';
import 'package:hasanat/feature/prayer/data/models/prayer_completion.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_analytics.dart';

/// Trend bucket containing aggregated prayer status counts.
class PrayerTrendBucket {
  const PrayerTrendBucket({
    required this.start,
    required this.end,
    required this.statusCounts,
    this.prayer,
  });

  final DateTime start;
  final DateTime end;
  final Map<CompletionStatus, int> statusCounts;
  final Prayer? prayer;
}

/// View data for the analysis section.
class PrayerAnalysisSectionData {
  const PrayerAnalysisSectionData({
    required this.period,
    required this.todayStatusCounts,
    required this.todayPerformanceScore,
    required this.trendBuckets,
  });

  factory PrayerAnalysisSectionData.empty(PrayerAnalyticsPeriod period) {
    return PrayerAnalysisSectionData(
      period: period,
      todayStatusCounts: _emptyCounts(),
      todayPerformanceScore: 0,
      trendBuckets: const [],
    );
  }

  final PrayerAnalyticsPeriod period;
  final Map<CompletionStatus, int> todayStatusCounts;

  /// Performance score from 0.0 to 1.0 based on weighted prayer completions.
  /// Jamaah = 1.0, OnTime = 0.85, Late = 0.5, Missed = 0.
  final double todayPerformanceScore;
  final List<PrayerTrendBucket> trendBuckets;

  static Map<CompletionStatus, int> _emptyCounts() {
    return {
      for (final status in CompletionStatus.values) status: 0,
    };
  }
}
