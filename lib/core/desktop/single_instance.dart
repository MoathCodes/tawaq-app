import 'dart:io';

import 'package:flutter/services.dart';
import 'package:tawaq/core/utils/platform.dart';
import 'package:window_manager/window_manager.dart';

/// Locale-independent native desktop window title.
const kDesktopWindowTitle = 'Tawaq';

const _channel = MethodChannel('tawaq/single_instance');

/// Restores, shows, and focuses the primary window through its native runner.
///
/// The same native operation handles tray activation and duplicate launches.
/// Runners acquire instance ownership before creating a Flutter engine in
/// profile/release builds; debug builds still allow parallel development.
Future<void> activateDesktopWindow() async {
  if (!isDesktopPlatform) return;
  await _channel.invokeMethod<void>('activate');
}

/// Completes startup visibility without losing a concurrent reopen request.
///
/// Native runners serialize the launch-to-tray decision with OS activation.
/// An activation received before this call keeps the window visible. If the
/// channel is unavailable, keep a visible recovery path rather than hide.
Future<void> completeDesktopActivationBootstrap({
  required bool launchHidden,
}) async {
  if (!isDesktopPlatform) return;
  try {
    await _channel.invokeMethod<void>('completeBootstrap', {
      'launchHidden': launchHidden,
    });
  } on PlatformException {
    await _showRecoveryWindow();
  } on MissingPluginException {
    await _showRecoveryWindow();
  }
}

Future<void> _showRecoveryWindow() async {
  if (Platform.isLinux) await windowManager.restore();
  await windowManager.show();
  await windowManager.focus();
}
