import 'dart:async';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/mouse_click.dart';
import 'package:tawaq/feature/prayer/data/models/prayer_completion.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_schedule_row.dart';
import 'package:tawaq/feature/prayer/domain/prayer_extensions.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_completion_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_data_providers.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_schedule/prayer_schedule_provider.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/prayer_semantics.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/schedule_row/notification_button.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/schedule_row/prayer_icon.dart' show PrayerIcon;
import 'package:tawaq/feature/prayer/presentation/widgets/schedule_row/prayer_relative_time.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/schedule_row/status_badge.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/schedule_row/status_selector.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/schedule_row/time_column.dart';
import 'package:tawaq/theme/theme.dart';

/// A single prayer row in the schedule list with expandable status selector.
class SchedulePrayerRow extends ConsumerWidget {
  /// Creates a [SchedulePrayerRow] instance.
  const SchedulePrayerRow({
    required this.row,
    required this.isExpanded,
    required this.isToday,
    required this.onToggle,
    super.key,
  });

  /// The prayer schedule row data.
  final PrayerScheduleRow row;

  /// Whether this row is expanded.
  final bool isExpanded;

  /// Whether the schedule is showing today (live clock + active prayer).
  final bool isToday;

  /// Callback to toggle expansion.
  final VoidCallback onToggle;

  static const _animDuration = Duration(milliseconds: 260);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FTheme.of(context);
    final colors = theme.colors;
    final l10n = context.l10n;
    final currentPrayer = isToday ? ref.watch(scheduleCurrentPrayerProvider) : null;
    final isActive =
        currentPrayer != null &&
        isScheduleRowCurrent(
          rowPrayer: row.prayer,
          currentPrayer: currentPrayer,
        );
    final now = ref.watch(currentLocationTimeProvider);
    final canLogStatus = row.prayerTime.isBefore(now);

    return _SchedulePrayerRowBody(
      row: row,
      theme: theme,
      colors: colors,
      isExpanded: isExpanded,
      isToday: isToday,
      isActive: isActive,
      canLogStatus: canLogStatus,
      onToggle: onToggle,
      rowSemanticsLabel: PrayerSemantics.scheduleRow(
        l10n: l10n,
        prayerName: row.prayer.getLocaleName(l10n),
        adhanTime: row.formattedAdhanTime,
        iqamahTime: row.formattedIqamahTime,
        relativeSubtitle: row.relativeTimeSubtitle,
        status: row.completionStatus,
        isCurrentPrayer: isActive,
        isExpanded: isExpanded,
      ),
    );
  }
}

class _SchedulePrayerRowBody extends ConsumerWidget {
  const _SchedulePrayerRowBody({
    required this.row,
    required this.theme,
    required this.colors,
    required this.isExpanded,
    required this.isToday,
    required this.isActive,
    required this.canLogStatus,
    required this.onToggle,
    required this.rowSemanticsLabel,
  });

  final PrayerScheduleRow row;
  final FThemeData theme;
  final FColors colors;
  final bool isExpanded;
  final bool isToday;
  final bool isActive;
  final bool canLogStatus;
  final VoidCallback onToggle;
  final String rowSemanticsLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(currentLocationTimeProvider);
    final completionFallback = DateTime(now.year, now.month, now.day);

    return AnimatedContainer(
      duration: SchedulePrayerRow._animDuration,
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
        borderRadius: theme.radii.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Semantics(
                  button: true,
                  expanded: isExpanded,
                  label: rowSemanticsLabel,
                  excludeSemantics: true,
                  child: MouseClick(
                    onClick: onToggle,
                    child: _MainRowContent(
                      row: row,
                      theme: theme,
                      colors: colors,
                      isActive: isActive,
                      isToday: isToday,
                    ),
                  ),
                ),
              ),
              NotificationButton(
                prayerName: row.prayer.getLocaleName(context.l10n),
              ),
            ],
          ),
          AnimatedSize(
            duration: SchedulePrayerRow._animDuration,
            curve: Curves.easeInOut,
            child: isExpanded
                ? StatusSelector(
                    prayer: row.prayer,
                    enable: canLogStatus,
                    currentStatus: row.completionStatus,
                    completionTime: row.completionDate ?? completionFallback,
                    onStatusSelected: (status) {
                      unawaited(
                        ref
                            .read(prayerCompletionProvider.notifier)
                            .addOrUpdateCompletion(
                              PrayerCompletion(
                                id: null,
                                status: status,
                                prayer: row.prayer,
                                completionTime:
                                    row.completionDate ?? completionFallback,
                              ),
                            ),
                      );
                    },
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _MainRowContent extends StatelessWidget {
  const _MainRowContent({
    required this.row,
    required this.theme,
    required this.colors,
    required this.isActive,
    required this.isToday,
  });

  final PrayerScheduleRow row;
  final FThemeData theme;
  final FColors colors;
  final bool isActive;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final status = row.completionStatus;

    return Row(
      children: [
        PrayerIcon(prayer: row.prayer, isActive: isActive, colors: colors),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    row.prayer.getLocaleName(l10n),
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
              PrayerRelativeTimeSubtitle(
                prayerTime: row.prayerTime,
                status: status,
                isToday: isToday,
                isCurrentPrayer: isActive,
              ),
            ],
          ),
        ),
        Row(
          children: [
            if (row.formattedIqamahTime != null) ...[
              TimeColumn(
                label: l10n.iqamah.toUpperCase(),
                time: row.formattedIqamahTime!,
                theme: theme,
                colors: colors,
              ),
            ],
            const SizedBox(width: AppSpacing.lg),
            TimeColumn(
              label: l10n.adhan.toUpperCase(),
              time: row.formattedAdhanTime,
              theme: theme,
              colors: colors,
            ),
          ],
        ),
      ],
    );
  }
}
