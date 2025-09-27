import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AnimationEntry extends StatelessWidget {
  final Widget child;
  final Duration delay;
  final bool forceAnimation;
  const AnimationEntry(
      {super.key,
      required this.child,
      this.delay = Duration.zero,
      this.forceAnimation = false});

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
                    curve: Curves.easeOutCubic)
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
