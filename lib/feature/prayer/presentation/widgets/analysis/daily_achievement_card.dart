import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/hooks/hooks.dart';
import 'package:tawaq/core/layout/responsive.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/utils/prayer_extensions.dart';
import 'package:tawaq/core/widgets/custom_cards.dart';
import 'package:tawaq/core/widgets/mouse_click.dart';
import 'package:tawaq/feature/prayer/data/models/prayer_completion.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_analysis_section.dart';
import 'package:tawaq/feature/prayer/domain/services/prayer_analytics_calculator.dart';
import 'package:tawaq/feature/prayer/presentation/extensions/completion_status_ui.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_analytics/prayer_analytics_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_completion_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_day.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_schedule/prayer_schedule_provider.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/prayer_semantics.dart';
import 'package:tawaq/theme/theme.dart';

/// Daily achievement section: header, streaks, tracker, and status breakdown.
class DailyAchievementCard extends ConsumerWidget {
  const DailyAchievementCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FTheme.of(context);
    final l10n = context.l10n;
    final analytics = ref.watch(
      prayerAnalysisSectionProvider.select(
        (state) => state.value?.periodAnalytics,
      ),
    );
    final todayStatusCounts = ref.watch(
      prayerAnalysisSectionProvider.select(
        (state) => state.value?.todayStatusCounts,
      ),
    );
    final todayPerformanceScore = ref.watch(
      prayerAnalysisSectionProvider.select(
        (state) => state.value?.todayPerformanceScore ?? 0.0,
      ),
    );
    final statuses = ref.watch(
      prayerAnalysisSectionProvider.select(
        (state) => state.value?.todayPrayerStatuses,
      ),
    );

    if (analytics == null || todayStatusCounts == null || statuses == null) {
      return const SizedBox.shrink();
    }

    final loggedCount = todayStatusCounts.values.fold<int>(
      0,
      (total, count) => total + count,
    );
    final percent = (todayPerformanceScore * 100).round();

    return StaticCard(
      backgroundColor: Colors.transparent,
      borderColor: Colors.transparent,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    l10n.todayAchievement,
                    style: theme.typography.body.lg.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Semantics(
                label: PrayerSemantics.todayPerformance(
                  l10n: l10n,
                  percent: percent,
                ),
                readOnly: true,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colors.primary.withValues(alpha: 0.12),
                    borderRadius: theme.radii.full,
                    border: Border.all(
                      color: theme.colors.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    '$loggedCount/${PrayerAnalyticsCalculator.prayersPerDay} · $percent%',
                    style: theme.typography.body.sm.copyWith(
                      color: theme.colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Semantics(
            label: PrayerSemantics.streakSummary(
              l10n: l10n,
              currentStreak: analytics.currentStreak,
              bestStreak: analytics.bestStreak,
            ),
            readOnly: true,
            child: _DailyStreakBanner(
              currentStreak: analytics.currentStreak,
              bestStreak: analytics.bestStreak,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _DailyPrayerTracker(statuses: statuses),
          const SizedBox(height: AppSpacing.lg),
          _DailyStatusGrid(counts: todayStatusCounts),
        ],
      ),
    );
  }
}

class _DailyStreakBanner extends StatelessWidget {
  const _DailyStreakBanner({
    required this.currentStreak,
    required this.bestStreak,
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
    final valueStyle =
        (emphasized ? theme.typography.body.xl : theme.typography.body.lg)
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

class _DailyPrayerTracker extends ConsumerWidget {
  const _DailyPrayerTracker({required this.statuses});

  final Map<Prayer, CompletionStatus> statuses;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = FTheme.of(context).colors;
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final prayer in kObligatoryPrayers) ...[
          _DailyTrackerRow(
            prayer: prayer,
            label: prayer.getLocaleName(l10n),
          ),
          if (prayer != kObligatoryPrayers.last)
            const SizedBox(height: AppSpacing.sm),
        ],
        const SizedBox(height: AppSpacing.md),
        _DailyStackedBar(statuses: statuses, colors: colors),
      ],
    );
  }
}

class _DailyTrackerRow extends ConsumerWidget {
  const _DailyTrackerRow({
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

    return Row(
      children: [
        _TrackerStatusChip(prayer: prayer, status: status),
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

class _DailyStackedBar extends StatelessWidget {
  const _DailyStackedBar({
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

class _DailyStatusGrid extends StatelessWidget {
  const _DailyStatusGrid({required this.counts});

  static const List<CompletionStatus> _statuses = [
    CompletionStatus.jamaah,
    CompletionStatus.onTime,
    CompletionStatus.late,
    CompletionStatus.missed,
  ];

  final Map<CompletionStatus, int> counts;

  @override
  Widget build(BuildContext context) {
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
          alignment: WrapAlignment.center,
          children: [
            for (final status in _statuses)
              SizedBox(
                width: columns == 4
                    ? (constraints.maxWidth - AppSpacing.sm * 3) / 6
                    : (constraints.maxWidth - AppSpacing.sm) / 4.3,
                child: _DailyStatusChip(
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

class _DailyStatusChip extends StatelessWidget {
  const _DailyStatusChip({
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

class _TrackerStatusChip extends HookConsumerWidget {
  const _TrackerStatusChip({
    required this.prayer,
    required this.status,
  });

  final Prayer prayer;
  final CompletionStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final colors = theme.colors;
    final l10n = context.l10n;
    final prayerTime = ref.watch(
      prayerScheduleProvider().select(
        (rows) => rows
            .where((row) => row.prayer == prayer)
            .firstOrNull
            ?.prayerTime,
      ),
    );
    final enable = ref.watch(
      prayerDayProvider.select((asyncDay) {
        final now = asyncDay.value?.now;
        return now != null &&
            prayerTime != null &&
            prayerTime.isBefore(now);
      }),
    );
    final isLogged = status != CompletionStatus.none;
    final statusColor = isLogged
        ? status.getBadgeColor(colors)
        : colors.mutedForeground.withValues(alpha: 0.35);
    final icon = status.getIcon();
    final (:isHovered, :setHovered) = useHoverState();

    final background = isLogged
        ? (isHovered && enable
              ? colors.hover(statusColor.withValues(alpha: 0.18))
              : statusColor.withValues(alpha: 0.18))
        : (isHovered && enable
              ? colors.secondary
              : colors.background.withValues(alpha: 0.35));

    final borderColor = isLogged
        ? statusColor.withValues(alpha: 0.55)
        : (isHovered && enable
              ? colors.border
              : colors.border.withValues(alpha: 0.35));

    return MouseClick(
      disabled: !enable,
      onHoverChange: enable
          ? (hovering) => setHovered(value: hovering)
          : null,
      onClick: enable
          ? () => unawaited(
              ref
                  .read(prayerCompletionActionsProvider.notifier)
                  .cycleTodayPrayerStatus(
                    prayer: prayer,
                    currentStatus: status,
                  ),
            )
          : null,
      semanticsLabel: enable
          ? (isLogged
                ? status.getLocaleName(l10n)
                : l10n.logPrayerStatus)
          : '${l10n.logPrayerStatus}, ${l10n.prepareForPrayer}',
      child: ExcludeSemantics(
        child: Opacity(
          opacity: enable ? 1 : 0.45,
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
      ),
    );
  }
}
