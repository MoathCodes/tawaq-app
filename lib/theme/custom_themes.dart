import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';

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
      destructive: const HSLColor.fromAHSL(1, 0, 0.72, 0.55).toColor(),
      destructiveForeground: const HSLColor.fromAHSL(
        1,
        40,
        0.20,
        0.95,
      ).toColor(),
      error: const HSLColor.fromAHSL(1, 5, 0.75, 0.58).toColor(),
      errorForeground: const HSLColor.fromAHSL(1, 40, 0.20, 0.95).toColor(),
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
      primary: const HSLColor.fromAHSL(1, _primaryHue, 0.85, 0.38).toColor(),
      primaryForeground: const HSLColor.fromAHSL(1, 45, 0.30, 0.98).toColor(),
      secondary: const HSLColor.fromAHSL(1, 38, 0.30, 0.84).toColor(),
      card: const HSLColor.fromAHSL(1, _primaryHue, 0.28, 0.88).toColor(),
      secondaryForeground: const HSLColor.fromAHSL(1, 25, 0.40, 0.22).toColor(),
      muted: const HSLColor.fromAHSL(1, 38, 0.25, 0.86).toColor(),
      mutedForeground: const HSLColor.fromAHSL(1, 25, 0.30, 0.45).toColor(),
      destructive: const HSLColor.fromAHSL(1, 0, 0.72, 0.45).toColor(),
      destructiveForeground: const HSLColor.fromAHSL(
        1,
        45,
        0.30,
        0.98,
      ).toColor(),
      error: const HSLColor.fromAHSL(1, 5, 0.78, 0.48).toColor(),
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
