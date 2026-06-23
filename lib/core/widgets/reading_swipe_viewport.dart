import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/theme/theme.dart';

/// Swipe/affordance direction for sequential Arabic reading (mushaf page-turn).
///
/// Independent of app UI locale: swipe left (or ←) advances, swipe right (or →)
/// goes back — same as mushaf keyboard shortcuts in Tawaq.
const TextDirection kReadingPageTurnDirection = TextDirection.rtl;

/// Viewport-sized reading area with browser-style horizontal swipe navigation.
///
/// Edge affordances stay pinned to the viewport; content scrolls inside.
class ReadingSwipeViewport extends HookWidget {
  /// Creates a reading swipe viewport.
  const ReadingSwipeViewport({
    required this.viewportMinHeight,
    required this.horizontalPadding,
    required this.topPadding,
    required this.bottomPadding,
    required this.child,
    required this.canGoNext,
    required this.canGoPrevious,
    required this.onNext,
    required this.onPrevious,
    this.textDirection = TextDirection.ltr,
    this.semanticsLabel,
    this.onTapDown,
    super.key,
  });

  /// Minimum scroll extent height (typically the visible pane height).
  final double viewportMinHeight;

  final double horizontalPadding;
  final double topPadding;
  final double bottomPadding;

  /// Reading content (already width-constrained by parent when needed).
  final Widget child;

  final bool canGoNext;
  final bool canGoPrevious;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  /// Reading-order direction for swipe commits and edge affordances.
  ///
  /// Use [kReadingPageTurnDirection] for Arabic sequential content (fortress,
  /// Quran study). When [TextDirection.ltr], swipe left advances and the next
  /// affordance sits on the right; [TextDirection.rtl] inverts both gestures
  /// and edge placement.
  final TextDirection textDirection;

  /// Optional semantics label for the swipe region.
  final String? semanticsLabel;

  /// Optional tap handler (e.g. fortress counter decrement).
  final void Function(Offset localPosition)? onTapDown;

  static const _commitDistance = 72.0;
  static const _maxDrag = 120.0;
  static const _velocityCommit = 420.0;
  static const _contentShiftFactor = 0.18;

  bool get _isRtl => textDirection == TextDirection.rtl;

  /// Swipe left advances when [textDirection] is LTR (mushaf default).
  bool get _swipeLeftAdvances => !_isRtl;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final l10n = context.l10n;
    final dragOffset = useState<double>(0);
    final thresholdHapticFired = useRef(false);

    double rubberBand(double offset) {
      if (_swipeLeftAdvances) {
        if (offset < 0) {
          if (!canGoNext) return offset * 0.18;
          return offset.clamp(-_maxDrag, 0.0);
        }
        if (offset > 0) {
          if (!canGoPrevious) return offset * 0.18;
          return offset.clamp(0.0, _maxDrag);
        }
        return 0;
      }

      if (offset > 0) {
        if (!canGoNext) return offset * 0.18;
        return offset.clamp(0.0, _maxDrag);
      }
      if (offset < 0) {
        if (!canGoPrevious) return offset * 0.18;
        return offset.clamp(-_maxDrag, 0.0);
      }
      return 0;
    }

    double progressForOffset(double offset) =>
        (offset.abs() / _commitDistance).clamp(0.0, 1.0);

    void onDragStart(DragStartDetails details) {
      thresholdHapticFired.value = false;
    }

    void onDragUpdate(DragUpdateDetails details) {
      final next = rubberBand(dragOffset.value + details.delta.dx);
      dragOffset.value = next;

      if (progressForOffset(next) >= 1 && !thresholdHapticFired.value) {
        thresholdHapticFired.value = true;
        unawaited(HapticFeedback.selectionClick());
      }
    }

    void onDragEnd(DragEndDetails details) {
      final offset = dragOffset.value;
      final velocity = details.primaryVelocity ?? 0.0;

      final commitNext = _swipeLeftAdvances
          ? canGoNext &&
                (offset <= -_commitDistance ||
                    (offset < -12 && velocity < -_velocityCommit))
          : canGoNext &&
                (offset >= _commitDistance ||
                    (offset > 12 && velocity > _velocityCommit));
      final commitPrevious = _swipeLeftAdvances
          ? canGoPrevious &&
                (offset >= _commitDistance ||
                    (offset > 12 && velocity > _velocityCommit))
          : canGoPrevious &&
                (offset <= -_commitDistance ||
                    (offset < -12 && velocity < -_velocityCommit));

      dragOffset.value = 0;

      if (commitNext) {
        unawaited(HapticFeedback.lightImpact());
        onNext();
        return;
      }
      if (commitPrevious) {
        unawaited(HapticFeedback.lightImpact());
        onPrevious();
      }
    }

    final offset = dragOffset.value;
    final nextProgress = canGoNext
        ? (_swipeLeftAdvances
              ? offset < 0
                    ? progressForOffset(offset)
                    : 0.0
              : offset > 0
              ? progressForOffset(offset)
              : 0.0)
        : 0.0;
    final previousProgress = canGoPrevious
        ? (_swipeLeftAdvances
              ? offset > 0
                    ? progressForOffset(offset)
                    : 0.0
              : offset < 0
              ? progressForOffset(offset)
              : 0.0)
        : 0.0;

    final swipeRegion = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: onTapDown == null
          ? null
          : (details) => onTapDown!(details.localPosition),
      onHorizontalDragStart: onDragStart,
      onHorizontalDragUpdate: onDragUpdate,
      onHorizontalDragEnd: onDragEnd,
      dragStartBehavior: DragStartBehavior.down,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(minHeight: viewportMinHeight),
        // alignment: Alignment.center,
        child: Transform.translate(
          offset: Offset(offset * _contentShiftFactor, 0),
          child: child,
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final showAffordanceLabels = constraints.maxWidth >= 480;

        return Stack(
          fit: StackFit.expand,
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                topPadding,
                horizontalPadding,
                bottomPadding,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: viewportMinHeight),
                child: semanticsLabel == null
                    ? swipeRegion
                    : Semantics(
                        container: true,
                        label: semanticsLabel,
                        child: swipeRegion,
                      ),
              ),
            ),
            if (nextProgress > 0.04)
              Positioned(
                right: _isRtl ? null : AppSpacing.lg,
                left: _isRtl ? AppSpacing.lg : null,
                top: 0,
                bottom: 0,
                child: Center(
                  child: ExcludeSemantics(
                    child: _SwipeNavAffordance(
                      progress: nextProgress,
                      label: l10n.next,
                      showLabel: showAffordanceLabels,
                      icon: _isRtl
                          ? FLucideIcons.chevronLeft
                          : FLucideIcons.chevronRight,
                      colors: colors,
                      radii: theme.radii,
                      slideFromStart: _isRtl,
                    ),
                  ),
                ),
              ),
            if (previousProgress > 0.04)
              Positioned(
                left: _isRtl ? null : AppSpacing.lg,
                right: _isRtl ? AppSpacing.lg : null,
                top: 0,
                bottom: 0,
                child: Center(
                  child: ExcludeSemantics(
                    child: _SwipeNavAffordance(
                      progress: previousProgress,
                      label: l10n.fortressPrevious,
                      showLabel: showAffordanceLabels,
                      icon: _isRtl
                          ? FLucideIcons.chevronRight
                          : FLucideIcons.chevronLeft,
                      colors: colors,
                      radii: theme.radii,
                      slideFromStart: !_isRtl,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SwipeNavAffordance extends StatelessWidget {
  const _SwipeNavAffordance({
    required this.progress,
    required this.label,
    required this.showLabel,
    required this.icon,
    required this.colors,
    required this.radii,
    required this.slideFromStart,
  });

  final double progress;
  final String label;
  final bool showLabel;
  final IconData icon;
  final FColors colors;
  final AppRadii radii;
  final bool slideFromStart;

  @override
  Widget build(BuildContext context) {
    final ready = progress >= 1;
    final scale = 0.7 + 0.3 * Curves.easeOutCubic.transform(progress);
    final opacity = math.min<double>(1, progress * 1.25);
    final slide = (1 - progress) * 20 * (slideFromStart ? -1 : 1);

    final ringColor = Color.lerp(
      colors.border.withAlpha(140),
      colors.primary,
      progress,
    )!;
    final iconColor = Color.lerp(
      colors.mutedForeground,
      colors.primary,
      progress,
    )!;

    return IgnorePointer(
      child: Opacity(
        opacity: opacity,
        child: Transform.translate(
          offset: Offset(slide, 0),
          child: Transform.scale(
            scale: scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: AppSpacing.xs,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.secondary.withAlpha(ready ? 200 : 140),
                    border: Border.all(
                      color: ringColor,
                      width: ready ? 1.5 : 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: iconColor,
                    textDirection: TextDirection.ltr,
                  ),
                ),
                if (showLabel)
                  Text(
                    label,
                    style: context.theme.typography.body.xs.copyWith(
                      color: iconColor,
                      fontWeight: ready ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
