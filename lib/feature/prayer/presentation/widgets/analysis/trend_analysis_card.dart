import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/custom_cards.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_analytics.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_analytics/prayer_analytics_provider.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/analysis/period_completion_summary.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/analysis/period_rate_bars.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/analysis/trend_chart.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_analytics_settings_provider.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/theme.dart';

/// Card showing period trends, rates, and a stacked activity chart.
class TrendAnalysisCard extends ConsumerWidget {
  /// Creates a [TrendAnalysisCard].
  const TrendAnalysisCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FTheme.of(context);
    final l10n = context.l10n;
    final selectedPeriod = ref.watch(
      prayerAnalyticsSettingsProvider.select(
        (value) => value.value?.period ?? PrayerAnalyticsPeriod.weekly,
      ),
    );
    final dataPeriod = ref.watch(
      prayerAnalysisSectionProvider.select(
        (state) => state.value?.period ?? PrayerAnalyticsPeriod.weekly,
      ),
    );
    final enabled = ref.watch(
      prayerAnalysisSectionProvider.select(
        (state) => state.asData?.value != null || !state.isLoading,
      ),
    );

    return StaticCard(
      backgroundColor: Colors.transparent,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.playerAnalytics,
              style: theme.typography.body.lg.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FTabs(
            control: FTabControl.lifted(
              index: selectedPeriod.index,
              onChange: enabled
                  ? (index) => ref
                        .read(prayerAnalyticsSettingsProvider.notifier)
                        .setPeriod(PrayerAnalyticsPeriod.values[index])
                  : (_) {},
            ),
            children: [
              for (final period in PrayerAnalyticsPeriod.values)
                FTabEntry(
                  label: Text(period.getLocaleName(l10n)),
                  child: dataPeriod == period
                      ? const _PeriodTrendBody()
                      : const SizedBox.shrink(),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PeriodTrendBody extends ConsumerWidget {
  const _PeriodTrendBody();

  String _periodSubtitle(AppLocalizations l10n, PrayerAnalyticsPeriod period) {
    return switch (period) {
      PrayerAnalyticsPeriod.weekly => l10n.onTimePrayersLast7Days,
      PrayerAnalyticsPeriod.monthly => l10n.onTimePrayersLast30Days,
      PrayerAnalyticsPeriod.yearly => l10n.onTimePrayersLast365Days,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final period = ref.watch(
      prayerAnalyticsSettingsProvider.select(
        (value) => value.value?.period ?? PrayerAnalyticsPeriod.weekly,
      ),
    );
    final analytics = ref.watch(
      prayerAnalysisSectionProvider.select(
        (state) => state.value?.periodAnalytics,
      ),
    );

    if (analytics == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.md),
        PeriodCompletionSummary(
          completionPercentage: analytics.completionPercentage,
          subtitle: _periodSubtitle(l10n, period),
        ),
        const SizedBox(height: AppSpacing.lg),
        const PeriodRateBars(),
        const SizedBox(height: AppSpacing.lg),
        const TrendChart(),
      ],
    );
  }
}
