import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tawaq/core/audio/audio_player_provider.dart';
import 'package:tawaq/core/desktop/alerts/prayer_alert_dispatcher.dart';
import 'package:tawaq/core/desktop/desktop_tray_service.dart';
import 'package:tawaq/core/utils/platform.dart';
import 'package:window_manager/window_manager.dart';

/// Ordered teardown for desktop quit paths (window close, tray quit).
///
/// Force-shuts down prayer alerts, stops audio, removes the tray icon,
/// then destroys the native window.
Future<void> shutdownDesktop(Ref ref) async {
  if (!isDesktopPlatform) return;

  await ref.read(prayerAlertDispatcherProvider.notifier).forceShutdown();
  await ref.read(audioPlayerControllerProvider.notifier).stop();
  await ref.read(desktopTrayServiceProvider).dispose();
  await windowManager.destroy();
}
