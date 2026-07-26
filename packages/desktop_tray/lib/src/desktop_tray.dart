import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import 'tray_item.dart';
import 'tray_listener.dart';

/// Returns `true` when running inside Flatpak, Snap, Docker, or Podman.
bool _runningInSandbox() {
  return Platform.environment.containsKey('FLATPAK_ID') ||
      Platform.environment.containsKey('SNAP') ||
      (Platform.environment['container']?.isNotEmpty == true) ||
      FileSystemEntity.isFileSync('/.dockerenv');
}

/// Singleton controller for the desktop system-tray icon and context menu.
///
/// ```dart
/// desktopTray.addListener(myListener);
/// await desktopTray.setIcon('assets/logo/logo.png');
/// await desktopTray.setToolTip('My App');
/// await desktopTray.setContextMenu(TrayMenu(items: [...]));
/// ```
class DesktopTray {
  DesktopTray._() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  /// Global singleton instance.
  static final DesktopTray instance = DesktopTray._();

  static const MethodChannel _channel = MethodChannel('desktop_tray');

  final ObserverList<DesktopTrayListener> _listeners = ObserverList<DesktopTrayListener>();

  /// The most recently set menu, used for mapping native id → [TrayMenuItem].
  TrayMenu? _menu;

  // ──────────────────────── Public API ────────────────────────

  bool get hasListeners => _listeners.isNotEmpty;

  void addListener(DesktopTrayListener listener) => _listeners.add(listener);

  void removeListener(DesktopTrayListener listener) => _listeners.remove(listener);

  /// Check whether the system tray (StatusNotifierWatcher) is available.
  ///
  /// On Linux, returns `true` only if the D-Bus StatusNotifierWatcher service
  /// is registered. On other platforms, always returns `true`.
  Future<bool> checkAvailable() async {
    if (defaultTargetPlatform != TargetPlatform.linux) return true;
    try {
      final result = await _channel.invokeMethod<bool>('checkAvailable');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Set the tray icon image.
  ///
  /// [assetPath] is relative to the Flutter assets directory
  /// (e.g. `'assets/logo/logo.png'`).
  ///
  /// Supported formats per platform:
  /// - **Windows**: `.ico`, `.png`, `.jpg`, `.bmp`, `.gif` (non-`.ico` files
  ///   are decoded via GDI+). `.ico` still gives the sharpest result.
  /// - **macOS**: any format `NSImage` understands (PNG recommended).
  /// - **Linux**: PNG in an icon-theme-compatible path.
  ///
  /// Throws a [PlatformException] with code `ICON_LOAD_FAILED` on Windows
  /// when the image cannot be decoded.
  Future<void> setIcon(String assetPath) async {
    final Map<String, dynamic> arguments = {
      'iconPath': p.joinAll([
        p.dirname(Platform.resolvedExecutable),
        'data',
        'flutter_assets',
        assetPath,
      ]),
    };

    // macOS: embed the image data as base64.
    if (defaultTargetPlatform == TargetPlatform.macOS) {
      final ByteData imageData = await rootBundle.load(assetPath);
      arguments['base64Icon'] = base64Encode(imageData.buffer.asUint8List());
    }

    // Linux in sandbox: pass bare icon-theme name instead of path.
    if (defaultTargetPlatform == TargetPlatform.linux && _runningInSandbox()) {
      arguments['iconPath'] = assetPath;
    }

    await _channel.invokeMethod<void>('setIcon', arguments);
  }

  /// Set the hover tooltip text. On Linux this is a safe no-op.
  Future<void> setToolTip(String toolTip) async {
    await _channel.invokeMethod<void>('setToolTip', {'toolTip': toolTip});
  }

  /// Replace the context menu displayed on right-click (or left-click on
  /// Linux AppIndicator).
  Future<void> setContextMenu(TrayMenu menu) async {
    _menu = menu;
    await _channel.invokeMethod<void>('setContextMenu', {'menu': menu.toJson()});
  }

  /// Programmatically open the context menu at the current cursor position.
  ///
  /// On Linux this is a no-op because AppIndicator natively shows the menu.
  Future<void> popUpContextMenu() async {
    await _channel.invokeMethod<void>('popUpContextMenu');
  }

  /// Remove the tray icon and release native resources.
  ///
  /// Also clears Dart-side [_listeners] and [_menu] so destroyed trays do not
  /// retain callbacks or menu graphs.
  Future<void> destroy() async {
    await _channel.invokeMethod<void>('destroy');
    _listeners.clear();
    _menu = null;
  }

  // ──────────────────── Method-channel handler ────────────────────

  Future<void> _handleMethodCall(MethodCall call) async {
    for (final DesktopTrayListener listener in _listeners) {
      switch (call.method) {
        case 'onTrayIconMouseDown':
          listener.onTrayIconMouseDown();
        case 'onTrayIconMouseUp':
          listener.onTrayIconMouseUp();
        case 'onTrayIconRightMouseDown':
          listener.onTrayIconRightMouseDown();
        case 'onTrayIconRightMouseUp':
          listener.onTrayIconRightMouseUp();
        case 'onTrayMenuItemClick':
          final int id = call.arguments['id'] as int;
          final TrayMenuItem? item = _menu?.findById(id);
          if (item != null) {
            listener.onTrayMenuItemClick(item);
          }
      }
    }
  }
}

/// Convenience top-level accessor.
final desktopTray = DesktopTray.instance;
