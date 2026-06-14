import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/gen/fonts.gen.dart';
import 'package:tawaq/theme/theme.dart';
import 'package:tawaq/theme/theme_model.dart';

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
  final typography = FTypography.inherit(
    colors: base.colors,
    touch: touch,
    fontFamily: FontFamily.iBMPlexSansArabic,
  ).scale(sizeScalar: textScale);

  return FThemeData(
    colors: base.colors,
    touch: touch,
    typography: typography,
    icons: base.icons,
    extensions: extensions,
  );
}
