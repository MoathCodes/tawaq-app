import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/utils/app_clock_provider.dart';
import 'package:tawaq/feature/prayer/domain/completion_dedup.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_analysis_section.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_analytics.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_completion.dart';
import 'package:tawaq/feature/prayer/domain/prayer_calendar.dart';
import 'package:tawaq/feature/prayer/domain/services/prayer_analytics_calculator.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_analytics_settings_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_completions_for_date_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_day.dart';
import 'package:timezone/timezone.dart';

part 'prayer_analytics_provider.g.dart';

/// Async notifier for the prayer analysis section (today's gauge + trend
/// chart).
@riverpod
class PrayerAnalysisSectionNotifier extends _$PrayerAnalysisSectionNotifier {
  @override
  FutureOr<PrayerAnalysisSectionData> build() async {
    ref.watch(prayerCalendarDayKeyProvider);
    final period =
        ref.watch(prayerAnalyticsSettingsProvider).value?.period ??
        PrayerAnalyticsPeriod.weekly;
    final index = await ref.watch(prayerCompletionStoreProvider.future);
    return _computeSection(period, index);
  }

  PrayerAnalysisSectionData _computeSection(
    PrayerAnalyticsPeriod period,
    Map<int, List<PrayerCompletion>> index,
  ) {
    if (!ref.mounted) {
      return PrayerAnalysisSectionData.empty(period);
    }

    final calendarDayKey = ref.read(prayerCalendarDayKeyProvider);
    final settings = ref.read(effectivePrayerSettingsProvider);
    if (settings == null) {
      return PrayerAnalysisSectionData.empty(period);
    }

    final location = settings.location;
    final instant =
        ref.read(prayerDayProvider).value?.now ??
        ref.read(appClockProvider).value;
    if (instant == null) {
      return PrayerAnalysisSectionData.empty(period);
    }
    final now = TZDateTime.from(instant, location);
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart
        .add(const Duration(days: 1))
        .subtract(const Duration(milliseconds: 1));
    final todayDayKey = calendarDayKey != 0
        ? calendarDayKey
        : calendarDayKeyFromDate(todayStart);

    final todayCompletions = index[todayDayKey] ?? const [];
    final todayCounts = countDedupedStatuses(todayCompletions, location);
    final todayPrayerStatuses = mapPrayerStatuses(
      todayCompletions,
      location,
      todayStart,
    );
    final performanceScore =
        PrayerAnalyticsCalculator.calculatePerformanceScore(todayCounts);

    final range = PrayerAnalyticsCalculator.periodCalendarRange(period, now);
    final rangeStartKey = calendarDayKeyFromDate(range.start);
    final rangeEndKey = calendarDayKeyFromDate(range.end);
    final periodCompletions = <PrayerCompletion>[
      for (final entry in index.entries)
        if (entry.key >= rangeStartKey && entry.key <= rangeEndKey)
          ...entry.value,
    ];
    final periodCounts = countDedupedStatuses(periodCompletions, location);
    final completedDays = <DateTime>[
      for (final entry in index.entries)
        if (_isFullyCompleted(entry.key, entry.value, location))
          calendarDayFromKey(entry.key, location),
    ];
    final streaks = PrayerAnalyticsCalculator.computeStreaks(
      fullyCompletedDays: completedDays,
      today: todayStart,
    );
    final firstRecordedDate = _earliestCompletion(index, location);
    final expectedPrayers = PrayerAnalyticsCalculator.calculateExpectedPrayers(
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

    final rangeStart = PrayerAnalyticsCalculator.periodCalendarRange(
      period,
      todayStart,
    ).start;

    final trendBuckets = PrayerAnalyticsCalculator.buildTrendBuckets(
      period: period,
      completions: periodCompletions,
      location: location,
      rangeStart: rangeStart,
      rangeEnd: todayEnd,
    );

    return PrayerAnalysisSectionData(
      period: period,
      todayStatusCounts: todayCounts,
      todayPrayerStatuses: todayPrayerStatuses,
      todayPerformanceScore: performanceScore,
      periodAnalytics: periodAnalytics,
      trendBuckets: trendBuckets,
    );
  }

  bool _isFullyCompleted(
    int dayKey,
    List<PrayerCompletion> completions,
    Location location,
  ) {
    final statuses = mapPrayerStatuses(
      completions,
      location,
      calendarDayFromKey(dayKey, location),
    );
    return kObligatoryPrayers.every((prayer) {
      final status = statuses[prayer] ?? CompletionStatus.none;
      return status != CompletionStatus.none &&
          status != CompletionStatus.missed;
    });
  }

  DateTime? _earliestCompletion(
    Map<int, List<PrayerCompletion>> index,
    Location location,
  ) {
    if (index.isEmpty) return null;
    final firstKey = index.keys.reduce((a, b) => a < b ? a : b);
    return calendarDayFromKey(firstKey, location);
  }
}
