import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/feature/settings/data/models/theme_prefs.dart';
import 'package:tawaq/feature/settings/presentation/provider/theme_settings_provider.dart';
import 'package:tawaq/gen/fonts.gen.dart';
import 'package:tawaq/theme/theme.dart';
import 'package:tawaq/theme/theme_model.dart';

part 'app_theme_builder.g.dart';

bool _isTouchThemePlatform() =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.fuchsia);

/// Builds the root [FThemeData] with palette, density, text scale, and app font.
FThemeData buildAppTheme({
  required AppPalette palette,
  required ThemeMode themeMode,
  required bool touch,
  required double textScale,
  List<ThemeExtension<dynamic>> extensions = const [
    AppRadii.standard(),
    AppDurations.standard(),
  ],
}) {
  final base = resolveColorScheme(palette, themeMode, touch: touch);
  final typeface = FTypeface.inherit(
    colors: base.colors,
    touch: touch,
    fontFamily: FontFamily.iBMPlexSansArabic,
  );
  final typography = FTypography(
    display: typeface,
    body: typeface,
  ).scale(sizeScalar: textScale);

  return FThemeData(
    colors: base.colors,
    touch: touch,
    typography: typography,
    style: base.style,
    icons: base.icons,
    buttonStyles: base.buttonStyles,
    extensions: extensions,
  );
}

/// Appearance-only theme (palette + mode + density), excluding text scale.
@Riverpod(keepAlive: true)
FThemeData appThemeData(Ref ref) {
  final palette = ref.watch(
    themeProvider.select((t) => t.value?.appPalette ?? AppPalette.manuscript),
  );
  final themeMode = ref.watch(
    themeProvider.select((t) => t.value?.themeMode ?? ThemeMode.light),
  );
  return buildAppTheme(
    palette: palette,
    themeMode: themeMode,
    touch: _isTouchThemePlatform(),
    textScale: 1,
  );
}

/// Applies persisted app text scale on top of [appThemeDataProvider].
@Riverpod(keepAlive: true)
FThemeData appThemeWithTextScale(Ref ref) {
  final base = ref.watch(appThemeDataProvider);
  final scale = ref.watch(
    themeProvider.select(
      (t) => (t.value ?? ThemePrefs.defaults()).appTextScale.scalar,
    ),
  );
  return buildAppTheme(
    palette: ref.read(
      themeProvider.select((t) => t.value?.appPalette ?? AppPalette.manuscript),
    ),
    themeMode: ref.read(
      themeProvider.select((t) => t.value?.themeMode ?? ThemeMode.light),
    ),
    touch: _isTouchThemePlatform(),
    textScale: scale,
    extensions: List<ThemeExtension<dynamic>>.from(base.extensions),
  );
}
