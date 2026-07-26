import 'package:dorar_hadith_flutter/dorar_hadith_flutter.dart';
import 'package:flutter/material.dart';
import 'package:hivez_flutter/hivez_flutter.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/desktop/launch_at_login_service.dart';
import 'package:tawaq/core/desktop/single_instance.dart';
import 'package:tawaq/core/desktop/window_snapshot.dart';
import 'package:tawaq/core/utils/platform.dart';
import 'package:tawaq/hive/hive_registrar.g.dart';
import 'package:window_manager/window_manager.dart';

part 'app_init_providers.g.dart';

/// Initializes Hive and registers adapters for persisted settings and data.
@Riverpod(keepAlive: true)
Future<void> hiveCoreInit(Ref ref) async {
  await Hive.initFlutter();
  Hive.registerAdapters();
}

/// Initializes the Dorar hadith client.
@Riverpod(keepAlive: true)
Future<void> dorarInit(Ref ref) async {
  await DorarHadithFlutter.ensureInitialized();
}

/// Initializes desktop window manager, notifications, tray hooks, and MPV.
@Riverpod(keepAlive: true)
Future<void> desktopShellInit(Ref ref) async {
  if (!isDesktopPlatform) return;

  MpvAudioKit.ensureInitialized();
  await localNotifier.setup(appName: 'Tawaq');
  await LaunchAtLoginService.setup();
  await windowManager.ensureInitialized();
  await windowManager.waitUntilReadyToShow(
    const WindowOptions(
      center: true,
      backgroundColor: Color(0x00000000),
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      title: kDesktopWindowTitle,
      minimumSize: kDesktopMinimumWindowSize,
    ),
  );
  await windowManager.setMinimumSize(kDesktopMinimumWindowSize);
  // Pin a locale-independent title so flutter_alone can find the window
  // (Windows HWND lookup; Linux uses the activate socket for tray restore).
  await windowManager.setTitle(kDesktopWindowTitle);
}

/// Gate for showing the real app after Hive and core settings can hydrate.
@Riverpod(keepAlive: true)
Future<void> appBootstrapReady(Ref ref) async {
  await ref.watch(hiveCoreInitProvider.future);
  if (isDesktopPlatform) {
    await ref.watch(desktopShellInitProvider.future);
  }
}
