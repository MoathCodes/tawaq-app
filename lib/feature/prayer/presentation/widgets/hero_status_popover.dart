import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/mouse_click.dart';
import 'package:tawaq/feature/prayer/data/models/prayer_completion.dart';
import 'package:tawaq/feature/prayer/presentation/extensions/completion_status_ui.dart';
import 'package:tawaq/feature/prayer/domain/prayer_calendar.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_card/prayer_card_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_completion_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_completions_for_date_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_data_providers.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/prayer_semantics.dart';
import 'package:tawaq/theme/theme.dart';

/// Popover status picker for the prayer hero header.
class HeroStatusPopover extends ConsumerWidget {
  const HeroStatusPopover({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final l10n = context.l10n;
    final (prayer, canSetStatus) = ref.watch(
      prayerCardStaticProvider.select((c) => (c.prayer, c.canSetStatus)),
    );
    final dayKey = ref.watch(prayerCalendarDayKeyProvider);
    if (!canSetStatus || dayKey == 0) {
      return const SizedBox.shrink();
    }
    final completionDay = dateFromCalendarDayKey(dayKey);
    final status =
        ref.watch(prayerTodayStatusProvider(prayer)).value ??
        CompletionStatus.none;

    final menuTriggerLabel = PrayerSemantics.statusMenuTrigger(
      l10n: l10n,
      status: status,
    );

    return FPopoverMenu(
      menu: [
        FItemGroup(
          children: CompletionStatus.values
              .where((v) => v != CompletionStatus.none)
              .map(
                (e) => FItem(
                  title: Text(e.getLocaleName(l10n)),
                  prefix: Icon(
                    e.getIcon(),
                    color: e.getBadgeColor(theme.colors),
                  ),
                  onPress: () async {
                    await ref
                        .read(prayerCompletionActionsProvider.notifier)
                        .setPrayerStatus(
                          prayer: prayer,
                          completionDay: completionDay,
                          status: e,
                        );
                  },
                ),
              )
              .toList(),
        ),
      ],
      builder: (context, controller, _) {
        final isSet = status != CompletionStatus.none;
        return MouseClick(
          semanticsLabel: menuTriggerLabel,
          onClick: controller.toggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isSet
                  ? theme.colors.secondary
                  : theme.colors.background.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSet
                    ? theme.colors.secondary
                    : theme.colors.border.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSet) ...[
                  Icon(
                    status.getIcon(),
                    color: theme.colors.secondaryForeground,
                    size: theme.typography.body.md.fontSize,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      status.getLocaleName(l10n),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.typography.body.sm.copyWith(
                        color: theme.colors.secondaryForeground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    FLucideIcons.chevronDown,
                    color: theme.colors.secondaryForeground,
                    size: theme.typography.body.sm.fontSize,
                  ),
                ] else ...[
                  Text(
                    l10n.logPrayerStatus,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.typography.body.sm.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
