import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/utils/scaled_screen_util.dart';
import 'package:tawaq/core/widgets/mouse_click.dart';
import 'package:tawaq/feature/prayer/data/models/prayer_completion.dart';
import 'package:tawaq/feature/prayer/presentation/extensions/completion_status_ui.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/prayer_semantics.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/theme/theme.dart';

/// Expandable status selector showing all completion status options.
class StatusSelector extends ConsumerWidget {
  /// Creates a [StatusSelector].
  const StatusSelector({
    required this.prayer,
    required this.currentStatus,
    required this.completionTime,
    required this.enable,
    required this.onStatusSelected,
    super.key,
  });

  /// The prayer this selector is for.
  final Prayer prayer;

  /// The currently selected status.
  final CompletionStatus currentStatus;

  /// The completion time for the prayer.
  final DateTime completionTime;

  /// Whether selection is enabled (prayer time has passed).
  final bool enable;

  /// Callback when a status is selected.
  final void Function(CompletionStatus status) onStatusSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FTheme.of(context);
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.logPrayerStatus.toUpperCase(),
              style: theme.typography.xs.copyWith(
                color: theme.colors.mutedForeground,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: CompletionStatus.values
                .where((s) => s != CompletionStatus.none)
                .map(
                  (status) => StatusButton(
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

/// A single status option button inside the [StatusSelector].
class StatusButton extends ConsumerWidget {
  /// Creates a [StatusButton].
  const StatusButton({
    required this.status,
    required this.isSelected,
    required this.onPressed,
    required this.enable,
    super.key,
  });

  /// The completion status this button represents.
  final CompletionStatus status;

  /// Whether this button is currently selected.
  final bool isSelected;

  /// Callback when the button is pressed.
  final VoidCallback onPressed;

  /// Whether the button is enabled.
  final bool enable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appScale = ref.watch(appTextScaleFactorProvider);
    final theme = FTheme.of(context);
    final colors = theme.colors;

    return Semantics(
      button: true,
      enabled: enable,
      selected: isSelected,
      label: PrayerSemantics.statusOption(
        l10n: context.l10n,
        status: status,
        enabled: enable,
      ),
      excludeSemantics: true,
      child: MouseClick(
        disabled: !enable,
        onClick: enable ? onPressed : null,
        child: Opacity(
          opacity: enable ? 1.0 : 0.5,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? status.getBadgeColor(colors)
                  : colors.background,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    isSelected ? status.getBadgeColor(colors) : colors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  status.getIcon(),
                  color: isSelected ? colors.background : colors.foreground,
                  size: scaledSp(16, appScale),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  status.getLocaleName(context.l10n),
                  style: TextStyle(
                    color: isSelected ? colors.background : colors.foreground,
                    fontSize: scaledSp(12, appScale),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
