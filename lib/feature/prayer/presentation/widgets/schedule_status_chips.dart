import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/mouse_click.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_completion.dart';
import 'package:tawaq/feature/prayer/domain/prayer_calendar.dart';
import 'package:tawaq/feature/prayer/presentation/extensions/completion_status_ui.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_completion_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_completions_for_date_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_day.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/prayer_semantics.dart';
import 'package:tawaq/theme/theme.dart';

/// Circular status chips for schedule prayer rows.
class ScheduleStatusChips extends ConsumerWidget {
  const new({
    required this.prayer,
    required this.completionDay,
    required this.prayerTime,
    this.menu = false,
    super.key,
  });

  static const chipSize = 30.0;

  final bool menu;
  final Prayer prayer;
  final DateTime completionDay;
  final DateTime prayerTime;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dayKey = calendarDayKeyFromDate(completionDay);
    final completionStatus = ref.watch(
      completionStatusProvider(prayer, dayKey),
    );

    if (menu) {
      final now = ref.watch(prayerMinuteSnapshotProvider)?.now;
      final enabled = now != null && !prayerTime.isAfter(now);
      final l10n = context.l10n;
      return FPopoverMenu(
        menu: [
          FItemGroup(
            children: [
              for (final status in selectableCompletionStatuses)
                FItem(
                  title: Text(status.getLocaleName(l10n)),
                  prefix: Icon(status.getIcon()),
                  onPress: enabled
                      ? () => unawaited(
                          ref
                              .read(prayerCompletionActionsProvider.notifier)
                              .setPrayerStatus(
                                prayer: prayer,
                                completionDay: completionDay,
                                status: status,
                              ),
                        )
                      : null,
                ),
            ],
          ),
        ],
        builder: (context, controller, _) => FButton.icon(
          variant: .ghost,
          size: .sm,
          semanticsLabel: PrayerSemantics.statusMenuTrigger(
            l10n: l10n,
            status: completionStatus,
          ),
          onPress: enabled ? controller.toggle : null,
          child: Icon(
            completionStatus?.getIcon() ?? FLucideIcons.circleCheck,
            size: 18,
          ),
        ),
      );
    }
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: selectableCompletionStatuses
          .where((status) => status != CompletionStatus.none)
          .map(
            (status) => _ScheduleStatusChip(
              prayer: prayer,
              completionDay: completionDay,
              prayerTime: prayerTime,
              status: status,
              isSelected:
                  completionStatus != null && status == completionStatus,
            ),
          )
          .toList(),
    );
  }
}

class _ScheduleStatusChip extends ConsumerWidget {
  const new({
    required this.prayer,
    required this.completionDay,
    required this.prayerTime,
    required this.status,
    required this.isSelected,
  });

  final Prayer prayer;
  final DateTime completionDay;
  final DateTime prayerTime;
  final CompletionStatus status;
  final bool isSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final colors = theme.colors;
    final now = ref.watch(prayerMinuteSnapshotProvider)?.now;
    final enable = now != null && prayerTime.isBefore(now);
    final accent = status.getBadgeColor(colors);
    final icon = status.getIcon();
    final l10n = context.l10n;

    return MouseClick(
      disabled: !enable,
      onClick: enable
          ? () => unawaited(
              ref
                  .read(prayerCompletionActionsProvider.notifier)
                  .setPrayerStatus(
                    prayer: prayer,
                    completionDay: completionDay,
                    status: status,
                  ),
            )
          : null,
      semanticsLabel: PrayerSemantics.statusOption(
        l10n: l10n,
        status: status,
        enabled: enable,
      ),
      child: ExcludeSemantics(
        child: Opacity(
          opacity: enable ? 1 : 0.45,
          child: AnimatedContainer(
            duration: theme.durations.fast,
            width: ScheduleStatusChips.chipSize,
            height: ScheduleStatusChips.chipSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected
                  ? accent
                  : colors.secondary.withValues(alpha: 0.5),
              shape: BoxShape.circle,
              border: Border.all(color: isSelected ? accent : colors.border),
            ),
            child: Icon(
              icon,
              size: 14,
              color: isSelected ? colors.background : colors.foreground,
            ),
          ),
        ),
      ),
    );
  }
}
