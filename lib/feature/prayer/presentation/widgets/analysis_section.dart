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
import 'package:hasanat/feature/prayer/domain/services/prayer_analytics_calculator.dart';
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

    final score = _weightedScore(counts);

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'إنجاز اليوم',
                    style: theme.typography.lg.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Icon(
                    FIcons.chartSpline,
                    size: 18.sp,
                    color: theme.colors.mutedForeground,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: _Gauge(
                  progress: score,
                  size: gaugeSize,
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

  double _weightedScore(Map<CompletionStatus, int> counts) {
    final jamaah = counts[CompletionStatus.jamaah] ?? 0;
    final onTime = counts[CompletionStatus.onTime] ?? 0;
    final late = counts[CompletionStatus.late] ?? 0;
    const expected = PrayerAnalyticsCalculator.prayersPerDay;
    if (expected == 0) return 0;

    final totalScore = (jamaah * 1.0) + (onTime * 0.85) + (late * 0.5);
    return (totalScore / expected).clamp(0.0, 1.0);
  }
}

class _Gauge extends StatelessWidget {
  const _Gauge({required this.progress, required this.size});

  final double progress;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final percent = (progress * 100).round();

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
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'مؤشر الأداء',
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
  _GaugePainter({required this.progress, required this.trackColor});

  final double progress;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    if (!progress.isFinite) return;

    final safeProgress = progress.clamp(0.0, 1.0);
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2.2;
    const startAngle = math.pi;
    const sweepAngle = math.pi;
    const strokeWidth = 16.0;

    if (radius <= 0) return;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, startAngle, sweepAngle, false, trackPaint);

    if (safeProgress <= 0) return;

    final gradient = SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + sweepAngle * safeProgress,
      colors: const [
        Color(0xFF60A5FA),
        Color(0xFF22D3EE),
        Color(0xFF34D399),
      ],
    );

    final progressPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressSweep = sweepAngle * safeProgress;
    if (progressSweep > 0) {
      canvas.drawArc(rect, startAngle, progressSweep, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor;
  }
}

class _DailyStatsRow extends StatelessWidget {
  const _DailyStatsRow({required this.counts});

  final Map<CompletionStatus, int> counts;

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    const statuses = [
      CompletionStatus.missed,
      CompletionStatus.late,
      CompletionStatus.onTime,
      CompletionStatus.jamaah,
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colors.background.withValues(alpha: 0.2),
        borderRadius: context.theme.radii.lg,
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (var i = 0; i < statuses.length; i++) ...[
              Expanded(
                child: _StatColumn(
                  value: counts[statuses[i]] ?? 0,
                  label: statuses[i].getLocaleName(context.l10n),
                  color: statuses[i].getBadgeColor(isDark: true),
                ),
              ),
              if (i != statuses.length - 1) _VerticalDivider(),
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
  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    return Container(
      width: 1,
      height: 32,
      color: theme.colors.border.withValues(alpha: 0.2),
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
            'التحليل البياني',
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
            'لا توجد بيانات',
            style: theme.typography.sm.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
        ),
      );
    }

    final groups = _buildGroups(buckets);
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
                          text: 'الإجمالي: $total\n',
                          style: theme.typography.xs.copyWith(
                            color: theme.colors.mutedForeground,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text: '● ${context.l10n.jamaah}: $jamaah\n',
                          style: theme.typography.xs.copyWith(
                            color: CompletionStatus.jamaah.getBadgeColor(
                              isDark: true,
                            ),
                          ),
                        ),
                        TextSpan(
                          text: '● ${context.l10n.onTime}: $onTime\n',
                          style: theme.typography.xs.copyWith(
                            color: CompletionStatus.onTime.getBadgeColor(
                              isDark: true,
                            ),
                          ),
                        ),
                        TextSpan(
                          text: '● ${context.l10n.late}: $late\n',
                          style: theme.typography.xs.copyWith(
                            color: CompletionStatus.late.getBadgeColor(
                              isDark: true,
                            ),
                          ),
                        ),
                        TextSpan(
                          text: '● ${context.l10n.missed}: $missed',
                          style: theme.typography.xs.copyWith(
                            color: CompletionStatus.missed.getBadgeColor(
                              isDark: true,
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
  ) {
    final jamaahColor = CompletionStatus.jamaah.getBadgeColor(isDark: true);
    final onTimeColor = CompletionStatus.onTime.getBadgeColor(isDark: true);
    final lateColor = CompletionStatus.late.getBadgeColor(isDark: true);
    final missedColor = CompletionStatus.missed.getBadgeColor(isDark: true);

    return buckets.asMap().entries.map((entry) {
      final index = entry.key;
      final counts = entry.value.statusCounts;
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
            borderRadius: BorderRadius.circular(6),
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
    }).toList();
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

  @override
  Widget build(BuildContext context) {
    const statuses = [
      CompletionStatus.jamaah,
      CompletionStatus.onTime,
      CompletionStatus.late,
      CompletionStatus.missed,
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < statuses.length; i++) ...[
          if (i != 0) const SizedBox(width: AppSpacing.md),
          _LegendItem(
            label: statuses[i].getLocaleName(context.l10n),
            color: statuses[i].getBadgeColor(isDark: true),
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
