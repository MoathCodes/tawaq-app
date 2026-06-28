import 'package:flutter/material.dart';

/// Inherited scope for Hadith screen layout mode (split vs stacked).
class HadithLayoutScope extends InheritedWidget {
  /// Creates a layout scope for the Hadith page subtree.
  const HadithLayoutScope({
    required this.useSplitLayout,
    required super.child,
    super.key,
  });

  /// Whether filters and details use the horizontal side panel.
  final bool useSplitLayout;

  /// Returns whether the current subtree uses horizontal split layout.
  static bool of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<HadithLayoutScope>();
    assert(
      scope != null,
      'HadithLayoutScope not found in widget tree',
    );
    return scope!.useSplitLayout;
  }

  @override
  bool updateShouldNotify(HadithLayoutScope oldWidget) {
    return oldWidget.useSplitLayout != useSplitLayout;
  }
}
