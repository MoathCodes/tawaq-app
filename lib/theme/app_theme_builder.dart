import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/gen/fonts.gen.dart';
import 'package:tawaq/theme/theme.dart';
import 'package:tawaq/theme/theme_model.dart';

/// Builds the root [FThemeData] with palette, density, text scale, and locale font.
FThemeData buildAppTheme({
  required AppPalette palette,
  required ThemeMode themeMode,
  required bool touch,
  required double textScale,
  required bool isArabic,
  List<ThemeExtension<dynamic>> extensions = const [
    AppRadii.standard(),
    AppDurations.standard(),
  ],
}) {
  final base = resolveColorScheme(palette, themeMode, touch: touch);
  final typography = _scaledTypography(
    base: base.typography,
    colors: base.colors,
    touch: touch,
    textScale: textScale,
    isArabic: isArabic,
  );

  return FThemeData(
    colors: base.colors,
    touch: touch,
    typography: typography,
    icons: base.icons,
    extensions: extensions,
  );
}

FTypography _scaledTypography({
  required FTypography base,
  required FColors colors,
  required bool touch,
  required double textScale,
  required bool isArabic,
}) {
  if (isArabic) {
    return FTypography.inherit(
      colors: colors,
      touch: touch,
      fontFamily: FontFamily.iBMPlexSansArabic,
    ).scale(sizeScalar: textScale);
  }

  if (textScale == 1.0) {
    return base;
  }

  return base.scale(sizeScalar: textScale);
}
