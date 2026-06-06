import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/theme/theme.dart';

/// Uniform step buttons for discrete scale presets (no selected-tab typography jump).
class ScaleStepPicker extends StatelessWidget {
  /// Creates a [ScaleStepPicker].
  const ScaleStepPicker({
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    this.enabled = true,
    this.wrapStep,
    super.key,
  });

  /// Labels for each step (same visual weight for every option).
  final List<String> labels;

  /// Currently selected step index.
  final int selectedIndex;

  /// Called when the user selects a different step.
  final ValueChanged<int> onChanged;

  /// Whether steps can be selected.
  final bool enabled;

  /// Optional wrapper for each step (e.g. accessibility semantics).
  final Widget Function(int index, Widget step)? wrapStep;

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final labelStyle = theme.typography.xs.copyWith(
      fontWeight: FontWeight.w600,
      height: 1.2,
    );

    return NonSelectable(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: wrapStep?.call(
                    i,
                    _stepButton(
                      label: labels[i],
                      labelStyle: labelStyle,
                      selected: selectedIndex == i,
                      onPress: enabled ? () => onChanged(i) : null,
                    ),
                  ) ??
                  _stepButton(
                    label: labels[i],
                    labelStyle: labelStyle,
                    selected: selectedIndex == i,
                    onPress: enabled ? () => onChanged(i) : null,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _stepButton({
    required String label,
    required TextStyle labelStyle,
    required bool selected,
    required VoidCallback? onPress,
  }) {
    return FButton(
      variant: selected ? .primary : .outline,
      selected: selected,
      onPress: onPress,
      style: const FButtonStyleDelta.delta(
        contentStyle: FButtonContentStyleDelta.delta(
          padding: EdgeInsetsGeometryDelta.value(
            EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 10,
            ),
          ),
        ),
      ),
      child: Text(
        label,
        style: labelStyle,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
