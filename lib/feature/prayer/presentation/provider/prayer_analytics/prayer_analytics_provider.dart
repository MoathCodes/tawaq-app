import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/logging/logger_provider.dart';
import 'package:tawaq/feature/prayer/data/repository/prayer_repo.dart';
import 'package:tawaq/feature/prayer/domain/completion_dedup.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_analysis_section.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_analytics.dart';
import 'package:tawaq/feature/prayer/domain/prayer_calendar.dart';
import 'package:tawaq/feature/prayer/domain/services/prayer_analytics_calculator.dart';
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
      final repo = ref.read(prayerRepoProvider);
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

      final todayCompletions = await repo.getPrayerCompletionForDate(
        now,
        location,
      );
      final todayCounts = countDedupedStatuses(todayCompletions, location);
      final todayPrayerStatuses = mapPrayerStatuses(
        todayCompletions,
        location,
        todayStart,
      );
      final performanceScore =
          PrayerAnalyticsCalculator.calculatePerformanceScore(todayCounts);

      final streaks = await repo.computeStreaks(location);
      final periodCounts = await repo.countAllStatusesOnPeriod(
        period,
        location,
        now,
      );
      final firstRecordedDate = await _resolveFirstRecordedDate(repo);
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

      final rangeEndDayKey = calendarDayKeyFromDate(todayEnd);
      final trendKey = (period, rangeEndDayKey);
      final needsFullTrendRefresh =
          _cachedTrendKey != trendKey ||
          _cachedTrendBuckets == null ||
          calendarDayKey != rangeEndDayKey;

      final rangeStart = PrayerAnalyticsCalculator.periodCalendarRange(
        period,
        todayStart,
      ).start;

      if (needsFullTrendRefresh) {
        _cachedTrendBuckets = await _loadTrendBuckets(
          repo: repo,
          period: period,
          location: location,
          rangeStart: rangeStart,
          rangeEnd: todayEnd,
        );
        _cachedTrendKey = trendKey;
      } else if (
        completionsAsync.hasValue &&
        period == PrayerAnalyticsPeriod.weekly
      ) {
        _cachedTrendBuckets = PrayerAnalyticsCalculator.updateTrendBucketForDate(
          buckets: _cachedTrendBuckets!,
          date: todayStart,
          completions: todayCompletions,
          location: location,
        );
      } else if (completionsAsync.hasValue) {
        _cachedTrendBuckets = await _loadTrendBuckets(
          repo: repo,
          period: period,
          location: location,
          rangeStart: rangeStart,
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

  Future<List<PrayerTrendBucket>> _loadTrendBuckets({
    required PrayerRepo repo,
    required PrayerAnalyticsPeriod period,
    required Location location,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) async {
    final completions = await repo.getCompletionsBetween(
      rangeStart,
      rangeEnd,
      location,
    );
    return PrayerAnalyticsCalculator.buildTrendBuckets(
      period: period,
      completions: completions,
      location: location,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );
  }

  Future<DateTime?> _resolveFirstRecordedDate(PrayerRepo repo) async {
    final persisted = ref.read(firstPrayerRecordedDateTimeProvider);
    if (persisted != null) return persisted;

    final earliest = await repo.getEarliestCompletionTime();
    if (earliest == null) return null;

    final normalized = DateTime(earliest.year, earliest.month, earliest.day);
    ref.read(firstPrayerRecordedDateProvider.notifier).setIfNull(normalized);
    return normalized;
  }
}
