import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/desktop/desktop_shutdown.dart';
import 'package:tawaq/core/desktop/desktop_tray_service.dart';
import 'package:tawaq/core/utils/platform.dart';
import 'package:tawaq/feature/settings/presentation/provider/desktop_settings_provider.dart';
import 'package:window_manager/window_manager.dart';

part 'desktop_window_controller.g.dart';

/// Whether the main window is currently visible (not hidden to tray).
@Riverpod(keepAlive: true)
class DesktopMainWindowVisible extends _$DesktopMainWindowVisible {
  @override
  bool build() => true;

  /// Updates the cached visibility flag.
  void setVisible({required bool value}) {
    if (state == value) return;
    state = value;
  }

  /// Re-reads visibility from the native window manager.
  Future<void> refreshFromWindow() async {
    if (!isDesktopPlatform) return;
    setVisible(value: await windowManager.isVisible());
  }
}

/// Desktop window close / show / quit helpers shared by title bar and tray.
@Riverpod(keepAlive: true)
DesktopWindowController desktopWindowController(Ref ref) {
  return DesktopWindowController(ref);
}

/// Coordinates hide-to-tray and real quit behaviour.
class DesktopWindowController {
  /// Creates a [DesktopWindowController].
  DesktopWindowController(this._ref);

  final Ref _ref;

  /// Hides or quits depending on persisted desktop settings.
  Future<void> requestClose() async {
    if (!isDesktopPlatform) {
      await windowManager.close();
      return;
    }

    final settings = _ref.read(desktopSettingsProvider).value;
    if (settings?.minimizeToTrayOnClose ?? true) {
      if (await _trayAvailable()) {
        await hideMainWindow();
        return;
      }
      // No tray to restore from — quit instead of trapping a hidden window.
    }
    await quit();
  }

  /// Minimizes or hides to tray depending on settings.
  Future<void> requestMinimize() async {
    final settings = _ref.read(desktopSettingsProvider).value;
    if ((settings?.minimizeToTray ?? false) && await _trayAvailable()) {
      await hideMainWindow();
      return;
    }
    await windowManager.minimize();
  }

  /// Hides the main window to the system tray.
  ///
  /// No-ops when the tray backend is unavailable (no restore path).
  Future<void> hideMainWindow() async {
    if (!await _trayAvailable()) return;
    await windowManager.hide();
    _ref
        .read(desktopMainWindowVisibleProvider.notifier)
        .setVisible(value: false);
  }

  Future<bool> _trayAvailable() async {
    final tray = _ref.read(desktopTrayServiceProvider);
    await tray.ensureInitialized();
    return tray.isAvailable;
  }

  /// Shows and focuses the main window.
  Future<void> showMainWindow() async {
    // Linux GTK may treat show() after hide as minimize (window_manager#580).
    if (Platform.isLinux) {
      await windowManager.restore();
    }
    await windowManager.show();
    await windowManager.focus();
    _ref
        .read(desktopMainWindowVisibleProvider.notifier)
        .setVisible(value: true);
  }

  /// Fully exits the application.
  Future<void> quit() async {
    await shutdownDesktop(_ref);
  }
}
