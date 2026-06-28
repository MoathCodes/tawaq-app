import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/prayer/data/models/prayer_completion.dart';
import 'package:tawaq/feature/prayer/presentation/extensions/completion_status_ui.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_analytics/prayer_analytics_provider.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/analysis/analysis_metric_bar.dart';
import 'package:tawaq/theme/theme.dart';

/// Horizontal rate bars for period status breakdown.
class PeriodRateBars extends ConsumerWidget {
  const PeriodRateBars({super.key});

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
