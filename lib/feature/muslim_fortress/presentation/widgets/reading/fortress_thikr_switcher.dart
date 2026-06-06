import 'package:flutter/material.dart';
import 'package:tawaq/core/widgets/directional_content_switcher.dart';

export 'package:tawaq/core/widgets/directional_content_switcher.dart'
    show DirectionalContentSwitcher;

/// Directional slide transition for thikr navigation (RTL-aware).
///
/// [slideDirection] `1` = backward (previous), `-1` = forward (next, Arabic page).
/// Only the incoming thikr is shown during the transition to avoid overlapping text.
class FortressThikrSwitcher extends StatelessWidget {
  /// Creates a switcher.
  const FortressThikrSwitcher({
    required this.currentIndex,
    required this.slideDirection,
    required this.child,
    super.key,
  });

  /// Active thikr index (drives [ValueKey]).
  final int currentIndex;

  /// `1` for previous, `-1` for next (Arabic page-turn).
  final int slideDirection;

  /// Content for the active thikr.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DirectionalContentSwitcher(
      currentKey: currentIndex,
      slideDirection: slideDirection,
      child: child,
    );
  }
}
