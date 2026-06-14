import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:tawaq/core/utils/platform.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart' show DesktopSelectionArea, ScopedSelectableText;

/// Builds a minimal scrollbar theme: no track, thin always-visible thumb.
ScrollbarThemeData tawaqScrollbarTheme(ColorScheme colorScheme) {
  final thumbBase = colorScheme.onSurface;

  return ScrollbarThemeData(
    thumbVisibility: const WidgetStatePropertyAll(true),
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

/// Minimum scroll overflow before showing a scrollbar thumb.
const double kScrollbarMinScrollExtent = 64;

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
    return AnimatedBuilder(
      animation: controller,
      builder: (context, scrollChild) {
        if (!controller.hasClients) {
          return scrollChild!;
        }

        final position = controller.position;
        final showThumb = position.hasContentDimensions &&
            isMeaningfulScroll(position);

        if (!showThumb) {
          return scrollChild!;
        }

        return Scrollbar(
          controller: controller,
          thumbVisibility: true,
          trackVisibility: false,
          interactive: true,
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
