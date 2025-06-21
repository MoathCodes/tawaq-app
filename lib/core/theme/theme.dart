import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hasanat/core/theme/custom_themes.dart';
import 'package:hasanat/l10n/app_localizations.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

part 'theme.freezed.dart';

final defaultTheme = ThemeSettings(
  appPalette: AppPalette.islamic,
  colorScheme: IslamicTheme.lightIslamic(),
  themeMode: ThemeMode.light,
);

final Map<String, List<ColorScheme>> _palettesData = {
  'Islamic': [IslamicTheme.darkIslamic(), IslamicTheme.lightIslamic()],
  'Blue': [ColorSchemes.darkBlue(), ColorSchemes.lightBlue()],
  'Orange': [ColorSchemes.darkOrange(), ColorSchemes.lightOrange()],
  'Neutral': [ColorSchemes.darkNeutral(), ColorSchemes.lightNeutral()],
  'Red': [ColorSchemes.darkRed(), ColorSchemes.lightRed()],
  'Green': [ColorSchemes.darkGreen(), ColorSchemes.lightGreen()],
  'Rose': [ColorSchemes.darkRose(), ColorSchemes.lightRose()],
  'Slate': [ColorSchemes.darkSlate(), ColorSchemes.lightSlate()],
  'Stone': [ColorSchemes.darkStone(), ColorSchemes.lightStone()],
  'Violet': [ColorSchemes.darkViolet(), ColorSchemes.lightViolet()],
  'Yellow': [ColorSchemes.darkYellow(), ColorSchemes.lightYellow()],
  'Zinc': [ColorSchemes.darkZinc(), ColorSchemes.lightZinc()],
};

ColorScheme resolveColorScheme(AppPalette palette, ThemeMode themeMode) {
  final paletteKey = palette.key;
  final schemesList = _palettesData[paletteKey];

  if (schemesList == null || schemesList.length != 2) {
    debugPrint(
        "Warning: Theme data for $paletteKey not found or incomplete. Falling back to Neutral.");
    final defaultSchemes = _palettesData[AppPalette.neutral.key]!;
    return themeMode == ThemeMode.dark ? defaultSchemes[0] : defaultSchemes[1];
  }
  return themeMode == ThemeMode.dark ? schemesList[0] : schemesList[1];
}

enum AppPalette {
  islamic("Islamic"),
  blue("Blue"),
  orange("Orange"),
  green("Green"),
  neutral("Neutral"),
  red("Red"),
  rose("Rose"),
  slate("Slate"),
  stone("Stone"),
  violet("Violet"),
  yellow("Yellow"),
  zinc("Zinc");

  final String key;

  const AppPalette(this.key);
}

@freezed
abstract class ThemeSettings with _$ThemeSettings {
  const factory ThemeSettings({
    required AppPalette appPalette,
    required ColorScheme colorScheme,
    required ThemeMode themeMode,
  }) = _ThemeSettings;

  factory ThemeSettings.defaultSettings() {
    return ThemeSettings(
      appPalette: AppPalette.islamic,
      colorScheme: IslamicTheme.lightIslamic(),
      themeMode: ThemeMode.light,
    );
  }
}

extension AppPaletteLocale on AppPalette {
  String getLocaleName(AppLocalizations locale) {
    switch (this) {
      case AppPalette.blue:
        return locale.blue;
      case AppPalette.orange:
        return locale.orange;
      case AppPalette.green:
        return locale.green;
      case AppPalette.neutral:
        return locale.neutral;
      case AppPalette.red:
        return locale.red;
      case AppPalette.rose:
        return locale.rose;
      case AppPalette.slate:
        return locale.slate;
      case AppPalette.stone:
        return locale.stone;
      case AppPalette.violet:
        return locale.violet;
      case AppPalette.yellow:
        return locale.yellow;
      case AppPalette.zinc:
        return locale.zinc;
      case AppPalette.islamic:
        return locale.islamicTheme;
    }
  }
}
