import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart';

/// A collection of handcrafted theme presets inspired by manuscript
/// (parchment) aesthetics used across the app.
///
/// This class only exposes static [FThemeData] presets and exists as a
/// central place to select a stylistic theme variant: a dark and a
/// light "Manuscript" theme tuned for readability and contrast.
///
/// **Design Philosophy:**
/// Both themes share the same visual language - warm manuscript/parchment
/// aesthetic with rich golden accents. The dark theme is designed as a
/// true "inverted" version of the light theme, not a separate design.
class ManuscriptTheme {
  static const double _primaryHue = 42;
  static const double _warmHue = 35;

  /// Dark manuscript theme with both touch and desktop variants.
  static final FPlatformThemeData darkManuscript = FPlatformThemeData(
    touch: () => _darkThemeData(touch: true),
    desktop: () => _darkThemeData(touch: false),
  );

  /// Light manuscript theme with both touch and desktop variants.
  static final FPlatformThemeData lightManuscript = FPlatformThemeData(
    touch: () => _lightThemeData(touch: true),
    desktop: () => _lightThemeData(touch: false),
  );

  static FThemeData _darkThemeData({required bool touch}) {
    final colors = FColors(
      brightness: Brightness.dark,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      barrier: Colors.black.withValues(alpha: 0.75),
      background: const HSLColor.fromAHSL(1, _warmHue, 0.08, 0.11).toColor(),
      foreground: const HSLColor.fromAHSL(1, 40, 0.30, 0.90).toColor(),
      primary: const HSLColor.fromAHSL(1, _primaryHue, 0.80, 0.50).toColor(),
      primaryForeground: const HSLColor.fromAHSL(
        1,
        _warmHue,
        0.10,
        0.08,
      ).toColor(),
      secondary: const HSLColor.fromAHSL(1, _warmHue, 0.10, 0.18).toColor(),
      card: const HSLColor.fromAHSL(1, _warmHue, 0.09, 0.15).toColor(),
      secondaryForeground: const HSLColor.fromAHSL(1, 40, 0.25, 0.88).toColor(),
      muted: const HSLColor.fromAHSL(1, _warmHue, 0.08, 0.20).toColor(),
      mutedForeground: const HSLColor.fromAHSL(1, 38, 0.15, 0.60).toColor(),
      destructive: const HSLColor.fromAHSL(1, 0, 0.72, 0.66).toColor(),
      destructiveForeground: const HSLColor.fromAHSL(
        1,
        _warmHue,
        0.10,
        0.08,
      ).toColor(),
      error: const HSLColor.fromAHSL(1, 5, 0.75, 0.66).toColor(),
      errorForeground: const HSLColor.fromAHSL(
        1,
        _warmHue,
        0.10,
        0.08,
      ).toColor(),
      border: const HSLColor.fromAHSL(1, _warmHue, 0.10, 0.22).toColor(),
    );

    return _buildThemeData(colors: colors, touch: touch);
  }

  static FThemeData _lightThemeData({required bool touch}) {
    final colors = FColors(
      brightness: Brightness.light,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      barrier: Colors.black.withValues(alpha: 0.15),
      background: const HSLColor.fromAHSL(1, 40, 0.40, 0.95).toColor(),
      foreground: const HSLColor.fromAHSL(1, 25, 0.45, 0.18).toColor(),
      // Keep the gold accent warm and saturated while giving it enough depth
      // for both primary text on cards and its light foreground on controls.
      // This accent is also used for compact metadata labels and status copy
      // on the light secondary/muted surfaces, not only for borders and icons.
      // Keep the gold hue while giving those active labels a 4.5:1 floor.
      primary: const HSLColor.fromAHSL(1, _primaryHue, 0.85, 0.23).toColor(),
      primaryForeground: const HSLColor.fromAHSL(1, 45, 0.30, 0.98).toColor(),
      secondary: const HSLColor.fromAHSL(1, 38, 0.30, 0.84).toColor(),
      card: const HSLColor.fromAHSL(1, _primaryHue, 0.28, 0.88).toColor(),
      secondaryForeground: const HSLColor.fromAHSL(1, 25, 0.40, 0.22).toColor(),
      muted: const HSLColor.fromAHSL(1, 38, 0.25, 0.86).toColor(),
      // This role is used for normal metadata and supporting copy on card,
      // secondary, and muted surfaces, so it must remain readable on each.
      mutedForeground: const HSLColor.fromAHSL(1, 25, 0.30, 0.35).toColor(),
      destructive: const HSLColor.fromAHSL(1, 0, 0.72, 0.45).toColor(),
      destructiveForeground: const HSLColor.fromAHSL(
        1,
        45,
        0.30,
        0.98,
      ).toColor(),
      error: const HSLColor.fromAHSL(1, 5, 0.78, 0.42).toColor(),
      errorForeground: const HSLColor.fromAHSL(1, 45, 0.30, 0.98).toColor(),
      border: const HSLColor.fromAHSL(1, 35, 0.25, 0.72).toColor(),
    );

    return _buildThemeData(colors: colors, touch: touch);
  }

  static FThemeData _buildThemeData({
    required FColors colors,
    required bool touch,
  }) {
    final typography = FTypography.inherit(colors: colors, touch: touch);
    final style = _style(colors: colors, typography: typography, touch: touch);

    return FThemeData(
      colors: colors,
      typography: typography,
      style: style,
      touch: touch,
    );
  }

  static FStyle _style({
    required FColors colors,
    required FTypography typography,
    required bool touch,
  }) {
    const borderRadius = FBorderRadius();
    return FStyle(
      formFieldStyle: .inherit(
        colors: colors,
        typography: typography,
        touch: touch,
      ),
      focusedOutlineStyle: FFocusedOutlineStyle(
        color: colors.primary,
        borderRadius: borderRadius.md,
      ),
      sizes: FSizes.inherit(touch: touch),
      iconStyle: IconThemeData(
        color: colors.foreground,
        size: typography.body.lg.fontSize,
      ),
      tappableStyle: FTappableStyle(),
    );
  }
}

/// Parchment and sage roles derived from the approved Turning ت artwork.
///
/// The icon's #F7F4ED parchment and #37583C fold anchor the light theme.
/// Pale leaf highlights become the dark action color, paired with deep green
/// ink; they are never used as light-theme text. Surfaces carry tonal depth
/// without changing the app's spacing, typography, or component geometry.
class SageTheme {
  /// Light Sage in desktop and touch densities.
  static final FPlatformThemeData lightSage = FPlatformThemeData(
    touch: () => _build(lightColors, touch: true),
    desktop: () => _build(lightColors, touch: false),
  );

  /// Dark Sage in desktop and touch densities.
  static final FPlatformThemeData darkSage = FPlatformThemeData(
    touch: () => _build(darkColors, touch: true),
    desktop: () => _build(darkColors, touch: false),
  );

  /// Shared semantic light roles, also consumed by the Material bridge.
  static final FColors lightColors = FColors(
    brightness: Brightness.light,
    systemOverlayStyle: SystemUiOverlayStyle.dark,
    barrier: const Color(0xFF19251D).withValues(alpha: 0.20),
    background: const Color(0xFFF7F4ED),
    foreground: const Color(0xFF24382B),
    primary: const Color(0xFF37583C),
    primaryForeground: const Color(0xFFFFFDF7),
    card: const Color(0xFFFFFDF7),
    secondary: const Color(0xFFE4E8DA),
    secondaryForeground: const Color(0xFF2E4533),
    muted: const Color(0xFFEEEDE3),
    mutedForeground: const Color(0xFF52604C),
    border: const Color(0xFFBEC5B2),
    destructive: const Color(0xFFA33332),
    destructiveForeground: const Color(0xFFFFFDF7),
    error: const Color(0xFFA33332),
    errorForeground: const Color(0xFFFFFDF7),
  );

  /// Shared semantic dark roles with green charcoal and elevated olive planes.
  static final FColors darkColors = FColors(
    brightness: Brightness.dark,
    systemOverlayStyle: SystemUiOverlayStyle.light,
    barrier: const Color(0xFF0C120E).withValues(alpha: 0.75),
    background: const Color(0xFF171F19),
    foreground: const Color(0xFFF0EADF),
    primary: const Color(0xFFB9C78D),
    primaryForeground: const Color(0xFF1C2B20),
    card: const Color(0xFF212C23),
    secondary: const Color(0xFF303B2C),
    secondaryForeground: const Color(0xFFE6EAD9),
    muted: const Color(0xFF293329),
    mutedForeground: const Color(0xFFB6BDAA),
    border: const Color(0xFF475442),
    destructive: const Color(0xFFFFA49A),
    destructiveForeground: const Color(0xFF351C18),
    error: const Color(0xFFFFA49A),
    errorForeground: const Color(0xFF351C18),
  );

  static FThemeData _build(FColors colors, {required bool touch}) =>
      FThemeData(colors: colors, touch: touch);
}
