import 'package:tawaq/feature/prayer/domain/models/prayer_alert_kind.dart';
import 'package:tawaq/l10n/app_localizations.dart';

/// Localized title for a prayer alert toast or card.
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
