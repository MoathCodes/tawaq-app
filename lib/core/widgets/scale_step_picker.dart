import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/theme/theme.dart';

/// Uniform step buttons for discrete scale presets.
///
/// Avoids a selected-tab typography jump.
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
    // final labelStyle = theme.typography.xs.copyWith(
    //   fontWeight: FontWeight.w600,
    //   height: 1.2,
    // );

    return LayoutBuilder(
      builder: (context, constraints) {
        final useGrid = constraints.maxWidth < context.theme.breakpoints.sm;

        return NonSelectable(
          child: useGrid ? _buildGrid(context) : _buildRow(),
        );
      },
    );
  }

  Widget _buildRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.xs,
      children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: _wrapStep(
              i,
              _stepButton(
                label: labels[i],
                selected: selectedIndex == i,
                onPress: enabled ? () => onChanged(i) : null,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGrid(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.xs,
        crossAxisSpacing: AppSpacing.xs,
        childAspectRatio: 2.8,
      ),
      itemCount: labels.length,
      itemBuilder: (context, i) => _wrapStep(
        i,
        _stepButton(
          label: labels[i],
          selected: selectedIndex == i,
          onPress: enabled ? () => onChanged(i) : null,
        ),
      ),
    );
  }

  Widget _wrapStep(int index, Widget step) =>
      wrapStep?.call(index, step) ?? step;

  Widget _stepButton({
    required String label,
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
        // style: labelStyle,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
