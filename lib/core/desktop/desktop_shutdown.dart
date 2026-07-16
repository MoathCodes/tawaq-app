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
///
/// [tray] must be passed when called from [DesktopTrayService] itself —
/// reading [desktopTrayServiceProvider] through that provider's [Ref]
/// asserts ("A provider cannot depend on itself").
Future<void> shutdownDesktop(Ref ref, {DesktopTrayService? tray}) async {
  if (!isDesktopPlatform) return;

  await ref.read(prayerAlertDispatcherProvider.notifier).forceShutdown();
  // Stop via the service (no lease owner) so recitation or adhan both halt.
  await ref.read(tawaqAudioServiceProvider).stop();
  if (tray != null) {
    await tray.dispose();
  } else {
    await ref.read(desktopTrayServiceProvider).dispose();
  }
  await windowManager.destroy();
}
