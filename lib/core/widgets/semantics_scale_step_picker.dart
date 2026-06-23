import 'package:flutter/material.dart';
import 'package:tawaq/core/a11y/a11y.dart';
import 'package:tawaq/core/widgets/scale_step_picker.dart';

/// [ScaleStepPicker] with per-step accessibility labels.
class SemanticsScaleStepPicker extends StatelessWidget {
  /// Creates a [SemanticsScaleStepPicker].
  const SemanticsScaleStepPicker({
    required this.groupLabel,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    this.enabled = true,
    this.previewSizes,
    super.key,
  });

  /// Setting name announced with each option (e.g. "App text size").
  final String groupLabel;

  /// Labels for each step.
  final List<String> labels;

  /// Currently selected step index.
  final int selectedIndex;

  /// Called when the user selects a different step.
  final ValueChanged<int> onChanged;

  /// Whether steps can be selected.
  final bool enabled;

  /// Optional per-step preview font sizes for the chip “Aa” sample.
  final List<double>? previewSizes;

  @override
  Widget build(BuildContext context) {
    return ScaleStepPicker(
      labels: labels,
      selectedIndex: selectedIndex,
      onChanged: onChanged,
      enabled: enabled,
      previewSizes: previewSizes,
      wrapStep: (index, step) => SemanticsWrappers.labeledControl(
        label: groupLabel,
        value: labels[index],
        button: true,
        selected: selectedIndex == index,
        enabled: enabled,
        excludeChild: true,
        onTap: enabled ? () => onChanged(index) : null,
        child: step,
      ),
    );
  }
}
