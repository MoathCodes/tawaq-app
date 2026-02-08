import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/utils/prayer_extensions.dart';
import 'package:hasanat/core/widgets/mouse_click.dart';
import 'package:hasanat/feature/prayer/data/models/prayer_completion.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_schedule_row.dart';
import 'package:hasanat/feature/prayer/presentation/provider/prayer_completion_provider.dart';
import 'package:hasanat/feature/prayer/presentation/widgets/schedule_row/notification_button.dart';
import 'package:hasanat/feature/prayer/presentation/widgets/schedule_row/prayer_icon.dart';
import 'package:hasanat/feature/prayer/presentation/widgets/schedule_row/status_badge.dart';
import 'package:hasanat/feature/prayer/presentation/widgets/schedule_row/status_selector.dart';
import 'package:hasanat/feature/prayer/presentation/widgets/schedule_row/time_column.dart';
import 'package:hasanat/theme/theme.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// A single prayer row in the schedule list with expandable status selector.
class SchedulePrayerRow extends ConsumerWidget {
  /// Creates a [SchedulePrayerRow] instance.
  const SchedulePrayerRow({
    required this.row,
    required this.isExpanded,
    required this.onToggle,
    super.key,
  });

  /// The prayer schedule row data.
  final PrayerScheduleRow row;

  /// Whether this row is expanded.
  final bool isExpanded;

  /// Callback to toggle expansion.
  final VoidCallback onToggle;

  static const _animDuration = Duration(milliseconds: 260);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FTheme.of(context);
    final colors = theme.colors;
    final isActive = row.isCurrentPrayer;
    final canLogStatus = row.prayerTime.isBefore(DateTime.now());

    return MouseClick(
      disabled: false,
      onClick: onToggle,
      child: AnimatedContainer(
        duration: _animDuration,
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isActive
              ? colors.primary.withValues(alpha: 0.2)
              : colors.secondary,
          border: Border.all(
            color: isActive ? colors.primary : colors.border,
            width: isActive ? 2 : 1,
          ),
          borderRadius: context.theme.radii.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main row content
            _MainRowContent(row: row, theme: theme, colors: colors),
            // Expandable status selector
            AnimatedSize(
              duration: _animDuration,
              curve: Curves.easeInOut,
              child: isExpanded
                  ? StatusSelector(
                      prayer: row.prayer,
                      enable: canLogStatus,
                      currentStatus: row.completionStatus,
                      completionTime: row.completionDate ?? DateTime.now(),
                      onStatusSelected: (status) {
                        ref
                            .read(prayerCompletionProvider.notifier)
                            .addOrUpdateCompletion(
                              PrayerCompletion(
                                id: null,
                                status: status,
                                prayer: row.prayer,
                                completionTime:
                                    row.completionDate ?? DateTime.now(),
                              ),
                            );
                      },
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MainRowContent extends StatelessWidget {
  const _MainRowContent({
    required this.row,
    required this.theme,
    required this.colors,
  });

  final PrayerScheduleRow row;
  final FThemeData theme;
  final FColors colors;

  @override
  Widget build(BuildContext context) {
    final isActive = row.isCurrentPrayer;
    final status = row.completionStatus;

    return Row(
      children: [
        // Prayer icon
        PrayerIcon(prayer: row.prayer, isActive: isActive, colors: colors),
        const SizedBox(width: AppSpacing.md),
        // Prayer name and status
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    row.prayer.getLocaleName(context.l10n),
                    style: theme.typography.lg.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (status != CompletionStatus.none) ...[
                    const SizedBox(width: AppSpacing.sm),
                    StatusBadge(status: status),
                  ],
                ],
              ),
              if (row.relativeTimeSubtitle != null)
                Text(
                  row.relativeTimeSubtitle!,
                  style: theme.typography.sm.copyWith(
                    color: isActive ? colors.primary : colors.mutedForeground,
                  ),
                ),
            ],
          ),
        ),
        // Time display
        Row(
          children: [
            if (row.formattedIqamahTime != null) ...[
              // Iqamah time column
              TimeColumn(
                label: context.l10n.iqamah.toUpperCase(),
                time: row.formattedIqamahTime!,
                theme: theme,
                colors: colors,
              ),
            ],
            const SizedBox(width: AppSpacing.lg),
            // Adhan time column
            TimeColumn(
              label: context.l10n.adhan.toUpperCase(),
              time: row.formattedAdhanTime,
              theme: theme,
              colors: colors,
            ),
          ],
        ),
        const SizedBox(width: AppSpacing.md),
        // Notification bell
        NotificationButton(colors: colors),
      ],
    );
  }
}
