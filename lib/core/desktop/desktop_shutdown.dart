import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tawaq/core/audio/audio_player_provider.dart';
import 'package:tawaq/core/desktop/alerts/prayer_alert_dispatcher.dart';
import 'package:tawaq/core/desktop/desktop_tray_service.dart';
import 'package:tawaq/core/desktop/single_instance.dart';
import 'package:tawaq/core/utils/platform.dart';
import 'package:window_manager/window_manager.dart';

Future<void>? _shutdownFuture;

/// Ordered teardown for desktop quit paths (window close, tray quit).
///
/// Single-flight: concurrent quit callers await the same teardown. Force-shuts
/// down prayer alerts, stops and disposes audio, removes the tray icon, then
/// destroys the native window.
///
/// [tray] must be passed when called from [DesktopTrayService] itself —
/// reading [desktopTrayServiceProvider] through that provider's [Ref]
/// asserts ("A provider cannot depend on itself").
Future<void> shutdownDesktop(Ref ref, {DesktopTrayService? tray}) {
  if (!isDesktopPlatform) return Future<void>.value();
  return _shutdownFuture ??= _runShutdownDesktop(ref, tray: tray);
}

Future<void> _runShutdownDesktop(Ref ref, {DesktopTrayService? tray}) async {
  await ref.read(prayerAlertDispatcherProvider.notifier).forceShutdown();
  final audio = ref.read(tawaqAudioServiceProvider);
  // Stop via the service (no lease owner) so recitation or adhan both halt,
  // then dispose so mpv / lease timers cannot linger past window destroy.
  await audio.stop(force: true);
  await audio.dispose();
  if (tray != null) {
    await tray.dispose();
  } else {
    await ref.read(desktopTrayServiceProvider).dispose();
  }
  await disposeSingleDesktopInstance();
  await windowManager.destroy();
}
