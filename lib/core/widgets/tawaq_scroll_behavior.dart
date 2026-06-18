import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:tawaq/core/utils/platform.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart'
    show DesktopSelectionArea, ScopedSelectableText;

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
  const TawaqAppScrollBehavior();

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

class _MeaningfulScrollbar extends StatelessWidget {
  const _MeaningfulScrollbar({
    required this.controller,
    required this.child,
  });

  final ScrollController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Pull the visual styling from the shared theme so the auto-hiding thumb
    // looks identical to the pinned one it replaces. RawScrollbar does not read
    // ScrollbarThemeData itself, so resolve the values here.
    final scrollbarTheme = Theme.of(context).scrollbarTheme;
    const states = <WidgetState>{};

    return AnimatedBuilder(
      animation: controller,
      builder: (context, scrollChild) {
        if (!controller.hasClients) {
          return scrollChild!;
        }

        final position = controller.position;
        final showThumb =
            position.hasContentDimensions && isMeaningfulScroll(position);

        if (!showThumb) {
          return scrollChild!;
        }

        return RawScrollbar(
          controller: controller,
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
          child: scrollChild!,
        );
      },
      child: child,
    );
  }
}

/// Desktop scroll behavior that avoids trackpad press-drag vs text selection.
///
/// Flutter lets [PointerDeviceKind.trackpad] drag-scroll ancestor
/// [Scrollable]s, which often wins over [SelectionArea] press-drag
/// (flutter/flutter#153004).
///
/// **Do not apply app-wide** via [MaterialApp.scrollBehavior]: excluding
/// [PointerDeviceKind.trackpad] from [dragDevices] breaks two-finger
/// trackpad scrolling on Linux/desktop (only the scrollbar thumb remains).
/// Prefer scoped [DesktopSelectionArea] / [ScopedSelectableText] instead.
class TawaqScrollBehavior extends MaterialScrollBehavior {
  /// Creates scroll behavior tuned for desktop text selection.
  const TawaqScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices {
    if (!isDesktopPlatform) return super.dragDevices;

    return const <PointerDeviceKind>{
      PointerDeviceKind.touch,
      PointerDeviceKind.stylus,
      PointerDeviceKind.invertedStylus,
    };
  }
}
