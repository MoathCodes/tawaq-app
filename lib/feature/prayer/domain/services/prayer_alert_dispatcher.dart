import 'dart:async';

import 'package:flutter/material.dart' show Locale;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/audio/audio_player_provider.dart';
import 'package:tawaq/core/audio/audio_track.dart';
import 'package:tawaq/core/desktop/adhan_alert_controller.dart';
import 'package:tawaq/core/locale/locale_provider.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_alert_kind.dart';
import 'package:tawaq/feature/prayer/domain/prayer_extensions.dart';
import 'package:tawaq/feature/prayer/domain/services/prayer_alert_resolver.dart';
import 'package:tawaq/feature/settings/presentation/provider/adhan_settings_provider.dart';
import 'package:tawaq/l10n/app_localizations.dart';

/// Dispatches a prayer alert across presentation and audio channels.
Future<void> dispatchPrayerAlert(
  Ref ref, {
  required PrayerAlertTarget target,
  required PrayerAlertDelivery delivery,
}) async {
  if (!delivery.hasAnyEffect) return;

  final alertController = ref.read(adhanAlertControllerProvider.notifier);
  final audio = ref.read(audioPlayerControllerProvider.notifier);
  await audio.stop();

  if (delivery.showInApp || delivery.showOsNotification) {
    if (ref.read(adhanAlertControllerProvider).isShowing) {
      await alertController.dismiss();
    }

    await alertController.present(
      target: target,
      showInApp: delivery.showInApp,
      showOsNotification: delivery.showOsNotification,
      playsSound: delivery.playSound,
    );
  }

  if (!delivery.playSound || delivery.soundAssetPath == null) return;

  final adhanSettings = ref.read(adhanSettingsProvider).value;
  if (adhanSettings == null) return;

  final lang = ref.read(localeProvider);
  final l10n = lookupAppLocalizations(Locale(lang));
  final prayerName = target.prayer.getLocaleName(l10n);
  final title = switch (target.kind) {
    PrayerAlertKind.adhan => l10n.adhanPlayingTitle(prayerName),
    PrayerAlertKind.iqamah => l10n.iqamahPlayingTitle(prayerName),
    PrayerAlertKind.sunnah => l10n.sunnahAlertTitle(prayerName),
  };

  await audio.setVolume(adhanSettings.volume);
  await audio.playTrack(
    AudioTrack.asset(
      id: '${target.kind.name}-${target.prayer.name}',
      title: title,
      assetPath: delivery.soundAssetPath!,
      subtitle: prayerName,
    ),
  );
}
