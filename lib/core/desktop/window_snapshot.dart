import 'dart:ui';

import 'package:tawaq/feature/prayer/domain/models/adhan_settings.dart';
import 'package:window_manager/window_manager.dart';

/// Minimum window size enforced on desktop bootstrap.
///
/// [WindowSnapshot] restores this after adhan compact morph because
/// `window_manager` does not expose a `getMinimumSize` API.
const Size kDesktopMinimumWindowSize = Size(800, 600);

/// Saved native window geometry and flags for restore after adhan alert morph.
class WindowSnapshot {
  /// Creates a [WindowSnapshot].
  const WindowSnapshot({
    required this.bounds,
    required this.isAlwaysOnTop,
    required this.isVisible,
    required this.skipTaskbar,
    required this.minimumSize,
  });

  /// Window bounds before morph.
  final Rect bounds;

  /// Whether always-on-top was enabled.
  final bool isAlwaysOnTop;

  /// Whether the window was visible.
  final bool isVisible;

  /// Taskbar visibility flag.
  final bool skipTaskbar;

  /// Minimum size constraint before morph.
  final Size minimumSize;

  /// Captures the current window state.
  static Future<WindowSnapshot> capture() async {
    final bounds = await windowManager.getBounds();
    return WindowSnapshot(
      bounds: bounds,
      isAlwaysOnTop: await windowManager.isAlwaysOnTop(),
      isVisible: await windowManager.isVisible(),
      skipTaskbar: await windowManager.isSkipTaskbar(),
      minimumSize: kDesktopMinimumWindowSize,
    );
  }

  /// Restores previously captured state.
  Future<void> restore() async {
    await windowManager.setMinimumSize(minimumSize);
    await windowManager.setBounds(bounds);
    await windowManager.setAlwaysOnTop(isAlwaysOnTop);
    await windowManager.setSkipTaskbar(skipTaskbar);
    if (isVisible) {
      await windowManager.show();
    } else {
      await windowManager.hide();
    }
  }
}

/// Captured window flags for overlay-mode alerts (no geometry morph).
class AlertWindowFlags {
  /// Creates [AlertWindowFlags].
  const AlertWindowFlags({required this.isAlwaysOnTop});

  /// Whether always-on-top was enabled before the alert.
  final bool isAlwaysOnTop;

  /// Captures flags needed to restore after an overlay alert.
  static Future<AlertWindowFlags> capture() async {
    return AlertWindowFlags(
      isAlwaysOnTop: await windowManager.isAlwaysOnTop(),
    );
  }

  /// Restores captured window flags.
  Future<void> restore() async {
    await windowManager.setAlwaysOnTop(isAlwaysOnTop);
  }
}

/// Compact alert card size when morphing from tray.
const Size kAdhanAlertCompactSize = Size(400, 104);

/// Screen edge inset for compact alert placement.
const double kAdhanAlertScreenInset = 16;

/// Resolves the top-left origin for a compact morphed adhan alert window.
Offset resolveAdhanAlertCompactOrigin({
  required Rect screen,
  required AdhanAlertPosition alertPosition,
}) {
  const size = kAdhanAlertCompactSize;
  const inset = kAdhanAlertScreenInset;
  return switch (alertPosition) {
    AdhanAlertPosition.center => Offset(
      screen.left + (screen.width - size.width) / 2,
      screen.top + (screen.height - size.height) / 2,
    ),
    AdhanAlertPosition.topEnd => Offset(
      screen.right - size.width - inset,
      screen.top + inset,
    ),
    AdhanAlertPosition.topStart => Offset(
      screen.left + inset,
      screen.top + inset,
    ),
  };
}
