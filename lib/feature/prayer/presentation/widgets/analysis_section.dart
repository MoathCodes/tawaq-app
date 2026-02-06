import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/utils/prayer_extensions.dart';
import 'package:hasanat/core/widgets/custom_cards.dart';
import 'package:hasanat/core/widgets/f_skeletonizer.dart';
import 'package:hasanat/feature/prayer/data/models/prayer_completion.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_analysis_section.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_analytics.dart';
import 'package:hasanat/feature/prayer/presentation/provider/prayer_analytics/prayer_analytics_provider.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hasanat/theme/theme.dart';
import 'package:intl/intl.dart';

/// Analysis section containing daily achievement and trends cards.
class AnalysisSection extends ConsumerWidget {
  /// Creates an [AnalysisSection].
  const AnalysisSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPeriod = ref.watch(
      stateSettingsProvider.select(
        (value) =>
            value.value?.prayerAnalyticsPeriod ?? PrayerAnalyticsPeriod.weekly,
      ),
    );
    final analysisState = ref.watch(prayerAnalysisSectionProvider);

    return analysisState.when(
      data: (data) => _AnalysisContent(
        data: data,
        onPeriodChanged: (period) => ref
            .read(stateSettingsProvider.notifier)
            .setPrayerAnalyticsPeriod(period),
        selectedPeriod: selectedPeriod,
      ),
      loading: () => FSkeletonizer(
        child: _AnalysisContent(
          data: PrayerAnalysisSectionData.empty(PrayerAnalyticsPeriod.weekly),
          onPeriodChanged: (_) {},
          selectedPeriod: selectedPeriod,
        ),
      ),
      error: (Object e, _) => StaticCard(
        child: FAlert(
          title: Text(context.l10n.errorOccurredWhile('Loading Analytics')),
          subtitle: Text(e.toString()),
        ),
      ),
    );
  }
}

class _AnalysisContent extends StatelessWidget {
  const _AnalysisContent({
    required this.data,
    required this.onPeriodChanged,
    required this.selectedPeriod,
  });

  final PrayerAnalysisSectionData data;
  final void Function(PrayerAnalyticsPeriod) onPeriodChanged;
  final PrayerAnalyticsPeriod selectedPeriod;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _DailyAchievementCard(data: data),
        const SizedBox(height: AppSpacing.md),
        _TrendAnalysisCard(
          data: data,
          onPeriodChanged: onPeriodChanged,
          selectedPeriod: selectedPeriod,
        ),
      ],
    );
  }
}

class _DailyAchievementCard extends StatelessWidget {
  const _DailyAchievementCard({required this.data});

  final PrayerAnalysisSectionData data;

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final counts = data.todayStatusCounts;

    return StaticCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      backgroundColor: theme.colors.secondary.withValues(alpha: 0.7),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : 240.0;
          final double gaugeSize = math.min(240, maxWidth);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.l10n.todayAchievement,
                style: theme.typography.lg.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              RepaintBoundary(
                child: Center(
                  child: _Gauge(
                    progress: data.todayPerformanceScore,
                    statusCounts: counts,
                    size: gaugeSize,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _DailyStatsRow(counts: counts),
            ],
          );
        },
      ),
    );
  }
}

class _Gauge extends StatelessWidget {
  const _Gauge({
    required this.progress,
    required this.statusCounts,
    required this.size,
  });

  final double progress;
  final Map<CompletionStatus, int> statusCounts;
  final double size;

  /// Determines the dominant status and returns its color for the percentage text.
  Color _getPerformanceColor(bool isDark) {
    final jamaah = statusCounts[CompletionStatus.jamaah] ?? 0;
    final onTime = statusCounts[CompletionStatus.onTime] ?? 0;
    final late = statusCounts[CompletionStatus.late] ?? 0;
    final missed = statusCounts[CompletionStatus.missed] ?? 0;
    final total = jamaah + onTime + late + missed;

    if (total == 0) {
      return CompletionStatus.onTime.getBadgeColor(isDark: isDark);
    }

    // Calculate a weighted score: jamaah=4, onTime=3, late=1, missed=0
    final score = (jamaah * 4 + onTime * 3 + late * 1) / (total * 4);

    // Return color based on performance tier
    if (score >= 0.75) {
      return CompletionStatus.jamaah.getBadgeColor(isDark: isDark);
    } else if (score >= 0.5) {
      return CompletionStatus.onTime.getBadgeColor(isDark: isDark);
    } else if (score >= 0.25) {
      return CompletionStatus.late.getBadgeColor(isDark: isDark);
    } else {
      return CompletionStatus.missed.getBadgeColor(isDark: isDark);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final percent = (progress * 100).round();
    final performanceColor = _getPerformanceColor(theme.isDark);

    return SizedBox(
      width: size,
      height: size * 0.65,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size * 0.65),
            painter: _GaugePainter(
              progress: progress,
              statusCounts: statusCounts,
              isDark: theme.isDark,
              trackColor: theme.colors.secondaryForeground.withValues(
                alpha: 0.12,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            child: Column(
              children: [
                Text(
                  '$percent%',
                  style: theme.typography.xl.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 32.sp,
                    color: performanceColor,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  context.l10n.performanceIndicator,
                  style: theme.typography.sm.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.progress,
    required this.statusCounts,
    required this.trackColor,
    required this.isDark,
  });

  final double progress;
  final Map<CompletionStatus, int> statusCounts;
  final Color trackColor;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || !progress.isFinite) return;

    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2.2;

    if (radius <= 0) return;

    const startAngle = math.pi;
    const totalSweep = math.pi;
    const strokeWidth = 16.0;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Draw background track
    canvas.drawArc(
      rect,
      startAngle,
      totalSweep,
      false,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // Get counts for each status
    final jamaah = statusCounts[CompletionStatus.jamaah] ?? 0;
    final onTime = statusCounts[CompletionStatus.onTime] ?? 0;
    final late = statusCounts[CompletionStatus.late] ?? 0;
    final missed = statusCounts[CompletionStatus.missed] ?? 0;
    final total = jamaah + onTime + late + missed;

    if (total == 0) return;

    // Calculate proportional angles for each status
    // Order: jamaah (best) -> onTime -> late -> missed (worst)
    final segments = <(double, Color)>[
      (jamaah / total, CompletionStatus.jamaah.getBadgeColor(isDark: isDark)),
      (onTime / total, CompletionStatus.onTime.getBadgeColor(isDark: isDark)),
      (late / total, CompletionStatus.late.getBadgeColor(isDark: isDark)),
      (missed / total, CompletionStatus.missed.getBadgeColor(isDark: isDark)),
    ];

    // Draw each segment
    var currentAngle = startAngle;
    for (final (proportion, color) in segments) {
      if (proportion <= 0) continue;

      final sweepAngle = totalSweep * proportion;

      canvas.drawArc(
        rect,
        currentAngle,
        sweepAngle,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.butt,
      );

      currentAngle += sweepAngle;
    }

    // Draw rounded caps at start and end
    if (total > 0) {
      // Start cap (first non-zero segment)
      final firstSegment = segments.firstWhere((s) => s.$1 > 0);
      final startCapOffset = Offset(
        center.dx + radius * math.cos(startAngle),
        center.dy + radius * math.sin(startAngle),
      );
      canvas.drawCircle(
        startCapOffset,
        strokeWidth / 2,
        Paint()..color = firstSegment.$2,
      );

      // End cap (last non-zero segment)
      final lastSegment = segments.lastWhere((s) => s.$1 > 0);
      final endCapOffset = Offset(
        center.dx + radius * math.cos(startAngle + totalSweep),
        center.dy + radius * math.sin(startAngle + totalSweep),
      );
      canvas.drawCircle(
        endCapOffset,
        strokeWidth / 2,
        Paint()..color = lastSegment.$2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.statusCounts != statusCounts;
  }
}

class _DailyStatsRow extends StatelessWidget {
  const _DailyStatsRow({required this.counts});

  static const List<CompletionStatus> _statuses = [
    CompletionStatus.missed,
    CompletionStatus.late,
    CompletionStatus.onTime,
    CompletionStatus.jamaah,
  ];

  final Map<CompletionStatus, int> counts;

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final isDark = theme.isDark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colors.background.withValues(alpha: 0.2),
        borderRadius: theme.radii.lg,
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (var i = 0; i < _statuses.length; i++) ...[
              Expanded(
                child: _StatColumn(
                  value: counts[_statuses[i]] ?? 0,
                  label: _statuses[i].getLocaleName(context.l10n),
                  color: _statuses[i].getBadgeColor(isDark: isDark),
                ),
              ),
              if (i != _statuses.length - 1) const _VerticalDivider(),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.value,
    required this.label,
    required this.color,
  });

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    return Column(
      children: [
        Text(
          value.toString(),
          style: theme.typography.lg.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: theme.typography.xs.copyWith(
            color: theme.colors.mutedForeground,
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: FTheme.of(context).colors.border.withValues(alpha: 0.2),
    );
  }
}

class _TrendAnalysisCard extends StatelessWidget {
  const _TrendAnalysisCard({
    required this.data,
    required this.onPeriodChanged,
    required this.selectedPeriod,
  });

  final PrayerAnalysisSectionData data;
  final void Function(PrayerAnalyticsPeriod) onPeriodChanged;
  final PrayerAnalyticsPeriod selectedPeriod;

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final colors = theme.colors;

    return StaticCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      backgroundColor: theme.colors.secondary.withValues(alpha: 0.7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.graphicalAnalysis,
            style: theme.typography.lg.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.md),
          FTabs(
            control: FTabControl.lifted(
              index: selectedPeriod.index,
              onChange: (index) =>
                  onPeriodChanged(PrayerAnalyticsPeriod.values[index]),
            ),
            style: (style) => style.copyWith(
              decoration: style.decoration.copyWith(color: colors.barrier),
              unselectedLabelTextStyle: style.unselectedLabelTextStyle.copyWith(
                color: colors.secondaryForeground.withAlpha(150),
              ),
            ),
            children: PrayerAnalyticsPeriod.values.map((period) {
              return FTabEntry(
                label: Text(period.getLocaleName(context.l10n)),
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
    final buckets = data.trendBuckets;

    if (buckets.isEmpty) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Text(
            context.l10n.noDataAvailable,
            style: theme.typography.sm.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
        ),
      );
    }

    final groups = _buildGroups(buckets, context.theme.isDark);
    final maxTotal = groups
        .map((g) => g.barRods.first.toY)
        .fold<double>(1, math.max);

    return Column(
      children: [
        SizedBox(
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

                    final title = period == PrayerAnalyticsPeriod.daily
                        ? (bucket.prayer?.getLocaleName(context.l10n) ?? '')
                        : DateFormat.MMMd(
                            context.l10n.localeName,
                          ).format(bucket.start);

                    return BarTooltipItem(
                      '$title\n',
                      theme.typography.sm.copyWith(
                        color: theme.colors.foreground,
                        fontWeight: FontWeight.w700,
                      ),
                      children: [
                        TextSpan(
                          text: '${context.l10n.total}: $total\n',
                          style: theme.typography.xs.copyWith(
                            color: theme.colors.mutedForeground,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text: '● ${context.l10n.jamaah}: $jamaah\n',
                          style: theme.typography.xs.copyWith(
                            color: CompletionStatus.jamaah.getBadgeColor(
                              isDark: context.theme.isDark,
                            ),
                          ),
                        ),
                        TextSpan(
                          text: '● ${context.l10n.onTime}: $onTime\n',
                          style: theme.typography.xs.copyWith(
                            color: CompletionStatus.onTime.getBadgeColor(
                              isDark: context.theme.isDark,
                            ),
                          ),
                        ),
                        TextSpan(
                          text: '● ${context.l10n.late}: $late\n',
                          style: theme.typography.xs.copyWith(
                            color: CompletionStatus.late.getBadgeColor(
                              isDark: context.theme.isDark,
                            ),
                          ),
                        ),
                        TextSpan(
                          text: '● ${context.l10n.missed}: $missed',
                          style: theme.typography.xs.copyWith(
                            color: CompletionStatus.missed.getBadgeColor(
                              isDark: context.theme.isDark,
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
        const SizedBox(height: AppSpacing.md),
        const _LegendRow(),
      ],
    );
  }

  List<BarChartGroupData> _buildGroups(
    List<PrayerTrendBucket> buckets,
    bool isDark,
  ) {
    // Cache colors once
    final jamaahColor = CompletionStatus.jamaah.getBadgeColor(isDark: isDark);
    final onTimeColor = CompletionStatus.onTime.getBadgeColor(isDark: isDark);
    final lateColor = CompletionStatus.late.getBadgeColor(isDark: isDark);
    final missedColor = CompletionStatus.missed.getBadgeColor(isDark: isDark);
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
            rodStackItems: [
              BarChartRodStackItem(0, jamaah, jamaahColor),
              BarChartRodStackItem(jamaah, jamaah + onTime, onTimeColor),
              BarChartRodStackItem(
                jamaah + onTime,
                jamaah + onTime + late,
                lateColor,
              ),
              BarChartRodStackItem(
                jamaah + onTime + late,
                total,
                missedColor,
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

    String label;
    switch (period) {
      case PrayerAnalyticsPeriod.daily:
        label = bucket.prayer?.getLocaleName(context.l10n) ?? '';
      case PrayerAnalyticsPeriod.yearly:
        label = DateFormat.MMM(locale).format(bucket.start);
      case PrayerAnalyticsPeriod.monthly:
        label = DateFormat.Md(locale).format(bucket.start);
      case PrayerAnalyticsPeriod.weekly:
        label = DateFormat.E(locale).format(bucket.start);
    }

    return SideTitleWidget(
      meta: meta,
      child: Text(
        label,
        style: FTheme.of(context).typography.xs.copyWith(
          color: FTheme.of(context).colors.mutedForeground,
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
    final isDark = context.theme.isDark;
    final l10n = context.l10n;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < _statuses.length; i++) ...[
          if (i != 0) const SizedBox(width: AppSpacing.md),
          _LegendItem(
            label: _statuses[i].getLocaleName(l10n),
            color: _statuses[i].getBadgeColor(isDark: isDark),
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
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
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
    );
  }
}
