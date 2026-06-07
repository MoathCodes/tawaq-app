import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:tawaq/core/utils/platform.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart' show DesktopSelectionArea, ScopedSelectableText;

/// App-wide scroll behavior that hides scrollbars while preserving default
/// drag/scroll device handling (including desktop trackpad).
class TawaqAppScrollBehavior extends MaterialScrollBehavior {
  /// Creates scroll behavior with hidden scrollbars.
  const TawaqAppScrollBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) =>
      child;
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
