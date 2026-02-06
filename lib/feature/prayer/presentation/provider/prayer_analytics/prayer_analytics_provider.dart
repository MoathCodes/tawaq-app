import 'package:adhan_dart/adhan_dart.dart';
import 'package:hasanat/core/logging/logger_provider.dart';
import 'package:hasanat/core/utils/date_extensions.dart';
import 'package:hasanat/core/utils/prayer_extensions.dart';
import 'package:hasanat/feature/prayer/data/models/prayer_completion.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_analysis_section.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_analytics.dart';
import 'package:hasanat/feature/prayer/domain/services/prayer_analytics_calculator.dart';
import 'package:hasanat/feature/prayer/domain/services/prayer_service.dart';
import 'package:hasanat/feature/prayer/presentation/provider/prayer_completion_provider.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hasanat/feature/settings/service/settings_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:timezone/timezone.dart';

part 'prayer_analytics_provider.g.dart';

/// Notifier for prayer analytics.
@riverpod
class PrayerAnalyticsNotifier extends _$PrayerAnalyticsNotifier {
  @override
  FutureOr<PrayerAnalytics> build() async {
    const period = PrayerAnalyticsPeriod.weekly;
    try {
      return await _computeAnalytics(period);
    } catch (e, stackTrace) {
      ref
          .read(loggerProvider)
          .e(
            '[PrayerAnalyticsNotifier] Error computing analytics',
            error: e,
            stackTrace: stackTrace,
          );
      rethrow;
    }
  }

  /// Changes the analytics period and recomputes the analytics.
  Future<void> changePeriod(PrayerAnalyticsPeriod period) async {
    state = const AsyncValue.loading();
    try {
      final analytics = await _computeAnalytics(period);
      state = AsyncValue.data(analytics);
    } catch (e, stackTrace) {
      ref
          .read(loggerProvider)
          .e(
            '[PrayerAnalyticsNotifier] Error while changing period',
            error: e,
            stackTrace: stackTrace,
          );
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<PrayerAnalytics> _computeAnalytics(
    PrayerAnalyticsPeriod period,
  ) async {
    if (!ref.mounted) {
      return PrayerAnalytics.empty().copyWith(period: period);
    }
    final log = ref.read(loggerProvider);
    try {
      final service = ref.read(prayerServiceProvider);
      final settings = ref.read(prayerSettingsProvider);
      final settingsService = ref.read(settingsServiceProvider);

      // Fetch data
      final location = settings.when(
        data: (data) => data.location,
        loading: () => local,
        error: (error, stackTrace) => local,
      );

      final streaks = await service.computeStreaks(location);
      final countsMap = await service.countAllStatusesOnPeriod(period);
      final firstRecordedDate = await settingsService
          .getFirstPrayerRecordedDate();

      // Calculate expected prayers using calculator
      final expectedPrayers =
          PrayerAnalyticsCalculator.calculateExpectedPrayers(
            period: period,
            firstRecordedDate: firstRecordedDate,
            now: DateTime.now(),
          );

      // Use calculator to build analytics
      return PrayerAnalyticsCalculator.calculateAnalytics(
        period: period,
        statusCounts: countsMap,
        expectedPrayers: expectedPrayers,
        currentStreak: streaks.current,
        bestStreak: streaks.best,
      );
    } catch (e, stackTrace) {
      log.e(
        '[PrayerAnalyticsNotifier] Error computing analytics',
        error: e,
        stackTrace: stackTrace,
      );
      // Return zeroed analytics in case of error so UI still renders.
      return PrayerAnalytics(
        period: period,
        completionPercentage: 0,
        jamaahPercentage: 0,
        onTimePercentage: 0,
        latePercentage: 0,
        missedPercentage: 0,
        currentStreak: 0,
        bestStreak: 0,
      );
    }
  }
}

/// Notifier for the analysis section view data.
@riverpod
class PrayerAnalysisSectionNotifier extends _$PrayerAnalysisSectionNotifier {
  @override
  FutureOr<PrayerAnalysisSectionData> build() async {
    final settings = ref.watch(stateSettingsProvider);
    final period =
        settings.value?.prayerAnalyticsPeriod ?? PrayerAnalyticsPeriod.weekly;
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
  Future<void> changePeriod(PrayerAnalyticsPeriod period) async {
    await ref
        .read(stateSettingsProvider.notifier)
        .setPrayerAnalyticsPeriod(period);
  }

  Future<PrayerAnalysisSectionData> _computeSection(
    PrayerAnalyticsPeriod period,
  ) async {
    if (!ref.mounted) {
      return PrayerAnalysisSectionData.empty(period);
    }
    // Recompute when completions change (optimistic updates included).
    final completionsAsync = ref.watch(prayerCompletionProvider);
    final log = ref.read(loggerProvider);
    try {
      final service = ref.read(prayerServiceProvider);
      final settings = ref.read(prayerSettingsProvider);

      final location = settings.when(
        data: (data) => data.location,
        loading: () => local,
        error: (_, __) => local,
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

      final buckets = period == PrayerAnalyticsPeriod.daily
          ? _buildDailyPrayerBuckets(todayCompletions, todayStart, todayEnd)
          : await _buildTrendBuckets(
              period: period,
              service: service,
              location: location,
              rangeStart: _rangeStart(period, todayStart),
              rangeEnd: todayEnd,
            );

      return PrayerAnalysisSectionData(
        period: period,
        todayStatusCounts: todayCounts,
        todayPerformanceScore: performanceScore,
        trendBuckets: buckets,
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
      PrayerAnalyticsPeriod.daily => todayStart,
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

  List<PrayerTrendBucket> _buildDailyPrayerBuckets(
    List<PrayerCompletion> completions,
    DateTime dayStart,
    DateTime dayEnd,
  ) {
    const prayers = [
      Prayer.fajr,
      Prayer.dhuhr,
      Prayer.asr,
      Prayer.maghrib,
      Prayer.isha,
    ];

    return prayers.map((prayer) {
      final counts = _emptyCounts();
      final completion = completions.firstWhere(
        (c) => c.prayer == prayer,
        orElse: () => PrayerCompletion(
          id: null,
          prayer: prayer,
          completionTime: dayStart,
          status: CompletionStatus.none,
        ),
      );

      if (completion.status != CompletionStatus.none) {
        counts[completion.status] = 1;
      }

      return PrayerTrendBucket(
        start: dayStart,
        end: dayEnd,
        statusCounts: counts,
        prayer: prayer,
      );
    }).toList();
  }

  List<PrayerTrendBucket> _initializeBuckets(
    PrayerAnalyticsPeriod period,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    final buckets = <PrayerTrendBucket>[];
    final emptyCounts = _emptyCounts();

    switch (period) {
      case PrayerAnalyticsPeriod.daily:
        buckets.add(
          PrayerTrendBucket(
            start: rangeStart,
            end: rangeEnd,
            statusCounts: emptyCounts,
          ),
        );
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
