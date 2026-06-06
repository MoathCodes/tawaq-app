import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/utils/scaled_screen_util.dart';
import 'package:tawaq/core/widgets/mouse_click.dart';
import 'package:tawaq/feature/prayer/data/models/prayer_completion.dart';
import 'package:tawaq/feature/prayer/presentation/extensions/completion_status_ui.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_completion_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_data_providers.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/prayer_semantics.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/theme/theme.dart';

/// Button that lets the user log a prayer's completion status via a popover.
class StatusSelectorButton extends ConsumerWidget {
  /// Creates a [StatusSelectorButton].
  const StatusSelectorButton({
    required this.prayer,
    required this.canSetStatus,
    super.key,
  });

  /// The prayer to set status for.
  final Prayer prayer;

  /// Whether the user is allowed to set the status (prayer time has passed).
  final bool canSetStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appScale = ref.watch(appTextScaleFactorProvider);
    final theme = FTheme.of(context);
    final l10n = context.l10n;
    final now = ref.watch(currentLocationTimeProvider);
    final completionDay = DateTime(now.year, now.month, now.day);
    final status = ref.watch(
      prayerCompletionProvider.select(
        (value) => value.value
            ?.firstWhere(
              (c) => c.prayer == prayer,
              orElse: () => PrayerCompletion(
                prayer: prayer,
                status: CompletionStatus.none,
                completionTime: completionDay,
                id: null,
              ),
            )
            .status,
      ),
    );

    final menuTriggerLabel = PrayerSemantics.statusMenuTrigger(
      l10n: l10n,
      status: status,
    );

    return canSetStatus
        ? FPopoverMenu(
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
                              .read(prayerCompletionProvider.notifier)
                              .addOrUpdateCompletion(
                                PrayerCompletion(
                                  id: null,
                                  status: e,
                                  prayer: prayer,
                                  completionTime: completionDay,
                                ),
                              );
                        },
                      ),
                    )
                    .toList(),
              ),
            ],
            builder: (context, controller, _) {
              final isSet = status != CompletionStatus.none && status != null;
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
                          size: scaledSp(16, appScale),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          status.getLocaleName(l10n),
                          style: TextStyle(
                            color: theme.colors.secondaryForeground,
                            fontWeight: FontWeight.w700,
                            fontSize: scaledSp(14, appScale),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Icon(
                          FLucideIcons.chevronDown,
                          color: theme.colors.secondaryForeground,
                          size: scaledSp(14, appScale),
                        ),
                      ] else ...[
                        Text(
                          l10n.logPrayerStatus,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: scaledSp(14, appScale),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          )
        : const SizedBox.shrink();
  }
}
