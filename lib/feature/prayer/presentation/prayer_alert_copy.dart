import 'package:tawaq/feature/prayer/domain/models/prayer_alert_kind.dart';
import 'package:tawaq/l10n/app_localizations.dart';

/// Localized title for the in-app alert card / OS notification.
String prayerAlertTitle(
  AppLocalizations l10n,
  PrayerAlertKind kind,
  String prayerName,
) {
  return switch (kind) {
    PrayerAlertKind.adhan => l10n.adhanAlertTitle(prayerName),
    PrayerAlertKind.iqamah => l10n.iqamahAlertTitle(prayerName),
    PrayerAlertKind.sunnah => l10n.sunnahAlertTitle(prayerName),
  };
}

/// Localized title shown while alert audio is playing.
String prayerAlertSoundTitle(
  AppLocalizations l10n,
  PrayerAlertKind kind,
  String prayerName,
) {
  return switch (kind) {
    PrayerAlertKind.adhan => l10n.adhanPlayingTitle(prayerName),
    PrayerAlertKind.iqamah => l10n.iqamahPlayingTitle(prayerName),
    PrayerAlertKind.sunnah => l10n.sunnahAlertTitle(prayerName),
  };
}

/// Localized OS notification body for a prayer alert.
String prayerAlertOsBody(AppLocalizations l10n, PrayerAlertKind kind) {
  return switch (kind) {
    PrayerAlertKind.adhan => l10n.adhanOsNotificationBody,
    PrayerAlertKind.iqamah => l10n.iqamahOsNotificationBody,
    PrayerAlertKind.sunnah => l10n.sunnahOsNotificationBody,
  };
}
