import 'dart:async';
import 'dart:ui';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:tawaq/app/desktop/alerts/prayer_alert_dispatcher.dart';
import 'package:tawaq/core/desktop/window_snapshot.dart';
import 'package:tawaq/core/utils/platform.dart';
import 'package:tawaq/feature/prayer/domain/models/adhan_settings.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_alert_event.dart';
import 'package:tawaq/feature/prayer/domain/services/prayer_alert_channel.dart';
import 'package:tawaq/feature/prayer/presentation/provider/adhan_settings_provider.dart';
import 'package:window_manager/window_manager.dart';

part 'adhan_alert_controller.g.dart';

const double _adhanAlertScreenInset = 16;

Offset _resolveAdhanAlertCompactOrigin({
  required Rect screen,
  required AdhanAlertPosition alertPosition,
}) {
  const size = kAdhanAlertCompactSize;
  const inset = _adhanAlertScreenInset;
  return switch (alertPosition) {
    AdhanAlertPosition.center => Offset(
      screen.left + (screen.width - size.width) / 2,
      screen.top + (screen.height - size.height) / 2,
    ),
    AdhanAlertPosition.topEnd => Offset(
      screen.right - size.width - inset,
      screen.top + inset,
    ),
    AdhanAlertPosition.topStart => Offset(
      screen.left + inset,
      screen.top + inset,
    ),
  };
}

/// In-app prayer alert channel.
///
/// Owns the alert overlay, the window morph/restore, and the
/// native presentation adapter. It is intentionally visuals-only: sound
/// and OS notifications are separate channels, and preemption/completion are
/// coordinated by the dispatcher.
@Riverpod(keepAlive: true)
class AdhanAlertController extends _$AdhanAlertController
    implements PrayerAlertChannel {
  WindowSnapshot? _snapshot;
  AlertWindowFlags? _overlayFlags;

  @override
  void build() {}

  @override
  String get debugName => 'in-app';

  @override
  Future<void> deliver(PrayerAlertEvent event) async {
    if (!isDesktopPlatform || !event.showInApp) return;

    final settings =
        ref.read(adhanSettingsProvider).value ?? AdhanSettings.defaults();

    final wasVisible = await windowManager.isVisible();
    final compactMorph = !wasVisible;

    if (compactMorph) {
      _snapshot = await WindowSnapshot.capture();
      await windowManager.show();
      await _morphToCompact(settings);
    } else {
      _overlayFlags = await AlertWindowFlags.capture();
    }

    await windowManager.focus();
    await windowManager.setAlwaysOnTop(true);

    ref
        .read(prayerAlertSessionStateProvider.notifier)
        .setCompactMorph(value: compactMorph);
  }

  @override
  Future<void> cancel() async {
    // Restore even when `!isShowing`: a partial `deliver` may have captured
    // snapshot/flags and morphed the window before state was assigned.
    await _restoreWindowArtifacts();
  }

  /// Brings the app and active alert to the foreground.
  Future<void> focusAlert() async {
    if (!isDesktopPlatform) return;
    await windowManager.show();
    await windowManager.focus();
    if (ref.read(prayerAlertSessionStateProvider) != null) {
      await windowManager.setAlwaysOnTop(true);
    }
  }

  Future<void> _restoreWindowArtifacts() async {
    if (_snapshot != null) {
      await _snapshot!.restore();
      _snapshot = null;
    } else if (_overlayFlags != null) {
      await _overlayFlags!.restore();
      _overlayFlags = null;
    }
  }

  Future<void> _morphToCompact(AdhanSettings settings) async {
    final screen = await _primaryDisplayBounds();
    final position = _resolveAdhanAlertCompactOrigin(
      screen: screen,
      alertPosition: settings.alertPosition,
    );
    await windowManager.setMinimumSize(kAdhanAlertCompactSize);
    await windowManager.setSize(kAdhanAlertCompactSize);
    await windowManager.setPosition(position);
  }

  Future<Rect> _primaryDisplayBounds() async {
    final display = await screenRetriever.getPrimaryDisplay();
    final origin = display.visiblePosition ?? Offset.zero;
    final size = display.visibleSize ?? display.size;
    return Rect.fromLTWH(origin.dx, origin.dy, size.width, size.height);
  }
}
