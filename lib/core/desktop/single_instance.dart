import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_alone/flutter_alone.dart';
import 'package:tawaq/core/utils/platform.dart';

/// Stable OS window title used by flutter_alone HWND / window lookup.
///
/// Must stay Latin and locale-independent so a second launch can find a
/// tray-hidden window even when in-app branding uses Arabic `توّاق`.
const kDesktopWindowTitle = 'Tawaq';

const _packageId = 'me.moathdev.tawaq';
const _lockFileName = 'me.moathdev.tawaq.lock';
const _activateDirName = 'me.moathdev.tawaq';
const _activateSocketName = 'activate.sock';

/// Ping timeout so a missing listener never hangs the duplicate process.
const _activatePingTimeout = Duration(milliseconds: 500);

ServerSocket? _activateServer;
StreamController<void>? _activateController;
StreamSubscription<Socket>? _activateAcceptSub;
bool _pendingActivate = false;

Directory get _activateDir =>
    Directory('${Directory.systemTemp.path}/$_activateDirName');

String get _activateSocketPath => '${_activateDir.path}/$_activateSocketName';

/// Emits when a blocked second launch asks the primary to show itself.
///
/// Linux only — empty elsewhere. Subscribe from `DesktopShell` and call
/// `DesktopWindowController.showMainWindow`. Also call
/// [takePendingDesktopActivate] after subscribing so a wake that arrived
/// during bootstrap is not lost.
Stream<void> get desktopActivateRequests =>
    _activateController?.stream ?? const Stream<void>.empty();

/// Consumes a wake that arrived before any listener was attached.
bool takePendingDesktopActivate() {
  final pending = _pendingActivate;
  _pendingActivate = false;
  return pending;
}

/// Ensures only one desktop instance runs.
///
/// On a duplicate launch, flutter_alone tries OS-level activation (best-effort
/// on Linux Wayland), then on Linux this pings a Unix socket so the primary
/// can call `DesktopWindowController.showMainWindow` for tray-hidden windows.
/// The second process then exits.
///
/// Skipped in debug by Alone's default (hot restart / parallel `flutter run`);
/// the Linux activate socket is also skipped in debug to match.
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
  } else if (Platform.isLinux) {
    config = FlutterAloneConfig.forLinux(
      linuxConfig: LinuxConfig(lockFileName: _lockFileName),
      windowConfig: const WindowConfig(windowTitle: kDesktopWindowTitle),
      messageConfig: const EnMessageConfig(showMessageBox: false),
    );
  } else {
    return;
  }

  if (!await FlutterAlone.instance.checkAndRun(config: config)) {
    if (Platform.isLinux) {
      await _pingActivateSocket();
    }
    exit(0);
  }

  // Match Alone's debug skip so parallel `flutter run` does not fight over
  // the activate socket path.
  if (Platform.isLinux && !kDebugMode) {
    await _startActivateListener();
  }
}

/// Closes the Linux activate socket. Safe to call when not listening.
Future<void> stopDesktopActivateListener() async {
  await _activateAcceptSub?.cancel();
  _activateAcceptSub = null;
  await _activateServer?.close();
  _activateServer = null;
  await _activateController?.close();
  _activateController = null;
  _pendingActivate = false;
  try {
    final socketFile = File(_activateSocketPath);
    if (socketFile.existsSync()) {
      socketFile.deleteSync();
    }
  } on Object {
    // Best-effort unlink of a crash leftover.
  }
}

Future<void> _ensurePrivateActivateDir() async {
  final dir = _activateDir;
  if (!dir.existsSync()) {
    await dir.create(recursive: true);
  }
  // Restrict the activate directory so other local users cannot trivially
  // bind/connect to a world-writable path under /tmp.
  try {
    await Process.run('chmod', ['700', dir.path]);
  } on Object {
    // Best-effort; bind still proceeds.
  }
}

Future<void> _startActivateListener() async {
  await stopDesktopActivateListener();
  await _ensurePrivateActivateDir();

  final path = _activateSocketPath;
  try {
    final stale = File(path);
    if (stale.existsSync()) {
      stale.deleteSync();
    }
  } on Object {
    // Continue; bind will fail loudly if the path is still taken.
  }

  final controller = StreamController<void>.broadcast();
  final address = InternetAddress(path, type: InternetAddressType.unix);
  // Unix sockets ignore the port; Dart still requires the positional arg.
  final server = await ServerSocket.bind(address, 0);
  try {
    await Process.run('chmod', ['600', path]);
  } on Object {
    // Best-effort socket mode.
  }
  _activateController = controller;
  _activateServer = server;
  _activateAcceptSub = server.listen((socket) {
    // Connection itself is the wake signal; close immediately.
    socket.destroy();
    _signalActivate(controller);
  });
}

void _signalActivate(StreamController<void> controller) {
  if (!controller.isClosed && controller.hasListener) {
    controller.add(null);
  } else {
    _pendingActivate = true;
  }
}

Future<void> _pingActivateSocket() async {
  Socket? socket;
  try {
    final address = InternetAddress(
      _activateSocketPath,
      type: InternetAddressType.unix,
    );
    socket = await Socket.connect(
      address,
      0,
      timeout: _activatePingTimeout,
    );
    await (socket..add(const [1])).flush().timeout(_activatePingTimeout);
  } on Object {
    // Primary may not have bound yet, or Alone skipped in debug.
  } finally {
    await socket?.close();
  }
}
