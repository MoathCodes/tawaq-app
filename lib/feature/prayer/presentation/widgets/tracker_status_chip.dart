import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/hooks/hooks.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/mouse_click.dart';
import 'package:tawaq/feature/prayer/data/models/prayer_completion.dart';
import 'package:tawaq/feature/prayer/presentation/extensions/completion_status_ui.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_analytics/prayer_analytics_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_completion_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_data_providers.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_schedule/prayer_schedule_provider.dart';
import 'package:tawaq/theme/theme.dart';

/// Single cycling status chip for the daily prayer tracker.
class TrackerStatusChip extends HookConsumerWidget {
  const TrackerStatusChip({required this.prayer, super.key});

  final Prayer prayer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final colors = theme.colors;
    final l10n = context.l10n;
    final status = ref.watch(
      prayerAnalysisSectionProvider.select(
        (state) =>
            state.value?.todayPrayerStatuses[prayer] ?? CompletionStatus.none,
      ),
    );
    final prayerTime = ref.watch(
      prayerScheduleProvider().select(
        (rows) => rows
            .where((row) => row.prayer == prayer)
            .firstOrNull
            ?.prayerTime,
      ),
    );
    final enable = ref.watch(
      currentLocationTimeProvider.select(
        (now) => now != null && prayerTime != null && prayerTime.isBefore(now),
      ),
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
