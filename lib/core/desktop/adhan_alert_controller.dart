import 'dart:async';
import 'dart:ui';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:forui/forui.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:tawaq/core/audio/audio_player_provider.dart';
import 'package:tawaq/core/desktop/adhan_alert_state.dart';
import 'package:tawaq/core/desktop/window_snapshot.dart';
import 'package:tawaq/core/locale/locale_provider.dart';
import 'package:tawaq/core/utils/platform.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_alert_kind.dart';
import 'package:tawaq/feature/prayer/domain/prayer_extensions.dart';
import 'package:tawaq/feature/prayer/domain/services/prayer_alert_resolver.dart';
import 'package:tawaq/feature/settings/data/models/adhan_settings.dart';
import 'package:tawaq/feature/settings/presentation/provider/adhan_settings_provider.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:window_manager/window_manager.dart';

part 'adhan_alert_controller.g.dart';

const _prayerNotificationId = 'tawaq-prayer-alert';
const _notifyOnlyDismissTimeout = Duration(seconds: 30);

/// Controls prayer alert overlay, window morph, OS notification, and toast.
@Riverpod(keepAlive: true)
class AdhanAlertController extends _$AdhanAlertController {
  WindowSnapshot? _snapshot;
  AlertWindowFlags? _overlayFlags;
  LocalNotification? _notification;
  FToasterEntry? _toastEntry;
  Timer? _notifyOnlyDismissTimer;
  bool _dismissing = false;
  bool _showInFlight = false;
  int _alertGeneration = 0;

  @override
  AdhanAlertState build() => const AdhanAlertState.idle();

  /// Registers the in-app toast shown during overlay-mode alerts.
  void registerToastEntry(FToasterEntry entry) {
    _toastEntry?.dismiss();
    _toastEntry = entry;
  }

  /// Presents alert UI and/or OS notification for [target].
  Future<void> present({
    required PrayerAlertTarget target,
    required bool showInApp,
    required bool showOsNotification,
    bool playsSound = false,
  }) async {
    if (!isDesktopPlatform) return;

    if (state.isShowing && !_dismissing) {
      await dismiss();
    }

    if (_showInFlight) return;

    final generation = ++_alertGeneration;

    if (showOsNotification) {
      await _showOsNotification(
        prayer: target.prayer,
        kind: target.kind,
        generation: generation,
      );
    }

    if (!showInApp) return;

    final settings = await ref.read(adhanSettingsProvider.future);

    _showInFlight = true;
    WindowSnapshot? pendingSnapshot;
    AlertWindowFlags? pendingOverlayFlags;

    try {
      final wasVisible = await windowManager.isVisible();
      final compactMorph = !wasVisible;

      if (compactMorph) {
        pendingSnapshot = await WindowSnapshot.capture();
        await windowManager.show();
        await _morphToCompact(settings);
      } else {
        pendingOverlayFlags = await AlertWindowFlags.capture();
      }

      await windowManager.focus();
      await windowManager.setAlwaysOnTop(true);

      _snapshot = pendingSnapshot;
      _overlayFlags = pendingOverlayFlags;
      pendingSnapshot = null;
      pendingOverlayFlags = null;

      state = AdhanAlertState(
        kind: target.kind,
        prayer: target.prayer,
        scheduledTime: target.scheduledTime,
        isCompactMorph: compactMorph,
        playsSound: playsSound,
      );

      _scheduleNotifyOnlyDismiss(playsSound: playsSound);
    } on Object {
      _alertGeneration++;
      unawaited(_notification?.close());
      _notification = null;
      if (pendingSnapshot != null) {
        await pendingSnapshot.restore();
      } else if (pendingOverlayFlags != null) {
        await pendingOverlayFlags.restore();
      }
    } finally {
      _showInFlight = false;
    }
  }

  /// Brings the app and active alert to the foreground.
  Future<void> focusAlert() async {
    if (!isDesktopPlatform) return;

    await windowManager.show();
    await windowManager.focus();
    if (state.isShowing) {
      await windowManager.setAlwaysOnTop(true);
    }
  }

  /// Dismisses the alert and stops playback.
  Future<void> dismiss() async {
    if (_dismissing || !state.isShowing) return;
    _dismissing = true;
    _alertGeneration++;
    _cancelNotifyOnlyDismissTimer();
    try {
      await ref.read(audioPlayerControllerProvider.notifier).stop();
      unawaited(_notification?.close());
      _notification = null;
      _dismissToast();
      await _restoreWindowArtifacts();
      state = const AdhanAlertState.idle();
    } finally {
      _dismissing = false;
    }
  }

  void _dismissToast() {
    _toastEntry?.dismiss();
    _toastEntry = null;
  }

  void _scheduleNotifyOnlyDismiss({required bool playsSound}) {
    _cancelNotifyOnlyDismissTimer();
    if (playsSound) return;

    _notifyOnlyDismissTimer = Timer(_notifyOnlyDismissTimeout, () {
      unawaited(dismiss());
    });
  }

  void _cancelNotifyOnlyDismissTimer() {
    _notifyOnlyDismissTimer?.cancel();
    _notifyOnlyDismissTimer = null;
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
    final position = resolveAdhanAlertCompactOrigin(
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

  Future<void> _showOsNotification({
    required Prayer prayer,
    required PrayerAlertKind kind,
    required int generation,
  }) async {
    final lang = ref.read(localeProvider);
    final l10n = lookupAppLocalizations(Locale(lang));
    final title = switch (kind) {
      PrayerAlertKind.adhan => l10n.adhanAlertTitle(prayer.getLocaleName(l10n)),
      PrayerAlertKind.iqamah =>
        l10n.iqamahAlertTitle(prayer.getLocaleName(l10n)),
      PrayerAlertKind.sunnah =>
        l10n.sunnahAlertTitle(prayer.getLocaleName(l10n)),
    };
    final body = switch (kind) {
      PrayerAlertKind.adhan => l10n.adhanOsNotificationBody,
      PrayerAlertKind.iqamah => l10n.iqamahOsNotificationBody,
      PrayerAlertKind.sunnah => l10n.sunnahOsNotificationBody,
    };

    final notification = LocalNotification(
      identifier: _prayerNotificationId,
      title: title,
      body: body,
    )..onClick = () => unawaited(focusAlert());

    await notification.show();
    if (generation != _alertGeneration) {
      unawaited(notification.close());
      return;
    }

    _notification = notification;
  }
}
