import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/audio/audio_player_provider.dart';
import 'package:tawaq/core/desktop/adhan_alert_controller.dart';
import 'package:tawaq/core/desktop/alerts/os_notification_channel.dart';
import 'package:tawaq/core/desktop/alerts/sound_alert_channel.dart';
import 'package:tawaq/core/logging/logger_provider.dart';
import 'package:tawaq/core/utils/platform.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_alert_event.dart';
import 'package:tawaq/feature/prayer/domain/services/prayer_alert_coordinator.dart';

part 'prayer_alert_dispatcher.g.dart';

/// Wires the concrete desktop alert channels into a [PrayerAlertCoordinator]
/// and exposes it to the scheduler and UI.
///
/// This is the single owner of alert delivery that previously lived as the
/// ad-hoc bridge in `DesktopShell` plus the free-function dispatcher.
@Riverpod(keepAlive: true)
class PrayerAlertDispatcher extends _$PrayerAlertDispatcher {
  late final PrayerAlertCoordinator _coordinator;

  @override
  void build() {
    final inApp = ref.watch(adhanAlertControllerProvider.notifier);
    final sound = SoundAlertChannel(
      ref.watch(audioPlayerControllerProvider.notifier),
    );
    final os = OsNotificationChannel(onClick: inApp.focusAlert);
    final log = ref.read(loggerProvider);

    _coordinator = PrayerAlertCoordinator(
      // Delivery order: notification (cheap) → window/overlay → sound.
      // Teardown runs in reverse, so audio fades before the window restores.
      channels: [os, inApp, sound],
      playbackStream: ref.read(tawaqAudioServiceProvider).stateStream,
      onError: (message, error, stack) =>
          log.e(message, error: error, stackTrace: stack),
    );

    ref.onDispose(_coordinator.dispose);
  }

  /// Enqueues [event] for delivery across the channels.
  Future<void> dispatch(PrayerAlertEvent event) {
    if (!isDesktopPlatform) return Future<void>.value();
    return _coordinator.dispatch(event);
  }

  /// Dismisses the currently active alert (user action or external request).
  Future<void> dismiss() => _coordinator.dismiss();
}
