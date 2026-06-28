import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/feature/prayer/data/models/prayer_completion.dart';
import 'package:tawaq/feature/prayer/presentation/extensions/completion_status_ui.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/analysis/analysis_metric_bar.dart';
import 'package:tawaq/theme/theme.dart';

/// Period completion summary with progress bar.
class PeriodCompletionSummary extends StatelessWidget {
  const PeriodCompletionSummary({
    required this.completionPercentage,
    required this.subtitle,
    super.key,
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
