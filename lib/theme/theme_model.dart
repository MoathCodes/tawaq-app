import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/custom_themes.dart';

part 'theme_model.freezed.dart';

/// Fallback theme settings used when persisted preferences are unavailable.
final defaultTheme = ThemeSettings(
  appPalette: AppPalette.manuscript,
  colorScheme: ManuscriptTheme.lightManuscript.desktop,
  themeMode: ThemeMode.light,
);

final Map<String, List<FPlatformThemeData>> _palettesData = {
  'Manuscript': [
    ManuscriptTheme.darkManuscript,
    ManuscriptTheme.lightManuscript,
  ],
  'Neutral': [FTheme.neutral.dark, FTheme.neutral.light],
};

/// Parses a persisted palette name; unknown legacy values map to Manuscript.
AppPalette appPaletteFromJson(Object? json) {
  if (json is! String) return AppPalette.manuscript;
  for (final palette in AppPalette.values) {
    if (palette.name == json || palette.key == json) return palette;
  }
  return AppPalette.manuscript;
}

/// Serializes [palette] for JSON persistence.
String appPaletteToJson(AppPalette palette) => palette.name;

/// Returns the [FPlatformThemeData] matching [palette] and [themeMode].
///
/// Falls back to Neutral when the mapping is missing or malformed,
/// logging a warning for easier troubleshooting.
FPlatformThemeData resolvePlatformColorScheme(
  AppPalette palette,
  ThemeMode themeMode,
) {
  final paletteKey = palette.key;
  final schemesList = _palettesData[paletteKey];

  if (schemesList == null || schemesList.length != 2) {
    debugPrint(
      'Warning: Theme data for $paletteKey not found or incomplete. '
      'Falling back to Neutral.',
    );
    final defaultSchemes = _palettesData[AppPalette.neutral.key]!;
    return themeMode == ThemeMode.dark ? defaultSchemes[0] : defaultSchemes[1];
  }
  return themeMode == ThemeMode.dark ? schemesList[0] : schemesList[1];
}

/// Returns the resolved [FThemeData] variant for the selected platform density.
FThemeData resolveColorScheme(
  AppPalette palette,
  ThemeMode themeMode, {
  bool touch = false,
}) {
  final scheme = resolvePlatformColorScheme(palette, themeMode);
  return touch ? scheme.touch : scheme.desktop;
}

/// Available color palettes exposed to the settings UI.
enum AppPalette {
  /// Rich parchment-inspired palette.
  manuscript('Manuscript'),

  /// Forui neutral (shadcn) palette.
  neutral('Neutral');

  new(this.key);

  /// Localization/lookup key pointing to palette metadata.
  final String key;
}

/// Immutable theme configuration shared across the app.
@freezed
abstract class ThemeSettings with _$ThemeSettings {
  /// Creates a theme configuration with explicit palette, scheme, and mode.
  const factory({
    required AppPalette appPalette,
    required FThemeData colorScheme,
    required ThemeMode themeMode,
  }) = _ThemeSettings;
}

/// Adds localized names for palettes used in the theme selector UI.
extension AppPaletteLocale on AppPalette {
  /// Returns the localized display name for this palette.
  String getLocaleName(AppLocalizations locale) {
    return switch (this) {
      AppPalette.manuscript => locale.islamicTheme,
      AppPalette.neutral => locale.neutral,
    };
  }
}
