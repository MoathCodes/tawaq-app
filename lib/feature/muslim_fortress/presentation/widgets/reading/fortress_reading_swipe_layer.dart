import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/reading_swipe_viewport.dart';

export 'package:tawaq/core/widgets/reading_swipe_viewport.dart'
    show ReadingSwipeViewport;

/// Fortress focus-reading viewport (mushaf-style page-turn swipes).
class FortressReadingViewport extends HookWidget {
  /// Creates a reading viewport.
  const FortressReadingViewport({
    required this.viewportMinHeight,
    required this.horizontalPadding,
    required this.topPadding,
    required this.bottomPadding,
    required this.child,
    required this.canGoNext,
    required this.canGoPrevious,
    required this.onNext,
    required this.onPrevious,
    this.onTapDown,
    super.key,
  });

  /// Minimum scroll extent height (typically the visible pane height).
  final double viewportMinHeight;

  final double horizontalPadding;
  final double topPadding;
  final double bottomPadding;

  /// Centered thikr (already width-constrained by parent).
  final Widget child;

  final bool canGoNext;
  final bool canGoPrevious;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final void Function(Offset localPosition)? onTapDown;

  @override
  Widget build(BuildContext context) {
    return ReadingSwipeViewport(
      viewportMinHeight: viewportMinHeight,
      horizontalPadding: horizontalPadding,
      topPadding: topPadding,
      bottomPadding: bottomPadding,
      textDirection: kReadingPageTurnDirection,
      canGoNext: canGoNext,
      canGoPrevious: canGoPrevious,
      onNext: onNext,
      onPrevious: onPrevious,
      semanticsLabel: context.l10n.fortressReadingHint,
      onTapDown: onTapDown,
      child: child,
    );
  }
}
