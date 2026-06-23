import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/hooks/hooks.dart';
import 'package:tawaq/core/layout/responsive.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/mouse_click.dart';
import 'package:tawaq/feature/prayer/data/models/prayer_completion.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_analysis_section.dart';
import 'package:tawaq/feature/prayer/domain/prayer_extensions.dart';
import 'package:tawaq/feature/prayer/domain/services/prayer_analytics_calculator.dart';
import 'package:tawaq/feature/prayer/presentation/extensions/completion_status_ui.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_analytics/prayer_analytics_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_completion_provider.dart';
import 'package:tawaq/theme/theme.dart';

/// Whether every obligatory prayer was logged with a positive status.
bool isFullyCompletedBucket(PrayerTrendBucket bucket) {
  final positive =
      (bucket.statusCounts[CompletionStatus.jamaah] ?? 0) +
      (bucket.statusCounts[CompletionStatus.onTime] ?? 0) +
      (bucket.statusCounts[CompletionStatus.late] ?? 0);
  return positive >= PrayerAnalyticsCalculator.prayersPerDay;
}

/// Prominent streak banner showing current and best streaks.
class StreakBanner extends StatelessWidget {
  const StreakBanner({
    required this.currentStreak,
    required this.bestStreak,
    super.key,
  });

  final int currentStreak;
  final int bestStreak;

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final colors = theme.colors;
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        borderRadius: theme.radii.md,
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            colors.primary.withValues(alpha: 0.2),
            colors.primary.withValues(alpha: 0.06),
          ],
        ),
        border: Border.all(color: colors.primary.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StreakHighlight(
              icon: FLucideIcons.flame,
              label: l10n.currentStreak,
              streak: currentStreak,
              streakLabel: l10n.streakInDays,
              emphasized: true,
            ),
          ),
          Container(
            width: 1,
            height: 44,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            color: colors.border.withValues(alpha: 0.35),
          ),
          Expanded(
            child: _StreakHighlight(
              icon: FLucideIcons.trophy,
              label: l10n.bestStreak,
              streak: bestStreak,
              streakLabel: l10n.streakInDays,
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakHighlight extends StatelessWidget {
  const _StreakHighlight({
    required this.icon,
    required this.label,
    required this.streak,
    required this.streakLabel,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final int streak;
  final String Function(int) streakLabel;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final colors = theme.colors;
    final valueStyle = (emphasized ? theme.typography.body.xl : theme.typography.body.lg)
        .copyWith(
          fontWeight: FontWeight.w800,
          color: emphasized ? colors.primary : colors.foreground,
        );

    return Row(
      children: [
        Icon(
          icon,
          size: emphasized ? 26 : 22,
          color: emphasized ? colors.primary : colors.mutedForeground,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                streakLabel(streak),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: valueStyle,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.typography.body.xs.copyWith(
                  color: colors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Row of five prayer slots showing today's logged status.
class TodayPrayerTracker extends ConsumerWidget {
  const TodayPrayerTracker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FTheme.of(context);
    final colors = theme.colors;
    final l10n = context.l10n;
    final statuses = ref.watch(
      prayerAnalysisSectionProvider.select(
        (state) => state.value?.todayPrayerStatuses,
      ),
    );

    if (statuses == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final prayer in kObligatoryPrayers) ...[
          _PrayerTrackerRow(
            prayer: prayer,
            label: prayer.getLocaleName(l10n),
          ),
          if (prayer != kObligatoryPrayers.last)
            const SizedBox(height: AppSpacing.sm),
        ],
        const SizedBox(height: AppSpacing.md),
        _TodayStackedBar(statuses: statuses, colors: colors),
      ],
    );
  }
}

class _PrayerTrackerRow extends HookConsumerWidget {
  const _PrayerTrackerRow({
    required this.prayer,
    required this.label,
  });

  final Prayer prayer;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FTheme.of(context);
    final colors = theme.colors;
    final status = ref.watch(
      prayerAnalysisSectionProvider.select(
        (state) =>
            state.value?.todayPrayerStatuses[prayer] ?? CompletionStatus.none,
      ),
    );
    final isLogged = status != CompletionStatus.none;
    final statusColor = isLogged
        ? status.getBadgeColor(colors)
        : colors.mutedForeground.withValues(alpha: 0.35);
    final icon = status.getIcon();
    final (:isHovered, :setHovered) = useHoverState();

    final background = isLogged
        ? (isHovered
              ? colors.hover(statusColor.withValues(alpha: 0.18))
              : statusColor.withValues(alpha: 0.18))
        : (isHovered
              ? colors.secondary
              : colors.background.withValues(alpha: 0.35));

    final borderColor = isLogged
        ? statusColor.withValues(alpha: 0.55)
        : (isHovered ? colors.border : colors.border.withValues(alpha: 0.35));

    return Row(
      children: [
        MouseClick(
          onHoverChange: (hovering) => setHovered(value: hovering),
          onClick: () => unawaited(
            ref
                .read(prayerCompletionActionsProvider.notifier)
                .cycleTodayPrayerStatus(
                  prayer: prayer,
                  currentStatus: status,
                ),
          ),
          child: AnimatedContainer(
            duration: theme.durations.fast,
            curve: Curves.easeOutCubic,
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: background,
              borderRadius: theme.radii.sm,
              border: Border.all(color: borderColor),
            ),
            alignment: Alignment.center,
            child: icon == null
                ? const SizedBox.shrink()
                : Icon(icon, size: 14, color: statusColor),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: theme.typography.body.sm.copyWith(
              color: isLogged ? colors.foreground : colors.mutedForeground,
              fontWeight: isLogged ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          isLogged ? status.getLocaleName(context.l10n) : '—',
          style: theme.typography.body.xs.copyWith(
            color: isLogged ? statusColor : colors.mutedForeground,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _TodayStackedBar extends StatelessWidget {
  const _TodayStackedBar({
    required this.statuses,
    required this.colors,
  });

  final Map<Prayer, CompletionStatus> statuses;
  final FColors colors;

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final segments = <Widget>[];

    for (final prayer in kObligatoryPrayers) {
      final status = statuses[prayer] ?? CompletionStatus.none;
      final color = status == CompletionStatus.none
          ? colors.mutedForeground.withValues(alpha: 0.15)
          : status.getBadgeColor(colors);

      segments.add(
        Expanded(
          child: Container(
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: segments),
        const SizedBox(height: AppSpacing.xs),
        Text(
          context.l10n.performanceIndicator,
          style: theme.typography.body.xs.copyWith(
            color: theme.colors.mutedForeground,
          ),
        ),
      ],
    );
  }
}

/// Compact 2x2 grid of today's status counts.
class TodayStatusGrid extends ConsumerWidget {
  const TodayStatusGrid({super.key});

  static const List<CompletionStatus> _statuses = [
    CompletionStatus.jamaah,
    CompletionStatus.onTime,
    CompletionStatus.late,
    CompletionStatus.missed,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(
      prayerAnalysisSectionProvider.select(
        (state) => state.value?.todayStatusCounts,
      ),
    );

    if (counts == null) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = responsiveColumnCount(
          context,
          constraints.maxWidth,
          maxColumns: 4,
        );

        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final status in _statuses)
              SizedBox(
                width: columns == 4
                    ? (constraints.maxWidth - AppSpacing.sm * 3) / 4
                    : (constraints.maxWidth - AppSpacing.sm) / 2,
                child: _StatusChip(
                  status: status,
                  value: counts[status] ?? 0,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.status,
    required this.value,
  });

  final CompletionStatus status;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final colors = theme.colors;
    final color = status.getBadgeColor(colors);
    final icon = status.getIcon();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: theme.radii.sm,
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 12, color: color),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                '$value',
                style: theme.typography.body.lg.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            status.getLocaleName(context.l10n),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.typography.body.xs.copyWith(
              color: colors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}

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
        _MetricBar(
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
          child: _MetricBar(
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

class _MetricBar extends StatelessWidget {
  const _MetricBar({
    required this.value,
    required this.color,
    required this.backgroundColor,
    this.minHeight = 8,
  });

  final double value;
  final Color color;
  final Color backgroundColor;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final radius = theme.radii.full;
    final fillFactor = value.clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        height: minHeight,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: backgroundColor),
            FractionallySizedBox(
              widthFactor: fillFactor,
              alignment: AlignmentDirectional.centerStart,
              child: ColoredBox(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
