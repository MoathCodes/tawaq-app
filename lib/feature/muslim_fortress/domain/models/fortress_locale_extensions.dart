import 'package:hisn_elmoslem/hisn_elmoslem.dart';
import 'package:tawaq/l10n/app_localizations.dart';

/// Localized recurrence label for fortress chapter subtitles.
String fortressRecurrenceLabel(
  HisnRecurrence recurrence,
  AppLocalizations l10n,
) =>
    switch (recurrence) {
      HisnRecurrence.daily => l10n.daily,
      HisnRecurrence.weekly => l10n.weekly,
      HisnRecurrence.monthly => l10n.monthly,
      HisnRecurrence.yearly => l10n.yearly,
    };

/// Localized reading-length hint from item count.
String fortressReadingDurationLabel(int itemCount, AppLocalizations l10n) {
  if (itemCount <= 3) return l10n.fortressReadShort;
  if (itemCount <= 8) return l10n.fortressReadMedium;
  return l10n.fortressReadLong;
}
