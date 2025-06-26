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
    state = const AsyncValue.loading();
    const period = PrayerAnalyticsPeriod.weekly;
    return await _computeAnalytics(period);
  }

  Future<void> changePeriod(PrayerAnalyticsPeriod period) async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(await _computeAnalytics(period));
  }

  Future<PrayerAnalytics> _computeAnalytics(
      PrayerAnalyticsPeriod period) async {
    final service = ref.read(prayerServiceProvider);
    final settings = ref.read(prayerSettingsNotifierProvider);

    final streaks = await service.computeStreaks(settings.when(
      data: (data) => data.location,
      loading: () => local,
      error: (error, stackTrace) => local,
    ));
    final allPrayers = await service.countAllPrayersOnPeriod(period);
    final jamaahPrayers =
        await service.countPrayerOnPeriod(CompletionStatus.jamaah, period);
    final onTimePrayers =
        await service.countPrayerOnPeriod(CompletionStatus.onTime, period);
    final latePrayers =
        await service.countPrayerOnPeriod(CompletionStatus.late, period);
    final missedPrayers =
        await service.countPrayerOnPeriod(CompletionStatus.missed, period);

    final completionPercentage = allPrayers / allPrayers;
    final jamaahPercentage = jamaahPrayers / allPrayers;
    final onTimePercentage = onTimePrayers / allPrayers;
    final latePercentage = latePrayers / allPrayers;
    final missedPercentage = missedPrayers / allPrayers;

    return PrayerAnalytics(
      period: period,
      completionPercentage:
          double.parse(completionPercentage.toStringAsFixed(1)),
      jamaahPercentage: double.parse(jamaahPercentage.toStringAsFixed(1)),
      onTimePercentage: double.parse(onTimePercentage.toStringAsFixed(1)),
      latePercentage: double.parse(latePercentage.toStringAsFixed(1)),
      missedPercentage: double.parse(missedPercentage.toStringAsFixed(1)),
      currentStreak: streaks.current,
      bestStreak: streaks.best,
    );
  }
}
