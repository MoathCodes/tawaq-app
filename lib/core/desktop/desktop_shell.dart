import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:tawaq/core/audio/audio_player_provider.dart';
import 'package:tawaq/core/audio/playback_state.dart';
import 'package:tawaq/core/desktop/adhan_alert_controller.dart';
import 'package:tawaq/core/desktop/desktop_tray_sync_provider.dart';
import 'package:tawaq/core/desktop/desktop_window_controller.dart';
import 'package:tawaq/core/desktop/launch_at_login_service.dart';
import 'package:tawaq/core/utils/platform.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_alert_scheduler_provider.dart';
import 'package:tawaq/feature/settings/data/models/desktop_settings.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:window_manager/window_manager.dart';

/// Desktop root that wires tray, window lifecycle, and background adhan.
class DesktopShell extends ConsumerStatefulWidget {
  /// Creates [DesktopShell].
  const DesktopShell({required this.child, super.key});

  /// App content.
  final Widget child;

  @override
  ConsumerState<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends ConsumerState<DesktopShell>
    with WindowListener {
  ProviderSubscription<PlaybackState>? _playbackDismissSub;

  @override
  void initState() {
    super.initState();
    if (!isDesktopPlatform) return;
    windowManager.addListener(this);
    _playbackDismissSub = ref.listenManual(
      audioPlayerControllerProvider,
      (previous, next) {
        if (next is PlaybackIdle &&
            ref.read(adhanAlertControllerProvider).isShowing) {
          unawaited(ref.read(adhanAlertControllerProvider.notifier).dismiss());
        }
      },
    );
    unawaited(_bootstrapDesktop());
  }

  Future<void> _bootstrapDesktop() async {
    await windowManager.setPreventClose(true);
    if (!mounted) return;

    final settings = await ref
        .read(desktopSettingsProvider.future)
        .catchError((_) => DesktopSettings.defaults());
    if (!mounted) return;

    unawaited(
      LaunchAtLoginService.syncWithPreference(
        launchAtLogin: settings.launchAtLogin,
      ),
    );

    if (settings.launchToTray) {
      await windowManager.hide();
    } else {
      await windowManager.show();
    }
  }

  @override
  void dispose() {
    _playbackDismissSub?.close();
    if (isDesktopPlatform) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  void onWindowClose() {
    unawaited(ref.read(desktopWindowControllerProvider).requestClose());
  }

  @override
  Widget build(BuildContext context) {
    if (isDesktopPlatform) {
      ref
        ..watch(prayerAlertSchedulerProvider)
        ..watch(desktopTraySyncProvider);
    }
    return widget.child;
  }
}

/// Initializes [localNotifier] during desktop startup.
Future<void> initDesktopNotifications() async {
  if (!isDesktopPlatform) return;
  await localNotifier.setup(
    appName: 'Tawaq',
  );
}
