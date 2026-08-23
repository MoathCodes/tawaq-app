import 'package:flutter/material.dart';

/// Builds a minimal scrollbar theme: no track, thin auto-hiding thumb.
///
/// The thumb is not pinned (`thumbVisibility` false) so it fades out shortly
/// after scrolling stops. See [kScrollbarTimeToFade] / [kScrollbarFadeDuration].
ScrollbarThemeData tawaqScrollbarTheme(ColorScheme colorScheme) {
  final thumbBase = colorScheme.onSurface;

  return ScrollbarThemeData(
    thumbVisibility: const WidgetStatePropertyAll(false),
    trackVisibility: const WidgetStatePropertyAll(false),
    thickness: const WidgetStatePropertyAll(3),
    radius: const Radius.circular(4),
    crossAxisMargin: 2,
    mainAxisMargin: 6,
    minThumbLength: 20,
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.dragged)) {
        return thumbBase.withValues(alpha: 0.45);
      }
      if (states.contains(WidgetState.hovered)) {
        return thumbBase.withValues(alpha: 0.32);
      }
      return thumbBase.withValues(alpha: 0.2);
    }),
  );
}

/// Delay after the last scroll before the thumb starts fading out.
///
/// Kept short so the thumb dismisses almost immediately once scrolling stops.
const Duration kScrollbarTimeToFade = Duration(milliseconds: 100);

/// Duration of the thumb fade-out animation.
const Duration kScrollbarFadeDuration = Duration(milliseconds: 150);

/// Minimum scroll overflow before showing a scrollbar thumb.
const double kScrollbarMinScrollExtent = 512;

/// Minimum overflow as a fraction of the viewport (e.g. 0.08 → 8%).
const double kScrollbarMinOverflowFraction = 0.08;

/// Hide the thumb when it would cover more than this fraction of the track.
const double kScrollbarMaxThumbTrackFraction = 0.88;

/// Returns whether a scrollbar would convey useful scroll-position info.
bool isMeaningfulScroll(ScrollMetrics metrics) {
  // Extents are null until the scrollable has completed its first layout.
  if (!metrics.hasContentDimensions) return false;

  final extent = metrics.maxScrollExtent;
  if (extent <= 0) return false;

  final viewport = metrics.viewportDimension;
  if (viewport <= 0) return false;

  // A nearly full-height thumb means almost no overflow — not worth showing.
  if (viewport / (viewport + extent) > kScrollbarMaxThumbTrackFraction) {
    return false;
  }

  return extent >= kScrollbarMinScrollExtent &&
      extent / viewport >= kScrollbarMinOverflowFraction;
}

/// App-wide scroll behavior with a thin scrollbar thumb on long content only.
///
/// The track stays hidden. The thumb appears only when overflow is large enough
/// that position and remaining content are actually informative.
class TawaqAppScrollBehavior extends MaterialScrollBehavior {
  /// Creates scroll behavior with minimal, context-aware scrollbars.
  const new();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    final controller = details.controller;
    if (controller == null) {
      return child;
    }

    return _MeaningfulScrollbar(controller: controller, child: child);
  }
}

class _MeaningfulScrollbar extends StatefulWidget {
  const new({
    required this.controller,
    required this.child,
  });

  final ScrollController controller;
  final Widget child;

  @override
  State<_MeaningfulScrollbar> createState() => _MeaningfulScrollbarState();
}

class _MeaningfulScrollbarState extends State<_MeaningfulScrollbar> {
  bool _showThumb = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_syncThumbVisibility);
  }

  @override
  void didUpdateWidget(covariant _MeaningfulScrollbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_syncThumbVisibility);
      widget.controller.addListener(_syncThumbVisibility);
      _syncThumbVisibility();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncThumbVisibility);
    super.dispose();
  }

  void _syncThumbVisibility() {
    if (!widget.controller.hasClients) {
      if (_showThumb) setState(() => _showThumb = false);
      return;
    }

    final show =
        widget.controller.position.hasContentDimensions &&
        isMeaningfulScroll(widget.controller.position);
    if (show != _showThumb) {
      setState(() => _showThumb = show);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scrollChild = widget.child;
    if (!_showThumb) {
      return scrollChild;
    }

    final scrollbarTheme = Theme.of(context).scrollbarTheme;
    const states = <WidgetState>{};

    return RawScrollbar(
      controller: widget.controller,
      thumbVisibility: false,
      trackVisibility: false,
      interactive: true,
      thickness: scrollbarTheme.thickness?.resolve(states),
      radius: scrollbarTheme.radius,
      thumbColor: scrollbarTheme.thumbColor?.resolve(states),
      crossAxisMargin: scrollbarTheme.crossAxisMargin ?? 0,
      mainAxisMargin: scrollbarTheme.mainAxisMargin ?? 0,
      minThumbLength: scrollbarTheme.minThumbLength ?? 18,
      timeToFade: kScrollbarTimeToFade,
      fadeDuration: kScrollbarFadeDuration,
      child: scrollChild,
    );
  }
}
