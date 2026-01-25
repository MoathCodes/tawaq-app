import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hasanat/l10n/app_localizations.dart';
import 'package:hasanat/theme/custom_themes.dart';

part 'theme_model.freezed.dart';

/// Fallback theme settings used when persisted preferences are unavailable.
final defaultTheme = ThemeSettings(
  appPalette: AppPalette.zinc,
  colorScheme: FThemes.zinc.light,
  themeMode: ThemeMode.light,
);

final Map<String, List<FThemeData>> _palettesData = {
  'Manuscript': [
    ManuscriptTheme.darkManuscript,
    ManuscriptTheme.lightManuscript,
  ],
  'Blue': [FThemes.blue.dark, FThemes.blue.light],
  'Orange': [FThemes.orange.dark, FThemes.orange.light],
  // 'Neutral': [FThemes.neutral.dark, FThemes.neutral.light],
  'Red': [FThemes.red.dark, FThemes.red.light],
  'Green': [FThemes.green.dark, FThemes.green.light],
  'Rose': [FThemes.rose.dark, FThemes.rose.light],
  'Slate': [FThemes.slate.dark, FThemes.slate.light],
  // 'Stone': [FThemes.stone.dark, FThemes.stone.light],
  'Violet': [FThemes.violet.dark, FThemes.violet.light],
  'Yellow': [FThemes.yellow.dark, FThemes.yellow.light],
  'Zinc': [FThemes.zinc.dark, FThemes.zinc.light],
};

/// Returns the [FThemeData] matching the selected [palette] and [themeMode].
///
/// Falls back to the zinc palette when the mapping is missing or malformed,
/// logging a warning for easier troubleshooting.
FThemeData resolveColorScheme(AppPalette palette, ThemeMode themeMode) {
  final paletteKey = palette.key;
  final schemesList = _palettesData[paletteKey];

  if (schemesList == null || schemesList.length != 2) {
    debugPrint(
      'Warning: Theme data for $paletteKey not found or incomplete. '
      'Falling back to Zinc.',
    );
    final defaultSchemes = _palettesData[AppPalette.zinc.key]!;
    return themeMode == ThemeMode.dark ? defaultSchemes[0] : defaultSchemes[1];
  }
  return themeMode == ThemeMode.dark ? schemesList[0] : schemesList[1];
}

/// Available color palettes exposed to the settings UI.
enum AppPalette {
  /// Rich parchment-inspired palette.
  manuscript('Manuscript'),

  /// Vibrant blue palette derived from Forui presets.
  blue('Blue'),

  /// Bright orange palette for high-contrast UI.
  orange('Orange'),

  /// Calming green palette.
  green('Green'),
  // neutral("Neutral"),
  /// Warm red palette.
  red('Red'),

  /// Soft rose palette.
  rose('Rose'),

  /// Subtle slate palette.
  slate('Slate'),
  // stone("Stone"),
  /// Deep violet palette.
  violet('Violet'),

  /// Energetic yellow palette.
  yellow('Yellow'),

  /// Default zinc palette.
  zinc('Zinc')
  ;

  const AppPalette(this.key);

  /// Localization/lookup key pointing to palette metadata.
  final String key;
}

/// Immutable theme configuration shared across the app.
@freezed
abstract class ThemeSettings with _$ThemeSettings {
  /// Creates a theme configuration with explicit palette, scheme, and mode.
  const factory ThemeSettings({
    required AppPalette appPalette,
    required FThemeData colorScheme,
    required ThemeMode themeMode,
  }) = _ThemeSettings;
}

/// Adds localized names for palettes used in the theme selector UI.
extension AppPaletteLocale on AppPalette {
  /// Returns the localized display name for this palette.
  String getLocaleName(AppLocalizations locale) {
    switch (this) {
      case AppPalette.blue:
        return locale.blue;
      case AppPalette.orange:
        return locale.orange;
      case AppPalette.green:
        return locale.green;
      // case AppPalette.neutral:
      //   return locale.neutral;
      case AppPalette.red:
        return locale.red;
      case AppPalette.rose:
        return locale.rose;
      case AppPalette.slate:
        return locale.slate;
      // case AppPalette.stone:
      //   return locale.stone;
      case AppPalette.violet:
        return locale.violet;
      case AppPalette.yellow:
        return locale.yellow;
      case AppPalette.zinc:
        return locale.zinc;
      case AppPalette.manuscript:
        return locale.islamicTheme;
    }
  }
}
