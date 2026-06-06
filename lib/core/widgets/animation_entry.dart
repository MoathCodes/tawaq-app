import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Total time for [AnimationEntry]'s fade, move, and scale effects after [delay].
const Duration kAnimationEntryEffectDuration = Duration(milliseconds: 620);

/// A widget that applies a staggered fade-in and
/// slide-up animation to its child.
///
/// This widget is useful for creating a visually appealing entrance animation
/// for a list of items.
class AnimationEntry extends StatefulWidget {
  /// Creates an animation entry.
  const AnimationEntry({
    required this.child,
    super.key,
    this.delay = Duration.zero,
    this.forceAnimation = false,
    this.animateOnce = false,
    this.onEntranceComplete,
  });

  /// The widget to animate.
  final Widget child;

  /// The delay before the animation starts.
  final Duration delay;

  /// Whether to force the animation to play even if animations are disabled
  /// on the device.
  final bool forceAnimation;

  /// When true, the entrance animation runs only once for this [State] object.
  ///
  /// Pair with a stable [Key] (e.g. [ValueKey] on an id) in lists so rebuilds
  /// do not replay the animation.
  final bool animateOnce;

  /// Called once when [animateOnce] finishes (after all effects complete).
  final VoidCallback? onEntranceComplete;

  @override
  State<AnimationEntry> createState() => _AnimationEntryState();
}

class _AnimationEntryState extends State<AnimationEntry> {
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    if (widget.animateOnce) {
      Future<void>.delayed(
        widget.delay + kAnimationEntryEffectDuration,
        () {
          if (!mounted) return;
          setState(() => _finished = true);
          widget.onEntranceComplete?.call();
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.animateOnce && _finished) {
      return widget.child;
    }

    final disableAnimation =
        widget.forceAnimation && MediaQuery.of(context).disableAnimations;
    return disableAnimation
        ? widget.child
        : RepaintBoundary(
            child: widget.child
                .animate(delay: widget.delay)
                .fadeIn(duration: 280.ms, curve: Curves.easeOut)
                .moveY(
                  begin: 20,
                  end: 0,
                  duration: 420.ms,
                  curve: Curves.easeOutCubic,
                )
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
