import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/custom_cards.dart';
import 'package:tawaq/feature/prayer/data/models/prayer_completion.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_analytics.dart';
import 'package:tawaq/feature/prayer/presentation/extensions/completion_status_ui.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_analytics/prayer_analytics_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_analytics_settings_provider.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/analysis/analysis_metric_bar.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/analysis/trend_chart.dart';
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
        _PeriodCompletionSummary(
          completionPercentage: analytics.completionPercentage,
          subtitle: _periodSubtitle(l10n, period),
        ),
        const SizedBox(height: AppSpacing.lg),
        const _PeriodRateBars(),
        const SizedBox(height: AppSpacing.lg),
        const TrendChart(),
      ],
    );
  }
}

class _PeriodCompletionSummary extends StatelessWidget {
  const _PeriodCompletionSummary({
    required this.completionPercentage,
    required this.subtitle,
  });

  final double completionPercentage;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final colors = theme.colors;
    final percent = (completionPercentage * 100).round();
    final fillColor = _completionColor(completionPercentage, colors);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$percent%',
              style: theme.typography.body.xl3.copyWith(
                fontWeight: FontWeight.w800,
                color: fillColor,
                height: 1,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text(
                  subtitle,
                  style: theme.typography.body.xs.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AnalysisMetricBar(
          value: completionPercentage,
          color: fillColor,
          backgroundColor: colors.mutedForeground.withValues(alpha: 0.12),
        ),
      ],
    );
  }

  static Color _completionColor(double value, FColors colors) {
    if (value >= 0.75) {
      return CompletionStatus.jamaah.getBadgeColor(colors);
    }
    if (value >= 0.5) {
      return CompletionStatus.onTime.getBadgeColor(colors);
    }
    if (value >= 0.25) {
      return CompletionStatus.late.getBadgeColor(colors);
    }
    return CompletionStatus.missed.getBadgeColor(colors);
  }
}

class _PeriodRateBars extends ConsumerWidget {
  const _PeriodRateBars();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final analytics = ref.watch(
      prayerAnalysisSectionProvider.select(
        (state) => state.value?.periodAnalytics,
      ),
    );

    if (analytics == null) {
      return const SizedBox.shrink();
    }

    return Column(
      spacing: AppSpacing.sm,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RateBarRow(
          label: l10n.jamaahRate,
          value: analytics.jamaahPercentage,
          status: CompletionStatus.jamaah,
        ),
        _RateBarRow(
          label: l10n.onTimeRate,
          value: analytics.onTimePercentage,
          status: CompletionStatus.onTime,
        ),
        _RateBarRow(
          label: l10n.lateRate,
          value: analytics.latePercentage,
          status: CompletionStatus.late,
        ),
        _RateBarRow(
          label: l10n.missedRate,
          value: analytics.missedPercentage,
          status: CompletionStatus.missed,
        ),
      ],
    );
  }
}

class _RateBarRow extends StatelessWidget {
  const _RateBarRow({
    required this.label,
    required this.value,
    required this.status,
  });

  final String label;
  final double value;
  final CompletionStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final colors = theme.colors;
    final color = status.getBadgeColor(colors);
    final percent = (value * 100).round();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          flex: 2,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.typography.body.xs.copyWith(
              color: colors.mutedForeground,
            ),
          ),
        ),
        Expanded(
          child: AnalysisMetricBar(
            value: value,
            minHeight: 6,
            color: color,
            backgroundColor: colors.mutedForeground.withValues(alpha: 0.1),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 36,
          child: Text(
            '$percent%',
            textAlign: TextAlign.end,
            style: theme.typography.body.xs.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
