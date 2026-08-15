import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/app/desktop/desktop_shutdown.dart';
import 'package:tawaq/app/desktop/desktop_tray_service.dart';
import 'package:tawaq/core/desktop/window_state_provider.dart';
import 'package:tawaq/core/utils/platform.dart';
import 'package:tawaq/feature/settings/presentation/provider/desktop_settings_provider.dart';
import 'package:window_manager/window_manager.dart';

part 'desktop_window_controller.g.dart';

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
    await _ref.read(nativeWindowStateProvider.notifier).refresh();
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
    await _ref.read(nativeWindowStateProvider.notifier).refresh();
  }

  /// Fully exits the application.
  Future<void> quit() async {
    await shutdownDesktop(_ref);
  }
}
