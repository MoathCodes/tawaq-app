import 'package:hasanat/core/logging/talker_provider.dart';
import 'package:hasanat/feature/prayer/data/models/prayer_completion.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_analytics.dart';
import 'package:hasanat/feature/prayer/domain/services/prayer_service.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:timezone/timezone.dart';

part 'prayer_analytics_provider.g.dart';

@riverpod
class PrayerAnalyticsNotifier extends _$PrayerAnalyticsNotifier {
  @override
  FutureOr<PrayerAnalytics> build() async {
    const period = PrayerAnalyticsPeriod.weekly;
    try {
      return await _computeAnalytics(period);
    } catch (e, stackTrace) {
      ref.read(talkerNotifierProvider).handle(
          e, stackTrace, '[PrayerAnalyticsNotifier] Error computing analytics');
      rethrow;
    }
  }

  Future<void> changePeriod(PrayerAnalyticsPeriod period) async {
    state = const AsyncValue.loading();
    try {
      final analytics = await _computeAnalytics(period);
      state = AsyncValue.data(analytics);
    } catch (e, stackTrace) {
      ref.read(talkerNotifierProvider).handle(e, stackTrace,
          '[PrayerAnalyticsNotifier] Error while changing period');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<PrayerAnalytics> _computeAnalytics(
      PrayerAnalyticsPeriod period) async {
    final talker = ref.read(talkerNotifierProvider);
    try {
      final service = ref.read(prayerServiceProvider);
      final settings = ref.read(prayerSettingsNotifierProvider);

      final streaks = await service.computeStreaks(settings.when(
        data: (data) => data.location,
        loading: () => local,
        error: (error, stackTrace) => local,
      ));

      final countsMap = await service.countAllStatusesOnPeriod(period);

      final int allPrayers =
          countsMap.values.fold<int>(0, (prev, e) => prev + e);

      double pct(int count) => allPrayers == 0 ? 0 : count / allPrayers;

      final jamaahPrayers = countsMap[CompletionStatus.jamaah] ?? 0;
      final onTimePrayers = countsMap[CompletionStatus.onTime] ?? 0;
      final latePrayers = countsMap[CompletionStatus.late] ?? 0;
      final missedPrayers = countsMap[CompletionStatus.missed] ?? 0;

      final completionPercentage = pct(jamaahPrayers + onTimePrayers);

      return PrayerAnalytics(
        period: period,
        completionPercentage:
            double.parse(completionPercentage.toStringAsFixed(1)),
        jamaahPercentage: double.parse(pct(jamaahPrayers).toStringAsFixed(1)),
        onTimePercentage: double.parse(pct(onTimePrayers).toStringAsFixed(1)),
        latePercentage: double.parse(pct(latePrayers).toStringAsFixed(1)),
        missedPercentage: double.parse(pct(missedPrayers).toStringAsFixed(1)),
        currentStreak: streaks.current,
        bestStreak: streaks.best,
      );
    } catch (e, stackTrace) {
      talker.handle(
          e, stackTrace, '[PrayerAnalyticsNotifier] Error computing analytics');
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
