import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/logging/logger_provider.dart';
import 'package:tawaq/core/utils/date_extensions.dart';
import 'package:tawaq/feature/prayer/data/models/prayer_completion.dart';
import 'package:tawaq/feature/prayer/domain/completion_dedup.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_analysis_section.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_analytics.dart';
import 'package:tawaq/feature/prayer/domain/prayer_extensions.dart';
import 'package:tawaq/feature/prayer/domain/services/prayer_analytics_calculator.dart';
import 'package:tawaq/feature/prayer/domain/services/prayer_service.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_completion_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_data_providers.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_service_provider.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:timezone/timezone.dart';

part 'prayer_analytics_provider.g.dart';

typedef _TrendCacheKey = (PrayerAnalyticsPeriod, int rangeEndDayKey);

/// Async notifier for the prayer analysis section (today's gauge + trend
/// chart).
///
/// Rebuilds when completions or the selected analytics period change. Period
/// selection is persisted via [prayerAnalyticsSettingsProvider].
@Riverpod(keepAlive: true)
class PrayerAnalysisSectionNotifier extends _$PrayerAnalysisSectionNotifier {
  _TrendCacheKey? _cachedTrendKey;
  List<PrayerTrendBucket>? _cachedTrendBuckets;

  @override
  FutureOr<PrayerAnalysisSectionData> build() async {
    ref.listen(
      prayerCompletionProvider,
      (_, _) => unawaited(_refresh()),
    );
    ref.listen(
      prayerCalendarDayKeyProvider,
      (_, _) => unawaited(_refresh()),
    );
    ref.listen(
      prayerAnalyticsSettingsProvider,
      (previous, next) {
        if (previous?.value?.period != next.value?.period) {
          unawaited(_refresh());
        }
      },
    );

    final period = _selectedPeriod;
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

  PrayerAnalyticsPeriod get _selectedPeriod =>
      ref.read(prayerAnalyticsSettingsProvider).value?.period ??
      PrayerAnalyticsPeriod.weekly;

  /// Recomputes section data in place without returning to [AsyncLoading].
  Future<void> _refresh() async {
    if (!ref.mounted) return;

    final period = _selectedPeriod;
    try {
      final data = await _computeSection(period);
      if (ref.mounted) {
        state = AsyncData(data);
      }
    } catch (e, stackTrace) {
      ref
          .read(loggerProvider)
          .e(
            '[PrayerAnalysisSectionNotifier] Error refreshing analysis section',
            error: e,
            stackTrace: stackTrace,
          );
    }
  }

  Future<PrayerAnalysisSectionData> _computeSection(
    PrayerAnalyticsPeriod period,
  ) async {
    if (!ref.mounted) {
      return PrayerAnalysisSectionData.empty(period);
    }

    final calendarDayKey = ref.read(prayerCalendarDayKeyProvider);
    final completionsAsync = ref.read(prayerCompletionProvider);
    final log = ref.read(loggerProvider);
    try {
      final service = ref.read(prayerServiceProvider);
      final settings = ref.read(effectivePrayerSettingsProvider);
      if (settings == null) {
        return PrayerAnalysisSectionData.empty(period);
      }

      final location = settings.location;
      final now = ref.read(currentLocationTimeProvider) ?? TZDateTime.now(location);
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart
          .add(const Duration(days: 1))
          .subtract(const Duration(milliseconds: 1));

      // Always load real today — not the schedule's browsed day.
      final todayCompletions = await service.getPrayerCompletionForDate(
        now,
        location,
      );
      final todayCounts = countDedupedStatuses(todayCompletions, location);
      final todayPrayerStatuses = mapPrayerStatuses(
        todayCompletions,
        location,
        todayStart,
      );
      final performanceScore = _calculatePerformanceScore(todayCounts);

      final streaks = await service.computeStreaks(location);
      final periodCounts = await service.countAllStatusesOnPeriod(
        period,
        location,
        now,
      );
      final firstRecordedDate = await _resolveFirstRecordedDate(service);
      final expectedPrayers =
          PrayerAnalyticsCalculator.calculateExpectedPrayers(
        period: period,
        firstRecordedDate: firstRecordedDate,
        now: now,
      );
      final periodAnalytics = PrayerAnalyticsCalculator.calculateAnalytics(
        period: period,
        statusCounts: periodCounts,
        expectedPrayers: expectedPrayers,
        currentStreak: streaks.current,
        bestStreak: streaks.best,
      );

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
      } else if (
        completionsAsync.hasValue &&
        period == PrayerAnalyticsPeriod.weekly
      ) {
        _cachedTrendBuckets = _updateBucketForDate(
          buckets: _cachedTrendBuckets!,
          date: todayStart,
          completions: todayCompletions,
          location: location,
        );
      } else if (completionsAsync.hasValue) {
        // Monthly/yearly buckets span multiple days — re-aggregate fully.
        _cachedTrendBuckets = await _buildTrendBuckets(
          period: period,
          service: service,
          location: location,
          rangeStart: _rangeStart(period, todayStart),
          rangeEnd: todayEnd,
        );
      }

      return PrayerAnalysisSectionData(
        period: period,
        todayStatusCounts: todayCounts,
        todayPrayerStatuses: todayPrayerStatuses,
        todayPerformanceScore: performanceScore,
        periodAnalytics: periodAnalytics,
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
    final dayCompletions = completions
        .where(
          (c) => c.completionTime.isSameCalendarDay(date, location),
        )
        .toList();
    final counts = countDedupedStatuses(dayCompletions, location);
    final updated = [...buckets];
    updated[bucketIndex] = PrayerTrendBucket(
      start: bucket.start,
      end: bucket.end,
      statusCounts: counts,
      prayer: bucket.prayer,
    );
    return updated;
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
    return PrayerAnalyticsCalculator.periodCalendarRange(
      period,
      todayStart,
    ).start;
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
      final counts = countDedupedStatuses(bucketCompletions, location);
      buckets[i] = PrayerTrendBucket(
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
              statusCounts: _emptyCounts(),
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
              statusCounts: _emptyCounts(),
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
              statusCounts: _emptyCounts(),
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

  /// Uses persisted first-recorded date, or backfills from the earliest
  /// completion for users who logged prayers before that setting existed.
  Future<DateTime?> _resolveFirstRecordedDate(PrayerService service) async {
    final persisted = ref.read(firstPrayerRecordedDateTimeProvider);
    if (persisted != null) return persisted;

    final earliest = await service.getEarliestCompletionTime();
    if (earliest == null) return null;

    final normalized = DateTime(earliest.year, earliest.month, earliest.day);
    ref.read(firstPrayerRecordedDateProvider.notifier).setIfNull(normalized);
    return normalized;
  }
}
