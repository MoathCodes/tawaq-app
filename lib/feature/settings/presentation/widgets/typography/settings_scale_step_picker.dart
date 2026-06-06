import 'package:flutter/material.dart';
import 'package:tawaq/core/widgets/scale_step_picker.dart';
import 'package:tawaq/feature/settings/presentation/widgets/settings_semantics.dart';

/// [ScaleStepPicker] with per-step button semantics for settings screens.
class SettingsScaleStepPicker extends StatelessWidget {
  /// Creates a [SettingsScaleStepPicker].
  const SettingsScaleStepPicker({
    required this.groupLabel,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    this.enabled = true,
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

  @override
  Widget build(BuildContext context) {
    return ScaleStepPicker(
      labels: labels,
      selectedIndex: selectedIndex,
      onChanged: onChanged,
      enabled: enabled,
      wrapStep: (index, step) => SettingsSemantics.labeledControl(
        name: groupLabel,
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
