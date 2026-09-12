import 'package:adhan_dart/adhan_dart.dart';
import 'package:tawaq/l10n/app_localizations.dart';

/// Returns the localized state shown above the prayer name in the hero.
String prayerCardStateLabel({
  required AppLocalizations l10n,
  required Prayer prayer,
  required bool isCountdown,
}) {
  if (prayer.isObligatory) {
    return isCountdown ? l10n.nextPrayer : l10n.currentPrayer;
  }
  return isCountdown ? l10n.nextEvent : l10n.currentEvent;
}

/// Returns the localized direction for the hero's live duration.
String prayerCardDurationLabel({
  required AppLocalizations l10n,
  required Prayer prayer,
  required bool isCountdown,
}) {
  if (prayer.isObligatory) {
    return isCountdown ? l10n.prayerTimeRemaining : l10n.prayerTimeSinceStart;
  }
  return isCountdown ? l10n.eventTimeRemaining : l10n.eventTimeSinceStart;
}
