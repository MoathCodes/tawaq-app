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
import 'package:hasanat/feature/prayer/presentation/provider/prayer_completion_provider.dart';
import 'package:hasanat/feature/prayer/presentation/provider/prayer_data_providers.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hasanat/theme/theme.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// A single prayer row in the schedule list with expandable status selector.
class SchedulePrayerRow extends HookConsumerWidget {
  /// Creates a [SchedulePrayerRow] instance.
  const SchedulePrayerRow({
    required this.prayer,
    required this.adhanTime,
    required this.prayerTime,
    required this.isActive,
    required this.isCompleted,
    required this.currentStatus,
    required this.completionTime,
    super.key,
  });

  /// The prayer this row represents.
  final Prayer prayer;

  /// Formatted adhan time string.
  final String adhanTime;

  /// The actual DateTime for this prayer (for relative time calculation).
  final DateTime prayerTime;

  /// Whether this is the currently active prayer.
  final bool isActive;

  /// Whether this prayer has been completed.
  final bool isCompleted;

  /// Current completion status.
  final CompletionStatus currentStatus;

  /// The date for this prayer completion.
  final DateTime completionTime;

  static const _animDuration = Duration(milliseconds: 260);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpanded = useState(isActive);
    final theme = FTheme.of(context);
    final colors = theme.colors;

    return MouseClick(
      onClick: () => isExpanded.value = !isExpanded.value,
      child: AnimatedContainer(
        duration: _animDuration,
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isActive
              ? colors.primary.withValues(alpha: 0.2)
              : colors.foreground.withValues(alpha: 0.1),
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
            _MainRowContent(
              prayer: prayer,
              adhanTime: adhanTime,
              prayerTime: prayerTime,
              isActive: isActive,
              currentStatus: currentStatus,
              colors: colors,
              theme: theme,
            ),
            // Expandable status selector
            AnimatedSize(
              duration: _animDuration,
              curve: Curves.easeInOut,
              child: isExpanded.value
                  ? _StatusSelector(
                      prayer: prayer,
                      currentStatus: currentStatus,
                      completionTime: completionTime,
                      onStatusSelected: (status) {
                        ref
                            .read(prayerCompletionProvider.notifier)
                            .addOrUpdateCompletion(
                              PrayerCompletion(
                                id: null,
                                status: status,
                                prayer: prayer,
                                completionTime: completionTime,
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

class _MainRowContent extends ConsumerWidget {
  const _MainRowContent({
    required this.prayer,
    required this.adhanTime,
    required this.prayerTime,
    required this.isActive,
    required this.currentStatus,
    required this.colors,
    required this.theme,
  });

  final Prayer prayer;
  final String adhanTime;
  final DateTime prayerTime;
  final bool isActive;
  final CompletionStatus currentStatus;
  final FColors colors;
  final FThemeData theme;

  /// Computes the relative time subtitle for this prayer.
  // No need to pass prayerTime here as we use the local variable derived from it
  String _computeSubtitle(
    BuildContext context,
    DateTime now,
    DateTime localPrayerTime,
  ) {
    if (isActive) {
      return context.l10n.nowActive;
    }

    final difference = now.difference(localPrayerTime).abs();
    final hours = difference.inHours;
    final minutes = difference.inMinutes;
    final isPast = now.isAfter(localPrayerTime);

    if (currentStatus != CompletionStatus.none) {
      // Completed - show time since completion
      final timeAgo = hours > 0
          ? context.l10n.adhanHoursAgo(hours)
          : context.l10n.adhanMinsAgo(minutes);
      return '${context.l10n.completed} - $timeAgo';
    }

    // Not completed - show remaining or elapsed time
    if (isPast) {
      return hours > 0
          ? context.l10n.adhanHoursAgo(hours)
          : context.l10n.adhanMinsAgo(minutes);
    }

    return hours > 0
        ? context.l10n.adhanHoursLeft(hours)
        : context.l10n.adhanMinsLeft(minutes);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch location from settings to ensure correct timezone conversion
    final location = ref.watch(
      prayerSettingsProvider.select((s) => s.value?.location),
    );
    final now = ref.watch(currentLocationTimeProvider);

    // Ensure prayer time is in the correct timezone before diffing
    final localPrayerTime = location != null
        ? prayerTime.toLocation(location)
        : prayerTime;

    final subtitle = _computeSubtitle(context, now, localPrayerTime);

    return Row(
      children: [
        // Prayer icon
        _PrayerIcon(prayer: prayer, isActive: isActive, colors: colors),
        const SizedBox(width: AppSpacing.md),
        // Prayer name and status
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    prayer.getLocaleName(context.l10n),
                    style: theme.typography.lg.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (currentStatus != CompletionStatus.none) ...[
                    const SizedBox(width: AppSpacing.sm),
                    _StatusBadge(status: currentStatus),
                  ],
                ],
              ),
              Text(
                subtitle,
                style: theme.typography.sm.copyWith(
                  color: isActive ? colors.primary : colors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
        // Time display
        Text(
          adhanTime,
          style: theme.typography.xl.copyWith(
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        // Notification bell (placeholder)
        IconButton(
          onPressed: () {
            // TODO(notifications): Implement notification toggle
          },
          icon: Icon(
            FIcons.bell,
            color: colors.mutedForeground,
            size: 20.sp,
          ),
        ),
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
          color: isActive ? Colors.white : colors.foreground,
          size: 24.sp,
        ),
      ),
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
    required this.onStatusSelected,
  });

  final Prayer prayer;
  final CompletionStatus currentStatus;
  final DateTime completionTime;
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
  });

  final CompletionStatus status;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final colors = theme.colors;

    return MouseClick(
      onClick: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? status.getBadgeColor() : colors.secondary,
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
    );
  }
}
