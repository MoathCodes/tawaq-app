import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/widgets/custom_cards.dart';
import 'package:hasanat/feature/prayer/data/models/prayer_completion.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_analysis_section.dart';
import 'package:hasanat/theme/theme.dart';

/// Card showing today's prayer achievement gauge and stats breakdown.
class DailyAchievementCard extends StatelessWidget {
  /// Creates a [DailyAchievementCard].
  const DailyAchievementCard({required this.data, super.key});

  /// The analysis data to display.
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

  /// Determines the dominant status and returns its color for the percentage
  /// text.
  Color _getPerformanceColor(FColors colors) {
    final jamaah = statusCounts[CompletionStatus.jamaah] ?? 0;
    final onTime = statusCounts[CompletionStatus.onTime] ?? 0;
    final late = statusCounts[CompletionStatus.late] ?? 0;
    final missed = statusCounts[CompletionStatus.missed] ?? 0;
    final total = jamaah + onTime + late + missed;

    if (total == 0) {
      return CompletionStatus.onTime.getBadgeColor(colors);
    }

    // Calculate a weighted score: jamaah=4, onTime=3, late=1, missed=0
    final score = (jamaah * 4 + onTime * 3 + late * 1) / (total * 4);

    // Return color based on performance tier
    if (score >= 0.75) {
      return CompletionStatus.jamaah.getBadgeColor(colors);
    } else if (score >= 0.5) {
      return CompletionStatus.onTime.getBadgeColor(colors);
    } else if (score >= 0.25) {
      return CompletionStatus.late.getBadgeColor(colors);
    } else {
      return CompletionStatus.missed.getBadgeColor(colors);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final percent = (progress * 100).round();
    final performanceColor = _getPerformanceColor(theme.colors);

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
              colors: theme.colors,
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
    required this.colors,
  });

  final double progress;
  final Map<CompletionStatus, int> statusCounts;
  final Color trackColor;
  final FColors colors;

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
      (jamaah / total, CompletionStatus.jamaah.getBadgeColor(colors)),
      (onTime / total, CompletionStatus.onTime.getBadgeColor(colors)),
      (late / total, CompletionStatus.late.getBadgeColor(colors)),
      (missed / total, CompletionStatus.missed.getBadgeColor(colors)),
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
        oldDelegate.statusCounts != statusCounts ||
        oldDelegate.colors != colors;
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
    final colors = theme.colors;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.background.withValues(alpha: 0.2),
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
                  color: _statuses[i].getBadgeColor(colors),
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
