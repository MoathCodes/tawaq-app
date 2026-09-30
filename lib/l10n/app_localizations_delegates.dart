import 'package:material_ui/material_ui.dart';
import 'package:tawaq/l10n/app_localizations.dart';

/// App translations with the standalone Material and Cupertino delegates.
///
/// Flutter 3.47 gen-l10n still emits legacy framework delegates. Keep generated
/// translations intact and use this list for Material UI app and test hosts.
const appLocalizationsDelegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  ...GlobalMaterialLocalizations.delegates,
];
