import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/widgets/mouse_click.dart';
import 'package:hasanat/feature/prayer/data/models/prayer_completion.dart';
import 'package:hasanat/feature/prayer/presentation/provider/prayer_completion_provider.dart';
import 'package:hasanat/theme/theme.dart';

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
    final status = ref.watch(
      prayerCompletionProvider.select(
        (value) => value.value
            ?.firstWhere(
              (c) => c.prayer == prayer,
              orElse: () => PrayerCompletion(
                prayer: prayer,
                status: CompletionStatus.none,
                completionTime: DateTime.now(),
                id: null,
              ),
            )
            .status,
      ),
    );

    return canSetStatus
        ? FPopoverMenu(
            menu: [
              FItemGroup(
                children: CompletionStatus.values
                    .where((v) => v != CompletionStatus.none)
                    .map(
                      (e) => FItem(
                        title: Text(e.getLocaleName(context.l10n)),
                        prefix: Icon(
                          e.getIcon(),
                          color: e.getBadgeColor(FTheme.of(context).colors),
                        ),
                        onPress: () async {
                          await ref
                              .read(prayerCompletionProvider.notifier)
                              .addOrUpdateCompletion(
                                PrayerCompletion(
                                  id: null,
                                  status: e,
                                  prayer: prayer,
                                  completionTime: DateTime.now(),
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
              final theme = FTheme.of(context);
              return MouseClick(
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
                  child: IntrinsicHeight(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSet) ...[
                          Icon(
                            status.getIcon(),
                            color: theme.colors.secondaryForeground,
                            size: 16.sp,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            status.getLocaleName(context.l10n),
                            style: TextStyle(
                              color: theme.colors.secondaryForeground,
                              fontWeight: FontWeight.w700,
                              fontSize: 14.sp,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Icon(
                            FIcons.chevronDown,
                            color: theme.colors.secondaryForeground,
                            size: 14.sp,
                          ),
                        ] else ...[
                          Text(
                            context.l10n.logPrayerStatus,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          )
        : const SizedBox.shrink();
  }
}
