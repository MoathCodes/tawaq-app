import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/prayer/data/models/prayer_completion.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_analysis_section.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_analytics.dart';
import 'package:tawaq/feature/prayer/presentation/extensions/completion_status_ui.dart';
import 'package:tawaq/theme/theme.dart';

/// Card showing prayer trend analysis with a stacked bar chart.
class TrendAnalysisCard extends StatelessWidget {
  /// Creates a [TrendAnalysisCard].
  const TrendAnalysisCard({
    required this.data,
    required this.onPeriodChanged,
    required this.selectedPeriod,
    super.key,
  });

  /// The analysis data to display.
  final PrayerAnalysisSectionData data;

  /// Callback when the selected period tab changes.
  final void Function(PrayerAnalyticsPeriod) onPeriodChanged;

  /// The currently selected analytics period.
  final PrayerAnalyticsPeriod selectedPeriod;

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final colors = theme.colors;
    final l10n = context.l10n;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colors.border,
        ),
        borderRadius: theme.radii.lg,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.graphicalAnalysis,
              style: theme.typography.lg.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FTabs(
            control: FTabControl.lifted(
              index: selectedPeriod.index,
              onChange: (index) =>
                  onPeriodChanged(PrayerAnalyticsPeriod.values[index]),
            ),
            style: .delta(
              decoration: .boxDelta(color: colors.barrier),
              labelTextStyle: .delta([
                .exact(
                  {.desktop},
                  .delta(
                    color: colors.secondaryForeground.withAlpha(150),
                  ),
                ),
              ]),
            ),

            children: PrayerAnalyticsPeriod.values.map((period) {
              return FTabEntry(
                label: Text(period.getLocaleName(l10n)),
                child: _TrendChart(
                  data: data,
                  period: period,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.data, required this.period});

  final PrayerAnalysisSectionData data;
  final PrayerAnalyticsPeriod period;

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final l10n = context.l10n;
    final buckets = data.trendBuckets;

    if (buckets.isEmpty) {
      return SizedBox(
        height: 180,
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

    final groups = _buildGroups(buckets, theme.colors);
    final maxTotal = groups
        .map((g) => g.barRods.first.toY)
        .fold<double>(1, math.max);

    return Column(
      children: [
        ExcludeSemantics(
          child: SizedBox(
            height: 180,
            child: BarChart(
            BarChartData(
              maxY: maxTotal + 1,
              gridData: const FlGridData(show: false),
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
                    interval: 1,
                    getTitlesWidget: (value, meta) => _BottomTitle(
                      index: value.toInt(),
                      buckets: buckets,
                      period: period,
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
        const SizedBox(height: AppSpacing.md),
        const _LegendRow(),
      ],
    );
  }

  List<BarChartGroupData> _buildGroups(
    List<PrayerTrendBucket> buckets,
    FColors colors,
  ) {
    // Cache colors once
    final jamaahColor = CompletionStatus.jamaah.getBadgeColor(colors);
    final onTimeColor = CompletionStatus.onTime.getBadgeColor(colors);
    final lateColor = CompletionStatus.late.getBadgeColor(colors);
    final missedColor = CompletionStatus.missed.getBadgeColor(colors);
    final borderRadius = BorderRadius.circular(6);

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
            width: 14,
            borderRadius: borderRadius,
            borderSide: .none,
            rodStackItems: [
              BarChartRodStackItem(
                0,
                jamaah,
                jamaahColor,
                borderSide: .none,
              ),
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

class _BottomTitle extends StatelessWidget {
  const _BottomTitle({
    required this.index,
    required this.buckets,
    required this.period,
    required this.meta,
  });

  final int index;
  final List<PrayerTrendBucket> buckets;
  final PrayerAnalyticsPeriod period;
  final TitleMeta meta;

  @override
  Widget build(BuildContext context) {
    if (index < 0 || index >= buckets.length) {
      return const SizedBox.shrink();
    }

    final bucket = buckets[index];
    final locale = context.l10n.localeName;

    final label = switch (period) {
      PrayerAnalyticsPeriod.yearly => DateFormat.MMM(
        locale,
      ).format(bucket.start),
      PrayerAnalyticsPeriod.monthly => DateFormat.Md(
        locale,
      ).format(bucket.start),
      PrayerAnalyticsPeriod.weekly => DateFormat.E(locale).format(bucket.start),
    };

    final theme = FTheme.of(context);

    return SideTitleWidget(
      meta: meta,
      child: Text(
        label,
        style: theme.typography.xs.copyWith(
          color: theme.colors.mutedForeground,
        ),
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

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < _statuses.length; i++) ...[
          if (i != 0) const SizedBox(width: AppSpacing.md),
          _LegendItem(
            label: _statuses[i].getLocaleName(l10n),
            color: _statuses[i].getBadgeColor(colors),
          ),
        ],
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
