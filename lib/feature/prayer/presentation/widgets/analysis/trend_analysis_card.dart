import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/custom_cards.dart';
import 'package:tawaq/feature/prayer/data/models/prayer_completion.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_analysis_section.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_analytics.dart';
import 'package:tawaq/feature/prayer/domain/services/prayer_analytics_calculator.dart';
import 'package:tawaq/feature/prayer/presentation/extensions/completion_status_ui.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_analytics/prayer_analytics_provider.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/analysis/analysis_widgets.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
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
              style: theme.typography.lg.copyWith(fontWeight: FontWeight.w700),
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
        const _TrendChart(),
      ],
    );
  }
}

class _TrendChart extends ConsumerWidget {
  const _TrendChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FTheme.of(context);
    final l10n = context.l10n;
    final period = ref.watch(
      prayerAnalyticsSettingsProvider.select(
        (value) => value.value?.period ?? PrayerAnalyticsPeriod.weekly,
      ),
    );
    final buckets = ref.watch(
      prayerAnalysisSectionProvider.select(
        (state) => state.value?.trendBuckets ?? const <PrayerTrendBucket>[],
      ),
    );

    if (buckets.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            l10n.noDataAvailable,
            style: theme.typography.sm.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final chartHeight = constraints.maxWidth < theme.breakpoints.sm
            ? 180.0
            : constraints.maxWidth < theme.breakpoints.md
            ? 200.0
            : 220.0;
        final barWidth = constraints.maxWidth < theme.breakpoints.sm
            ? 18.0
            : constraints.maxWidth < theme.breakpoints.md
            ? 22.0
            : 26.0;
        final groupsSpace = constraints.maxWidth < theme.breakpoints.sm
            ? 10.0
            : 14.0;

        final groups = _buildGroups(
          buckets,
          theme.colors,
          barWidth: barWidth,
        );
        final maxY = _resolveMaxY(period, groups);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ExcludeSemantics(
              child: SizedBox(
                height: chartHeight,
                child: BarChart(
                  BarChartData(
                    maxY: maxY,
                    minY: 0,
                    groupsSpace: groupsSpace,
                    gridData: FlGridData(
                      drawVerticalLine: false,
                      horizontalInterval: maxY / 4,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: theme.colors.border.withValues(alpha: 0.25),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        tooltipPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        tooltipMargin: 12,
                        getTooltipColor: (_) =>
                            theme.colors.background.withValues(alpha: 0.96),
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final bucket = buckets[group.x];
                          final counts = bucket.statusCounts;
                          final jamaah = counts[CompletionStatus.jamaah] ?? 0;
                          final onTime = counts[CompletionStatus.onTime] ?? 0;
                          final late = counts[CompletionStatus.late] ?? 0;
                          final missed = counts[CompletionStatus.missed] ?? 0;
                          final total = jamaah + onTime + late + missed;

                          final title = DateFormat.MMMd(
                            l10n.localeName,
                          ).format(bucket.start);

                          return BarTooltipItem(
                            '$title\n',
                            theme.typography.sm.copyWith(
                              color: theme.colors.foreground,
                              fontWeight: FontWeight.w700,
                            ),
                            children: [
                              TextSpan(
                                text: '${l10n.total}: $total\n',
                                style: theme.typography.xs.copyWith(
                                  color: theme.colors.mutedForeground,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(
                                text: '\u25cf ${l10n.jamaah}: $jamaah\n',
                                style: theme.typography.xs.copyWith(
                                  color: CompletionStatus.jamaah.getBadgeColor(
                                    theme.colors,
                                  ),
                                ),
                              ),
                              TextSpan(
                                text: '\u25cf ${l10n.onTime}: $onTime\n',
                                style: theme.typography.xs.copyWith(
                                  color: CompletionStatus.onTime.getBadgeColor(
                                    theme.colors,
                                  ),
                                ),
                              ),
                              TextSpan(
                                text: '\u25cf ${l10n.late}: $late\n',
                                style: theme.typography.xs.copyWith(
                                  color: CompletionStatus.late.getBadgeColor(
                                    theme.colors,
                                  ),
                                ),
                              ),
                              TextSpan(
                                text: '\u25cf ${l10n.missed}: $missed',
                                style: theme.typography.xs.copyWith(
                                  color: CompletionStatus.missed.getBadgeColor(
                                    theme.colors,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(),
                      rightTitles: const AxisTitles(),
                      topTitles: const AxisTitles(),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: period == PrayerAnalyticsPeriod.weekly
                              ? 42
                              : 28,
                          interval: 1,
                          getTitlesWidget: (value, meta) => _BottomTitle(
                            index: value.toInt(),
                            buckets: buckets,
                            meta: meta,
                          ),
                        ),
                      ),
                    ),
                    barGroups: groups,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const _LegendRow(),
          ],
        );
      },
    );
  }

  double _resolveMaxY(
    PrayerAnalyticsPeriod period,
    List<BarChartGroupData> groups,
  ) {
    final observedMax = groups
        .map((g) => g.barRods.first.toY)
        .fold<double>(0, math.max);

    return switch (period) {
      PrayerAnalyticsPeriod.weekly => math.max(
        PrayerAnalyticsCalculator.prayersPerDay.toDouble(),
        observedMax,
      ),
      _ => math.max(observedMax, 1),
    };
  }

  List<BarChartGroupData> _buildGroups(
    List<PrayerTrendBucket> buckets,
    FColors colors, {
    required double barWidth,
  }) {
    final jamaahColor = CompletionStatus.jamaah.getBadgeColor(colors);
    final onTimeColor = CompletionStatus.onTime.getBadgeColor(colors);
    final lateColor = CompletionStatus.late.getBadgeColor(colors);
    final missedColor = CompletionStatus.missed.getBadgeColor(colors);
    const borderRadius = BorderRadius.vertical(top: Radius.circular(8));

    return List.generate(buckets.length, (index) {
      final counts = buckets[index].statusCounts;
      final jamaah = (counts[CompletionStatus.jamaah] ?? 0).toDouble();
      final onTime = (counts[CompletionStatus.onTime] ?? 0).toDouble();
      final late = (counts[CompletionStatus.late] ?? 0).toDouble();
      final missed = (counts[CompletionStatus.missed] ?? 0).toDouble();
      final total = jamaah + onTime + late + missed;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: total,
            width: barWidth,
            borderRadius: borderRadius,
            borderSide: .none,
            rodStackItems: [
              BarChartRodStackItem(0, jamaah, jamaahColor, borderSide: .none),
              BarChartRodStackItem(
                jamaah,
                jamaah + onTime,
                onTimeColor,
                borderSide: .none,
              ),
              BarChartRodStackItem(
                jamaah + onTime,
                jamaah + onTime + late,
                lateColor,
                borderSide: .none,
              ),
              BarChartRodStackItem(
                jamaah + onTime + late,
                total,
                missedColor,
                borderSide: .none,
              ),
            ],
          ),
        ],
      );
    });
  }
}

class _BottomTitle extends ConsumerWidget {
  const _BottomTitle({
    required this.index,
    required this.buckets,
    required this.meta,
  });

  final int index;
  final List<PrayerTrendBucket> buckets;
  final TitleMeta meta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (index < 0 || index >= buckets.length) {
      return const SizedBox.shrink();
    }

    final bucket = buckets[index];
    final locale = context.l10n.localeName;
    final theme = context.theme;
    final colors = theme.colors;
    final period = ref.watch(
      prayerAnalyticsSettingsProvider.select(
        (value) => value.value?.period ?? PrayerAnalyticsPeriod.weekly,
      ),
    );

    final label = switch (period) {
      PrayerAnalyticsPeriod.yearly => DateFormat.MMM(
        locale,
      ).format(bucket.start),
      PrayerAnalyticsPeriod.monthly => DateFormat.Md(
        locale,
      ).format(bucket.start),
      PrayerAnalyticsPeriod.weekly => DateFormat.E(locale).format(bucket.start),
    };

    final showStreakMarker =
        period == PrayerAnalyticsPeriod.weekly &&
        isFullyCompletedBucket(bucket);

    return SideTitleWidget(
      meta: meta,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showStreakMarker)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Icon(
                FLucideIcons.flame,
                size: 12,
                color: colors.primary,
              ),
            ),
          Text(
            label,
            style: theme.typography.xs.copyWith(
              color: theme.colors.mutedForeground,
              fontWeight: showStreakMarker ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow();

  static const List<CompletionStatus> _statuses = [
    CompletionStatus.jamaah,
    CompletionStatus.onTime,
    CompletionStatus.late,
    CompletionStatus.missed,
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final l10n = context.l10n;

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: [
        for (final status in _statuses)
          _LegendItem(
            label: status.getLocaleName(l10n),
            color: status.getBadgeColor(colors),
          ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    return MergeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: theme.typography.xs.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}
