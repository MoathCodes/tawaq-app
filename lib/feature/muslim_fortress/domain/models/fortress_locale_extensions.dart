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
