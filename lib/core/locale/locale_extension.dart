import 'package:hasanat/l10n/app_localizations.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

extension LocalizationExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
