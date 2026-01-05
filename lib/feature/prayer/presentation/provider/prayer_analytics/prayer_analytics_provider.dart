import 'package:hasanat/core/logging/logger_provider.dart';
import 'package:hasanat/feature/prayer/data/models/prayer_completion.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_analytics.dart';
import 'package:hasanat/feature/prayer/domain/services/prayer_service.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
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

      final streaks = await service.computeStreaks(
        settings.when(
          data: (data) => data.location,
          loading: () => local,
          error: (error, stackTrace) => local,
        ),
      );

      final countsMap = await service.countAllStatusesOnPeriod(period);

      final allPrayers = countsMap.values.fold<int>(0, (prev, e) => prev + e);

      double pct(int count) => allPrayers == 0 ? 0 : count / allPrayers;

      final jamaahPrayers = countsMap[CompletionStatus.jamaah] ?? 0;
      final onTimePrayers = countsMap[CompletionStatus.onTime] ?? 0;
      final latePrayers = countsMap[CompletionStatus.late] ?? 0;
      final missedPrayers = countsMap[CompletionStatus.missed] ?? 0;

      final completionPercentage = pct(jamaahPrayers + onTimePrayers);

      return PrayerAnalytics(
        period: period,
        completionPercentage: double.parse(
          completionPercentage.toStringAsFixed(1),
        ),
        jamaahPercentage: double.parse(pct(jamaahPrayers).toStringAsFixed(1)),
        onTimePercentage: double.parse(pct(onTimePrayers).toStringAsFixed(1)),
        latePercentage: double.parse(pct(latePrayers).toStringAsFixed(1)),
        missedPercentage: double.parse(pct(missedPrayers).toStringAsFixed(1)),
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
