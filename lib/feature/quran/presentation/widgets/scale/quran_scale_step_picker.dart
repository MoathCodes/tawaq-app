import 'package:flutter/material.dart';
import 'package:tawaq/core/widgets/scale_step_picker.dart';
import 'package:tawaq/feature/quran/presentation/widgets/quran_semantics.dart';

/// Quran text scale step buttons with per-option accessibility labels.
class QuranScaleStepPicker extends StatelessWidget {
  /// Creates a [QuranScaleStepPicker].
  const QuranScaleStepPicker({
    required this.groupLabel,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    super.key,
  });

  /// Setting name announced with each option (e.g. "Quran text size").
  final String groupLabel;

  /// Labels for each step.
  final List<String> labels;

  /// Currently selected step index.
  final int selectedIndex;

  /// Called when the user selects a different step.
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return ScaleStepPicker(
      labels: labels,
      selectedIndex: selectedIndex,
      onChanged: onChanged,
      wrapStep: (index, step) => QuranSemantics.labeledControl(
        name: groupLabel,
        value: labels[index],
        button: true,
        selected: selectedIndex == index,
        excludeChild: true,
        child: step,
      ),
    );
  }
}
