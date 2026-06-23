import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/core/widgets/mouse_click.dart';
import 'package:tawaq/theme/theme.dart';

/// Default preview font sizes for the four standard scale steps.
const List<double> kDefaultScalePreviewSizes = <double>[12, 14, 16, 18];

/// Compact chip-style picker for discrete scale presets.
///
/// Renders options in a [Wrap] with optional typographic previews instead of
/// large block buttons.
class ScaleStepPicker extends StatelessWidget {
  /// Creates a [ScaleStepPicker].
  const ScaleStepPicker({
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    this.enabled = true,
    this.previewSizes = kDefaultScalePreviewSizes,
    this.wrapStep,
    super.key,
  });

  /// Labels for each step.
  final List<String> labels;

  /// Currently selected step index.
  final int selectedIndex;

  /// Called when the user selects a different step.
  final ValueChanged<int> onChanged;

  /// Whether steps can be selected.
  final bool enabled;

  /// Optional per-step preview sizes for the leading “Aa” sample.
  final List<double>? previewSizes;

  /// Optional wrapper for each step (e.g. accessibility semantics).
  final Widget Function(int index, Widget step)? wrapStep;

  @override
  Widget build(BuildContext context) {
    return NonSelectable(
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (var i = 0; i < labels.length; i++)
            _wrapStep(i, _ScaleStepChip(
              label: labels[i],
              selected: selectedIndex == i,
              enabled: enabled,
              previewSize: previewSizes != null && i < previewSizes!.length
                  ? previewSizes![i]
                  : null,
              onPress: enabled ? () => onChanged(i) : null,
            )),
        ],
      ),
    );
  }

  Widget _wrapStep(int index, Widget step) =>
      wrapStep?.call(index, step) ?? step;
}

class _ScaleStepChip extends StatelessWidget {
  const _ScaleStepChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onPress,
    this.previewSize,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback? onPress;
  final double? previewSize;

  static const _minWidth = 72.0;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final duration = theme.durations.fast;

    return MouseClick(
      disabled: !enabled,
      onClick: onPress,
      semanticsLabel: label,
      child: AnimatedContainer(
        duration: duration,
        constraints: const BoxConstraints(minWidth: _minWidth),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected
              ? colors.primary.withValues(alpha: 0.12)
              : colors.secondary,
          borderRadius: theme.radii.md,
          border: Border.all(
            color: selected
                ? colors.primary.withValues(alpha: 0.75)
                : colors.border.withValues(alpha: 0.65),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.xs,
          children: [
            if (previewSize != null)
              Text(
                'Aa',
                style: theme.typography.body.sm.copyWith(
                  fontSize: previewSize,
                  fontWeight: FontWeight.w600,
                  height: 1,
                  color: selected ? colors.primary : colors.foreground,
                ),
              ),
            Text(
              label,
              style: theme.typography.body.xs.copyWith(
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected
                    ? colors.foreground
                    : colors.mutedForeground,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
