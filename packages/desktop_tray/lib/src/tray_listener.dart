import 'package:desktop_tray/src/tray_item.dart';

/// Mixin for receiving system-tray events from [DesktopTray].
///
/// Override only the callbacks you care about — every method has a default
/// no-op implementation.
abstract mixin class DesktopTrayListener {
  /// Left mouse button pressed on the tray icon.
  void onTrayIconMouseDown() {}

  /// Left mouse button released on the tray icon.
  void onTrayIconMouseUp() {}

  /// Right mouse button pressed on the tray icon.
  void onTrayIconRightMouseDown() {}

  /// Right mouse button released on the tray icon.
  void onTrayIconRightMouseUp() {}

  /// A context-menu item was clicked.
  void onTrayMenuItemClick(TrayMenuItem item) {}
}
