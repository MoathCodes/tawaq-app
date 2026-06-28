import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/layout/responsive.dart';

/// Inherited study-panel width for density-aware child layout.
class StudyPanelWidthScope extends InheritedWidget {
  /// Creates a [StudyPanelWidthScope].
  const StudyPanelWidthScope({
    required this.width,
    required super.child,
    super.key,
  });

  /// Allocated width of the study panel content area.
  final double width;

  /// Returns whether the panel is narrower than the small breakpoint.
  static bool isNarrow(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<StudyPanelWidthScope>();
    if (scope != null) {
      return scope.width < FTheme.of(context).breakpoints.sm;
    }
    return isLessThan(context, FBreakpoint.sm);
  }

  @override
  bool updateShouldNotify(StudyPanelWidthScope oldWidget) {
    return oldWidget.width != width;
  }
}
