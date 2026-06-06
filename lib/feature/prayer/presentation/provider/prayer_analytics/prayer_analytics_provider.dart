import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/logging/logger_provider.dart';
import 'package:tawaq/core/utils/date_extensions.dart';
import 'package:tawaq/feature/prayer/data/models/prayer_completion.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_analysis_section.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_analytics.dart';
import 'package:tawaq/feature/prayer/domain/prayer_extensions.dart';
import 'package:tawaq/feature/prayer/domain/services/prayer_analytics_calculator.dart';
import 'package:tawaq/feature/prayer/domain/services/prayer_service.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_completion_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_data_providers.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:timezone/timezone.dart';

part 'prayer_analytics_provider.g.dart';

typedef _TrendCacheKey = (PrayerAnalyticsPeriod, int rangeEndDayKey);

/// Async notifier for the prayer analysis section (today's gauge + trend
/// chart).
///
/// Rebuilds when completions or the selected analytics period change. Period
/// selection is persisted via [prayerAnalyticsSettingsProvider].
@riverpod
class PrayerAnalysisSectionNotifier extends _$PrayerAnalysisSectionNotifier {
  _TrendCacheKey? _cachedTrendKey;
  List<PrayerTrendBucket>? _cachedTrendBuckets;

  @override
  FutureOr<PrayerAnalysisSectionData> build() async {
    final settings = ref.watch(prayerAnalyticsSettingsProvider);
    final period = settings.value?.period ?? PrayerAnalyticsPeriod.weekly;
    try {
      return await _computeSection(period);
    } catch (e, stackTrace) {
      ref
          .read(loggerProvider)
          .e(
            '[PrayerAnalysisSectionNotifier] Error computing analysis section',
            error: e,
            stackTrace: stackTrace,
          );
      rethrow;
    }
  }

  /// Changes the analytics period and recomputes the section data.
  void changePeriod(PrayerAnalyticsPeriod period) {
    ref.read(prayerAnalyticsSettingsProvider.notifier).setPeriod(period);
  }

  Future<PrayerAnalysisSectionData> _computeSection(
    PrayerAnalyticsPeriod period,
  ) async {
    if (!ref.mounted) {
      return PrayerAnalysisSectionData.empty(period);
    }

    final calendarDayKey = ref.watch(prayerCalendarDayKeyProvider);
    final completionsAsync = ref.watch(prayerCompletionProvider);
    final log = ref.read(loggerProvider);
    try {
      final service = ref.read(prayerServiceProvider);
      final settings = ref.read(prayerSettingsProvider);

      final location = settings.when(
        data: (data) => data.location,
        loading: () => local,
        error: (_, _) => local,
      );

      final now = TZDateTime.now(location);
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart
          .add(const Duration(days: 1))
          .subtract(const Duration(milliseconds: 1));

      final todayCompletions =
          completionsAsync.value ??
          await service.getPrayerCompletionForDate(now);
      final todayCounts = _countStatuses(todayCompletions);
      final performanceScore = _calculatePerformanceScore(todayCounts);

      final rangeEndDayKey = todayEnd.year * 10000 +
          todayEnd.month * 100 +
          todayEnd.day;
      final trendKey = (period, rangeEndDayKey);
      final needsFullTrendRefresh =
          _cachedTrendKey != trendKey ||
          _cachedTrendBuckets == null ||
          calendarDayKey != rangeEndDayKey;

      if (needsFullTrendRefresh) {
        _cachedTrendBuckets = await _buildTrendBuckets(
          period: period,
          service: service,
          location: location,
          rangeStart: _rangeStart(period, todayStart),
          rangeEnd: todayEnd,
        );
        _cachedTrendKey = trendKey;
      } else if (completionsAsync.hasValue) {
        final activeDate = _activeCompletionDate(
          completionsAsync.value!,
          location,
        );
        _cachedTrendBuckets = _updateBucketForDate(
          buckets: _cachedTrendBuckets!,
          date: activeDate,
          completions: completionsAsync.value!,
          location: location,
        );
      }

      return PrayerAnalysisSectionData(
        period: period,
        todayStatusCounts: todayCounts,
        todayPerformanceScore: performanceScore,
        trendBuckets: _cachedTrendBuckets ?? const [],
      );
    } catch (e, stackTrace) {
      log.e(
        '[PrayerAnalysisSectionNotifier] Error computing section data',
        error: e,
        stackTrace: stackTrace,
      );
      return PrayerAnalysisSectionData.empty(period);
    }
  }

  DateTime _activeCompletionDate(
    List<PrayerCompletion> completions,
    Location location,
  ) {
    if (completions.isEmpty) {
      final now = TZDateTime.now(location);
      return DateTime(now.year, now.month, now.day);
    }
    final local = completions.first.completionTime.toLocation(location);
    return DateTime(local.year, local.month, local.day);
  }

  List<PrayerTrendBucket> _updateBucketForDate({
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
    final counts = _countStatuses(completions);
    final updated = [...buckets];
    updated[bucketIndex] = PrayerTrendBucket(
      start: bucket.start,
      end: bucket.end,
      statusCounts: counts,
      prayer: bucket.prayer,
    );
    return updated;
  }

  Map<CompletionStatus, int> _countStatuses(
    List<PrayerCompletion> completions,
  ) {
    final counts = _emptyCounts();
    for (final completion in completions) {
      counts[completion.status] = (counts[completion.status] ?? 0) + 1;
    }
    return counts;
  }

  /// Calculates a weighted performance score from 0.0 to 1.0.
  /// Jamaah = 1.0, OnTime = 0.85, Late = 0.5, Missed = 0.
  double _calculatePerformanceScore(Map<CompletionStatus, int> counts) {
    final jamaah = counts[CompletionStatus.jamaah] ?? 0;
    final onTime = counts[CompletionStatus.onTime] ?? 0;
    final late = counts[CompletionStatus.late] ?? 0;
    const expected = PrayerAnalyticsCalculator.prayersPerDay;
    if (expected == 0) return 0;

    final totalScore = (jamaah * 1.0) + (onTime * 0.85) + (late * 0.5);
    return (totalScore / expected).clamp(0.0, 1.0);
  }

  DateTime _rangeStart(PrayerAnalyticsPeriod period, DateTime todayStart) {
    return switch (period) {
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
  }

  Future<List<PrayerTrendBucket>> _buildTrendBuckets({
    required PrayerAnalyticsPeriod period,
    required PrayerService service,
    required Location location,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) async {
    final completions = await service.getCompletionsBetween(
      rangeStart,
      rangeEnd,
    );

    final buckets = _initializeBuckets(period, rangeStart, rangeEnd);

    for (final completion in completions) {
      final localTime = completion.completionTime.toLocation(location);
      final bucketIndex = buckets.indexWhere(
        (b) => localTime.isBetween(b.start, b.end),
      );
      if (bucketIndex == -1) continue;

      final bucket = buckets[bucketIndex];
      final counts = Map<CompletionStatus, int>.from(bucket.statusCounts);
      counts[completion.status] = (counts[completion.status] ?? 0) + 1;
      buckets[bucketIndex] = PrayerTrendBucket(
        start: bucket.start,
        end: bucket.end,
        statusCounts: counts,
        prayer: bucket.prayer,
      );
    }

    return buckets;
  }

  List<PrayerTrendBucket> _initializeBuckets(
    PrayerAnalyticsPeriod period,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    final buckets = <PrayerTrendBucket>[];
    final emptyCounts = _emptyCounts();

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
              statusCounts: emptyCounts,
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
              statusCounts: emptyCounts,
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
              statusCounts: emptyCounts,
            ),
          );
        }
    }

    return buckets;
  }

  Map<CompletionStatus, int> _emptyCounts() {
    return {
      for (final status in CompletionStatus.values) status: 0,
    };
  }
}
