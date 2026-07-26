import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/logging/logger_provider.dart';
import 'package:tawaq/feature/prayer/data/database/prayer_database.dart';
import 'package:tawaq/feature/prayer/data/repository/prayer_repo.dart';
import 'package:tawaq/feature/prayer/domain/completion_dedup.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_analysis_section.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_analytics.dart';
import 'package:tawaq/feature/prayer/domain/prayer_calendar.dart';
import 'package:tawaq/feature/prayer/domain/services/prayer_analytics_calculator.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_analytics_settings_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_completions_for_date_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_day.dart';
import 'package:tawaq/feature/settings/presentation/provider/first_prayer_recorded_provider.dart';
import 'package:timezone/timezone.dart';

part 'prayer_analytics_provider.g.dart';

typedef _TrendCacheKey = (PrayerAnalyticsPeriod, int rangeEndDayKey);

/// Async notifier for the prayer analysis section (today's gauge + trend
/// chart).
@Riverpod(keepAlive: true)
class PrayerAnalysisSectionNotifier extends _$PrayerAnalysisSectionNotifier {
  _TrendCacheKey? _cachedTrendKey;
  List<PrayerTrendBucket>? _cachedTrendBuckets;

  @override
  FutureOr<PrayerAnalysisSectionData> build() async {
    // Watch day key so cold start (0 → valid) and midnight rebind the
    // completions listener via a fresh build (listeners dispose on rebuild).
    final dayKey = ref.watch(prayerCalendarDayKeyProvider);
    ref.listen(
      prayerAnalyticsSettingsProvider,
      (previous, next) {
        if (previous?.value?.period != next.value?.period) {
          unawaited(_refresh());
        }
      },
    );
    if (dayKey != 0) {
      ref.listen(prayerCompletionsForDateProvider(dayKey), (_, _) {
        unawaited(_refresh());
      });
    }

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
      if (ref.mounted) {
        state = AsyncError(e, stackTrace);
      }
    }
  }

  Future<PrayerAnalysisSectionData> _computeSection(
    PrayerAnalyticsPeriod period,
  ) async {
    if (!ref.mounted) {
      return PrayerAnalysisSectionData.empty(period);
    }

    final calendarDayKey = ref.read(prayerCalendarDayKeyProvider);
    final repo = ref.read(prayerRepoProvider);
    final settings = ref.read(effectivePrayerSettingsProvider);
    if (settings == null) {
      return PrayerAnalysisSectionData.empty(period);
    }

    final location = settings.location;
    final now = ref.read(prayerDayProvider).value?.now ??
        TZDateTime.now(location);
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart
        .add(const Duration(days: 1))
        .subtract(const Duration(milliseconds: 1));
    final todayDayKey = calendarDayKey != 0
        ? calendarDayKey
        : calendarDayKeyFromDate(todayStart);

    final todayCompletions = await ref.read(
      prayerCompletionsForDateProvider(todayDayKey).future,
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
    final firstRecordedDate = await _resolveFirstRecordedDate();
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
    } else if (period == PrayerAnalyticsPeriod.weekly) {
      _cachedTrendBuckets = PrayerAnalyticsCalculator.updateTrendBucketForDate(
        buckets: _cachedTrendBuckets!,
        date: todayStart,
        completions: todayCompletions,
        location: location,
      );
    } else {
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

  Future<DateTime?> _resolveFirstRecordedDate() async {
    final raw = await ref.read(firstPrayerRecordedDateProvider.future);
    final persisted =
        (raw == null || raw.isEmpty) ? null : DateTime.tryParse(raw);
    if (persisted != null) return persisted;

    final earliest =
        await ref.read(prayerDatabaseProvider).getEarliestCompletionTime();
    if (earliest == null) return null;

    final location = ref.read(effectivePrayerSettingsProvider)?.location;
    final normalized = location != null
        ? completionCalendarDay(earliest, location)
        : DateTime(earliest.year, earliest.month, earliest.day);
    ref.read(firstPrayerRecordedDateProvider.notifier).setIfNull(normalized);
    return normalized;
  }
}
