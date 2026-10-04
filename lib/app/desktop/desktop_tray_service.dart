import 'dart:async';
import 'dart:io';

import 'package:desktop_tray/desktop_tray.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/app/desktop/desktop_shutdown.dart';
import 'package:tawaq/app/desktop/desktop_window_controller.dart';
import 'package:tawaq/app/desktop/tray_menu.dart';
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
  new(this._ref);

  final Ref _ref;
  bool _initialized = false;
  Future<void>? _initialization;
  String? _lastTooltip;

  /// Whether the tray backend is active.
  bool get isAvailable => _initialized;

  /// Sets up the tray icon and listener.
  ///
  /// Menu content is applied separately via [applyMenu].
  Future<void> ensureInitialized() async {
    if (!isDesktopPlatform || _initialized) return;
    final pending = _initialization;
    if (pending != null) return await pending;
    final initialization = _initialize();
    _initialization = initialization;
    try {
      await initialization;
    } finally {
      _initialization = null;
    }
  }

  Future<void> _initialize() async {
    final log = _ref.read(loggerProvider);
    final available = await desktopTray.checkAvailable();
    if (!available) {
      log.w(
        '[DesktopTrayService] Tray unavailable on this desktop environment',
      );
      return;
    }

    desktopTray.addListener(this);
    try {
      await desktopTray.setIcon('assets/images/tray_icon.png');
      await desktopTray.setToolTip('Tawaq');
      _initialized = true;
    } on Exception catch (error, stackTrace) {
      desktopTray.removeListener(this);
      await desktopTray.destroy();
      log.w(
        '[DesktopTrayService] Tray initialization failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
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
    // Pass [this] so shutdown does not re-read [desktopTrayServiceProvider]
    // through this provider's own [Ref] (self-dependency assertion).
    await shutdownDesktop(_ref, tray: this);
  }

  @override
  void onTrayIconMouseUp() {
    unawaited(_ref.read(desktopWindowControllerProvider).showMainWindow());
  }

  @override
  void onTrayIconRightMouseUp() {
    // Linux panels display the exported dbusmenu themselves.
    if (Platform.isLinux) return;
    unawaited(desktopTray.popUpContextMenu());
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
    await _initialization;
    if (!_initialized) return;
    desktopTray.removeListener(this);
    await desktopTray.destroy();
    _initialized = false;
    _lastTooltip = null;
  }
}
