import 'dart:async';

import 'package:desktop_tray/desktop_tray.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/desktop/desktop_window_controller.dart';
import 'package:tawaq/core/desktop/tray_menu.dart';
import 'package:tawaq/core/logging/logger_provider.dart';
import 'package:tawaq/core/utils/platform.dart';

part 'desktop_tray_service.g.dart';

/// System tray integration for desktop platforms.
@Riverpod(keepAlive: true)
DesktopTrayService desktopTrayService(Ref ref) {
  final service = DesktopTrayService(ref);
  ref.onDispose(() {
    unawaited(service.dispose());
  });
  return service;
}

/// Manages tray icon, menu, and events.
class DesktopTrayService with DesktopTrayListener {
  /// Creates [DesktopTrayService].
  DesktopTrayService(this._ref);

  final Ref _ref;
  bool _initialized = false;
  String? _lastTooltip;

  /// Whether the tray backend is active.
  bool get isAvailable => _initialized;

  /// Sets up the tray icon and listener.
  ///
  /// Menu content is applied separately via [applyMenu].
  Future<void> ensureInitialized() async {
    if (!isDesktopPlatform || _initialized) return;

    final log = _ref.read(loggerProvider);
    final available = await desktopTray.checkAvailable();
    if (!available) {
      log.w(
        '[DesktopTrayService] Tray unavailable on this desktop environment',
      );
      return;
    }

    desktopTray.addListener(this);
    await desktopTray.setIcon('assets/images/tray_icon.png');
    await desktopTray.setToolTip('Tawaq');
    _initialized = true;
  }

  /// Applies the tray context menu.
  Future<void> applyMenu(TrayMenu menu) async {
    if (!_initialized) return;
    await desktopTray.setContextMenu(menu);
  }

  /// Refreshes tray tooltip text (e.g. next prayer).
  Future<void> applyTooltip(String tooltip) async {
    if (!_initialized || tooltip == _lastTooltip) return;
    _lastTooltip = tooltip;
    await desktopTray.setToolTip(tooltip);
  }

  /// Tears down the tray and quits the app from a native menu callback.
  Future<void> quitFromTray() async {
    await dispose();
    if (!_ref.mounted) return;
    await _ref.read(desktopWindowControllerProvider).quit();
  }

  @override
  void onTrayMenuItemClick(TrayMenuItem item) {
    if (item.key == 'quit') {
      unawaited(quitFromTray());
      return;
    }
    final entry = trayMenuEntryByKey[item.key];
    if (entry == null) return;
    unawaited(entry.handle(_ref));
  }

  /// Removes tray icon and listener.
  Future<void> dispose() async {
    if (!_initialized) return;
    desktopTray.removeListener(this);
    await desktopTray.destroy();
    _initialized = false;
  }
}
