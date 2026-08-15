import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_alone/flutter_alone.dart';
import 'package:tawaq/core/utils/platform.dart';

/// Stable OS window title used by flutter_alone HWND / window lookup.
///
/// Must stay Latin and locale-independent so a second launch can find a
/// tray-hidden window even when in-app branding uses Arabic `توّاق`.
const kDesktopWindowTitle = 'Tawaq';

const _packageId = 'me.moathdev.tawaq';
const _lockFileName = 'me.moathdev.tawaq.lock';
const _linuxSingleInstanceChannel = MethodChannel('tawaq/single_instance');

/// Consumes a Linux reactivation that arrived while Flutter was bootstrapping.
///
/// The native `GtkApplication` handles later activations directly. This
/// one-shot query only prevents launch-to-tray initialization from hiding a
/// window that the user asked to reopen during startup. Channel failures keep
/// the window visible because hiding it would recreate the original problem.
Future<bool> takePendingDesktopActivate() async {
  if (!Platform.isLinux) return false;
  try {
    return await _linuxSingleInstanceChannel.invokeMethod<bool>(
          'takePendingActivation',
        ) ??
        false;
  } on PlatformException {
    return true;
  } on MissingPluginException {
    return true;
  }
}

/// Ensures only one desktop instance runs.
///
/// Windows and macOS use flutter_alone and exit a duplicate process after it
/// activates the primary window. Linux is gated earlier by the native
/// `GtkApplication`, before a second Flutter engine is created.
///
/// Duplicate checks are skipped in debug so parallel `flutter run` sessions
/// and hot restart keep working.
Future<void> ensureSingleDesktopInstance() async {
  if (!isDesktopPlatform) return;

  final FlutterAloneConfig config;
  if (Platform.isWindows) {
    config = FlutterAloneConfig.forWindows(
      windowsConfig: const DefaultWindowsMutexConfig(
        packageId: _packageId,
        appName: kDesktopWindowTitle,
      ),
      windowConfig: const WindowConfig(windowTitle: kDesktopWindowTitle),
      messageConfig: const EnMessageConfig(showMessageBox: false),
    );
  } else if (Platform.isMacOS) {
    config = FlutterAloneConfig.forMacOS(
      macOSConfig: MacOSConfig(lockFileName: _lockFileName),
      windowConfig: const WindowConfig(windowTitle: kDesktopWindowTitle),
      messageConfig: const EnMessageConfig(showMessageBox: false),
    );
  } else {
    // Linux uniqueness and activation are owned by GtkApplication in the
    // native runner, before Dart starts.
    return;
  }

  if (!await FlutterAlone.instance.checkAndRun(config: config)) {
    exit(0);
  }
}

/// Releases the Windows or macOS duplicate-instance guard during real quit.
Future<void> disposeSingleDesktopInstance() async {
  if (Platform.isWindows || Platform.isMacOS) {
    await FlutterAlone.instance.dispose();
  }
}
