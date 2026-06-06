import 'package:flutter/material.dart';
import 'package:forui/forui.dart' show FThemeData;
import 'package:forui/theme.dart' show FThemeData;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tawaq/feature/settings/data/models/app_text_scale.dart';
import 'package:tawaq/theme/theme_model.dart';

part 'theme_prefs.freezed.dart';
part 'theme_prefs.g.dart';

/// Persisted theme preferences (palette + mode).
///
/// The runtime [ThemeSettings] (which includes [FThemeData]) is derived from
/// these prefs at build time — only [AppPalette] and [ThemeMode] are stored.
@freezed
abstract class ThemePrefs with _$ThemePrefs {
  /// Creates a [ThemePrefs] instance.
  const factory ThemePrefs({
    /// The selected color palette.
    required AppPalette appPalette,

    /// The selected theme brightness mode.
    required ThemeMode themeMode,

    /// App-wide UI text scale (Forui typography + scaled ScreenUtil).
    @Default(AppTextScale.normal) AppTextScale appTextScale,
  }) = _ThemePrefs;

  /// Creates a [ThemePrefs] instance from a JSON map.
  factory ThemePrefs.fromJson(Map<String, dynamic> json) =>
      _$ThemePrefsFromJson(json);

  /// Default theme preferences.
  factory ThemePrefs.defaults() =>
      const ThemePrefs(
        appPalette: AppPalette.manuscript,
        themeMode: ThemeMode.light,
      );
}
