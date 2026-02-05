import 'package:hasanat/core/logging/logger_provider.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_analytics.dart';
import 'package:hasanat/feature/prayer/domain/services/prayer_analytics_calculator.dart';
import 'package:hasanat/feature/prayer/domain/services/prayer_service.dart';
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
