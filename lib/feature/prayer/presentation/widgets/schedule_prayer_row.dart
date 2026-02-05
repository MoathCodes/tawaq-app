import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/utils/prayer_extensions.dart';
import 'package:hasanat/core/widgets/mouse_click.dart';
import 'package:hasanat/feature/prayer/data/models/prayer_completion.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_images.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_schedule_row.dart';
import 'package:hasanat/feature/prayer/presentation/provider/prayer_completion_provider.dart';
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
                  ? _StatusSelector(
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
        _PrayerIcon(prayer: row.prayer, isActive: isActive, colors: colors),
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
                    _StatusBadge(status: status),
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
              _TimeColumn(
                label: context.l10n.iqamah.toUpperCase(),
                time: row.formattedIqamahTime!,
                theme: theme,
                colors: colors,
              ),
            ],
            const SizedBox(width: AppSpacing.lg),
            // Adhan time column
            _TimeColumn(
              label: context.l10n.adhan.toUpperCase(),
              time: row.formattedAdhanTime,
              theme: theme,
              colors: colors,
            ),
          ],
        ),
        const SizedBox(width: AppSpacing.md),
        // Notification bell
        _NotificationButton(colors: colors),
      ],
    );
  }
}

class _PrayerIcon extends StatelessWidget {
  const _PrayerIcon({
    required this.prayer,
    required this.isActive,
    required this.colors,
  });

  final Prayer prayer;
  final bool isActive;
  final FColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44.w,
      height: 44.w,
      decoration: BoxDecoration(
        color: isActive ? colors.primary : colors.secondary,
        borderRadius: context.theme.radii.md,
      ),
      child: Center(
        child: Icon(
          prayer.icon,
          color: isActive
              ? colors.primaryForeground
              : colors.secondaryForeground,
          size: 24.sp,
        ),
      ),
    );
  }
}

/// Displays a time column with label (e.g., "ADHAN" / "IQAMAH") and time value.
class _TimeColumn extends StatelessWidget {
  const _TimeColumn({
    required this.label,
    required this.time,
    required this.theme,
    required this.colors,
  });

  final String label;
  final String time;
  final FThemeData theme;
  final FColors colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label (ADHAN / IQAMAH)
        Text(
          label,
          style: theme.typography.xs.copyWith(
            color: colors.mutedForeground,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        // Time value
        Text(
          time,
          style: theme.typography.sm.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.foreground,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// Notification bell button for prayer reminders.
class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.colors});

  final FColors colors;

  @override
  Widget build(BuildContext context) {
    return HookBuilder(
      builder: (context) {
        final isEnabled = useState(true);
        return FButton.icon(
          style: isEnabled.value
              ? FButtonStyle.primary()
              : FButtonStyle.secondary(),
          onPress: () {
            isEnabled.value = !isEnabled.value;
          },
          child: Icon(
            isEnabled.value ? FIcons.bell : FIcons.bellOff,
            size: 20.sp,
          ),
        );
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final CompletionStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: status.getBadgeColor().withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.getLocaleName(context.l10n),
        style: TextStyle(
          color: status.getBadgeColor(),
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatusSelector extends StatelessWidget {
  const _StatusSelector({
    required this.prayer,
    required this.currentStatus,
    required this.completionTime,
    required this.enable,
    required this.onStatusSelected,
  });

  final Prayer prayer;
  final CompletionStatus currentStatus;
  final DateTime completionTime;
  final bool enable;
  final void Function(CompletionStatus status) onStatusSelected;

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.logPrayerStatus.toUpperCase(),
            style: theme.typography.xs.copyWith(
              color: theme.colors.mutedForeground,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: CompletionStatus.values
                .where((s) => s != CompletionStatus.none)
                .map(
                  (status) => _StatusButton(
                    status: status,
                    isSelected: status == currentStatus,
                    onPressed: () => onStatusSelected(status),
                    enable: enable,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  const _StatusButton({
    required this.status,
    required this.isSelected,
    required this.onPressed,
    required this.enable,
  });

  final CompletionStatus status;
  final bool isSelected;
  final VoidCallback onPressed;
  final bool enable;

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final colors = theme.colors;

    return MouseClick(
      disabled: !enable,
      onClick: onPressed,
      child: Opacity(
        opacity: enable ? 1.0 : 0.5,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isSelected ? status.getBadgeColor() : colors.background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? status.getBadgeColor() : colors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                status.getIcon(),
                color: isSelected ? Colors.white : colors.foreground,
                size: 16.sp,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                status.getLocaleName(context.l10n),
                style: TextStyle(
                  color: isSelected ? Colors.white : colors.foreground,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
