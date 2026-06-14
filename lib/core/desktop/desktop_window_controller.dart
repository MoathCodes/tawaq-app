import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';
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
      await windowManager.hide();
      return;
    }
    await quit();
  }

  /// Minimizes or hides to tray depending on settings.
  Future<void> requestMinimize() async {
    final settings = _ref.read(desktopSettingsProvider).value;
    if (settings?.minimizeToTray ?? false) {
      await windowManager.hide();
      return;
    }
    await windowManager.minimize();
  }

  /// Shows and focuses the main window.
  Future<void> showMainWindow() async {
    // Linux GTK may treat show() after hide as minimize (window_manager#580).
    if (Platform.isLinux) {
      await windowManager.restore();
    }
    await windowManager.show();
    await windowManager.focus();
  }

  /// Fully exits the application.
  Future<void> quit() async {
    await windowManager.destroy();
  }
}
