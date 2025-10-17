import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A widget that applies a staggered fade-in and slide-up animation to its child.
///
/// This widget is useful for creating a visually appealing entrance animation
/// for a list of items.
class AnimationEntry extends StatelessWidget {
  /// Creates an animation entry.
  const AnimationEntry(
      {required this.child, super.key,
      this.delay = Duration.zero,
      this.forceAnimation = false,});

  /// The widget to animate.
  final Widget child;

  /// The delay before the animation starts.
  final Duration delay;

  /// Whether to force the animation to play even if animations are disabled
  /// on the device.
  final bool forceAnimation;

  @override
  Widget build(BuildContext context) {
    final disableAnimation =
        forceAnimation && MediaQuery.of(context).disableAnimations;
    return disableAnimation
        ? child
        : RepaintBoundary(
            child: child
                .animate(delay: delay)
                .fadeIn(duration: 280.ms, curve: Curves.easeOut)
                .moveY(
                    begin: 20,
                    end: 0,
                    duration: 420.ms,
                    curve: Curves.easeOutCubic,)
                .then()
                .scale(
                  begin: const Offset(0.98, 0.98),
                  end: const Offset(1, 1),
                  duration: 200.ms,
                  curve: Curves.easeOutBack,
                ),
          );
  }
}