import 'package:flutter/material.dart';
import 'package:hasanat/l10n/app_localizations.dart';

/// Provides quick access to localized strings from a [BuildContext].
extension LocalizationExtension on BuildContext {
  /// Returns the strongly typed localization instance for this context.
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
