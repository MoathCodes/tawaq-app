import 'package:flutter/material.dart';

/// Directional slide transition for paginated reading content (RTL-aware).
///
/// [slideDirection] `1` = backward (previous), `-1` = forward (next).
/// Only the incoming child is shown during the transition to avoid overlap.
class DirectionalContentSwitcher extends StatelessWidget {
  /// Creates a switcher.
  const new({
    required this.currentKey,
    required this.slideDirection,
    required this.child,
    super.key,
  });

  /// Active item key (drives [ValueKey]).
  final Object? currentKey;

  /// `1` for previous, `-1` for next.
  final int slideDirection;

  /// Content for the active item.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeIn,
      layoutBuilder: (currentChild, previousChildren) {
        return currentChild ?? const SizedBox.shrink();
      },
      transitionBuilder: (child, animation) {
        final isIncoming = child.key == ValueKey<Object?>(currentKey);
        if (!isIncoming) {
          return const ExcludeSemantics(child: SizedBox.shrink());
        }

        final dir = slideDirection.toDouble();
        final slide = animation.drive(
          Tween<Offset>(
            begin: Offset(dir * 0.18, 0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOutCubic)),
        );

        final opacity = animation.drive(
          Tween<double>(begin: 0, end: 1).chain(
            CurveTween(
              curve: const Interval(0.15, 1, curve: Curves.easeOut),
            ),
          ),
        );

        return ClipRect(
          child: SlideTransition(
            position: slide,
            child: FadeTransition(
              opacity: opacity,
              child: child,
            ),
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey<Object?>(currentKey),
        child: child,
      ),
    );
  }
}
