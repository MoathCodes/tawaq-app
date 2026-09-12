import 'package:tawaq/l10n/app_localizations.dart';

/// Returns the localized state shown above the prayer name in the hero.
String prayerCardStateLabel({
  required AppLocalizations l10n,
  required bool isCountdown,
}) => isCountdown ? l10n.nextPrayer : l10n.currentPrayer;

/// Returns the localized direction for the hero's live duration.
String prayerCardDurationLabel({
  required AppLocalizations l10n,
  required bool isCountdown,
}) => isCountdown ? l10n.prayerTimeRemaining : l10n.prayerTimeSinceStart;
