import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/core/widgets/directional_content_switcher.dart';
import 'package:tawaq/core/widgets/reading_swipe_viewport.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_category.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_dua_item.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/fortress_layout.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/fortress_a11y.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/reading/fortress_dua_content.dart';
import 'package:tawaq/theme/theme.dart';

/// Main thikr stage for focus reading (swipe, tap-to-count, mushaf text).
class FortressFocusThikrStage extends StatelessWidget {
  /// Creates a thikr stage.
  const FortressFocusThikrStage({
    required this.category,
    required this.duas,
    required this.index,
    required this.remaining,
    required this.isDone,
    required this.horizontalPadding,
    required this.slideDirection,
    required this.tapFeedback,
    required this.onDecrement,
    required this.onNext,
    required this.onPrevious,
    required this.onHorizontalScroll,
    this.showReadingHint = true,
    super.key,
  });

  final FortressCategory category;
  final List<FortressDuaItem> duas;
  final int index;
  final int remaining;
  final bool isDone;
  final double horizontalPadding;
  final int slideDirection;
  final (Offset position, int tick)? tapFeedback;
  final void Function([Offset? localPosition]) onDecrement;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final void Function(double delta) onHorizontalScroll;
  final bool showReadingHint;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = context.l10n;
    final currentDua = duas[index];
    final canGoNext = index < duas.length - 1;
    final canGoPrevious = index > 0;
    const verticalPadding = AppSpacing.xl;
    final hintReserve = showReadingHint && !isDone
        ? AppSpacing.xxl + AppSpacing.md
        : AppSpacing.lg;

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportMinHeight = (constraints.maxHeight -
                verticalPadding * 2 -
                hintReserve)
            .clamp(0.0, double.infinity);

        return Listener(
          onPointerSignal: (event) {
            if (event is PointerScrollEvent) {
              if (event.scrollDelta.dx.abs() > event.scrollDelta.dy.abs()) {
                onHorizontalScroll(event.scrollDelta.dx);
              }
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              ReadingSwipeViewport(
                viewportMinHeight: viewportMinHeight,
                horizontalPadding: horizontalPadding,
                topPadding: verticalPadding,
                bottomPadding: verticalPadding + hintReserve,
                textDirection: kReadingPageTurnDirection,
                canGoNext: canGoNext,
                canGoPrevious: canGoPrevious,
                onNext: onNext,
                onPrevious: onPrevious,
                semanticsLabel: l10n.fortressReadingHint,
                onTapDown: onDecrement,
                child: NonSelectable(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: kFortressReadingMaxWidth,
                    ),
                    child: DirectionalContentSwitcher(
                      currentKey: index,
                      slideDirection: slideDirection,
                      child: Semantics(
                        container: true,
                        label: FortressA11y.thikrSectionLabel(
                          l10n: l10n,
                          categoryTitle: category.title,
                          index: index,
                          total: duas.length,
                          remaining: remaining,
                          targetCount: currentDua.targetCount,
                          isDone: isDone,
                        ),
                        child: FortressDuaContent(
                          dua: currentDua,
                          mode: FortressDuaContentMode.focusReading,
                          muted: isDone,
                          proseStyle: theme.typography.body.xl3.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 2,
                            color: isDone
                                ? theme.colors.mutedForeground
                                : theme.colors.foreground,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (showReadingHint && !isDone)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: AppSpacing.lg,
                  child: FortressExcludeDecorative(
                    child: IgnorePointer(
                      child: Text(
                        l10n.fortressReadingHint,
                        style: theme.typography.body.xs.copyWith(
                          color: theme.colors.mutedForeground.withAlpha(160),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              if (tapFeedback case (final position, final tick))
                FortressFocusTapRipple(
                  key: ValueKey(tick),
                  position: position,
                  color: theme.colors.primary,
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Tap feedback ripple for focus-reading decrement.
class FortressFocusTapRipple extends HookWidget {
  /// Creates a tap ripple.
  const FortressFocusTapRipple({
    required this.position,
    required this.color,
    super.key,
  });

  final Offset position;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 420),
    );

    useEffect(() {
      unawaited(controller.forward(from: 0));
      return null;
    }, const []);

    final animation = useMemoized(
      () => CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutCubic,
      ),
      [controller],
    );
    useEffect(
      () => animation.dispose,
      [animation],
    );
    final opacityAnimation = useMemoized(
      () => Tween<double>(begin: 0.45, end: 0).animate(animation),
      [animation],
    );
    final scaleAnimation = useMemoized(
      () => Tween<double>(begin: 0.35, end: 1.6).animate(animation),
      [animation],
    );

    return Positioned(
      left: position.dx - 28,
      top: position.dy - 28,
      child: FortressExcludeDecorative(
        child: IgnorePointer(
          child: FadeTransition(
            opacity: opacityAnimation,
            child: ScaleTransition(
              scale: scaleAnimation,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withAlpha(50),
                  border: Border.all(color: color.withAlpha(90)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
