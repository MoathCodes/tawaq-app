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
  // ─────────────────────────────────────────────────────────────────────────
  // SHARED COLOR CONSTANTS
  // ─────────────────────────────────────────────────────────────────────────
  // Primary gold hue - the signature accent color for both themes
  static const double _primaryHue = 42;
  // Warm undertone hue - for backgrounds and surfaces
  static const double _warmHue = 35;

  /// Dark variant of the Manuscript theme.
  ///
  /// Uses deep charcoal with subtle warm undertones (not brown!) to create
  /// an elegant, legible dark appearance. The golden accents remain vibrant
  /// while text uses warm cream tones for comfortable reading.
  ///
  /// **Key Design Decisions:**
  /// - Background: Deep charcoal (L: 11%) with minimal warm saturation
  /// - Surfaces: Slightly elevated (L: 14-16%) for layering
  /// - Text: Warm cream/ivory matching light theme's parchment feel
  /// - Primary: Same rich gold, slightly lighter for dark mode visibility
  /// - Borders: Subtle warm gray, not overtly brown
  static final FThemeData darkManuscript = FThemeData(
    colors: FColors(
      brightness: Brightness.dark,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      barrier: Colors.black.withValues(alpha: 0.75),

      // Deep charcoal with very subtle warmth - NOT brown
      // Low saturation (8%) keeps it neutral but not cold
      background: const HSLColor.fromAHSL(1, _warmHue, 0.08, 0.11).toColor(),

      // Warm cream foreground - mirrors light theme's parchment background
      // This creates the "inverted" feel where text looks like parchment
      foreground: const HSLColor.fromAHSL(1, 40, 0.30, 0.90).toColor(),

      // Rich gold primary - slightly higher lightness for dark mode
      // Maintains the same hue and saturation as light theme
      primary: const HSLColor.fromAHSL(1, _primaryHue, 0.80, 0.50).toColor(),
      primaryForeground: const HSLColor.fromAHSL(
        1,
        _warmHue,
        0.10,
        0.08,
      ).toColor(),

      // Secondary surfaces - slightly elevated, subtle warm tint
      secondary: const HSLColor.fromAHSL(1, _warmHue, 0.10, 0.16).toColor(),
      secondaryForeground: const HSLColor.fromAHSL(1, 40, 0.25, 0.88).toColor(),

      // Muted elements - for subtle backgrounds and less important text
      muted: const HSLColor.fromAHSL(1, _warmHue, 0.08, 0.18).toColor(),
      mutedForeground: const HSLColor.fromAHSL(1, 38, 0.15, 0.60).toColor(),

      // Destructive actions - warm red, visible against dark background
      destructive: const HSLColor.fromAHSL(1, 0, 0.72, 0.55).toColor(),
      destructiveForeground: const HSLColor.fromAHSL(
        1,
        40,
        0.20,
        0.95,
      ).toColor(),

      // Error - slightly different shade for distinction from destructive
      error: const HSLColor.fromAHSL(1, 5, 0.75, 0.58).toColor(),
      errorForeground: const HSLColor.fromAHSL(1, 40, 0.20, 0.95).toColor(),

      // Borders - subtle warm gray, provides definition without harshness
      border: const HSLColor.fromAHSL(1, _warmHue, 0.10, 0.22).toColor(),
    ),
  );

  /// Light variant of the Manuscript theme.
  ///
  /// Provides a warm, authentic parchment-like background with rich
  /// contrast and accessible semantic colors. Optimized for readability
  /// and a premium manuscript aesthetic.
  ///
  /// **Key Design Decisions:**
  /// - Background: Warm cream/ivory parchment (L: 95%)
  /// - Surfaces: Slightly darker cream for layering
  /// - Text: Deep brown-black for excellent contrast
  /// - Primary: Rich, deep gold for elegant accents
  /// - Borders: Warm tan that complements the parchment
  static final FThemeData lightManuscript = FThemeData(
    colors: FColors(
      brightness: Brightness.light,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      barrier: Colors.black.withValues(alpha: 0.15),

      // Warm parchment/ivory background
      background: const HSLColor.fromAHSL(1, 40, 0.40, 0.95).toColor(),

      // Deep warm brown-black for excellent readability
      foreground: const HSLColor.fromAHSL(1, 25, 0.45, 0.18).toColor(),

      // Deep, rich gold primary - the signature accent
      primary: const HSLColor.fromAHSL(1, _primaryHue, 0.85, 0.38).toColor(),
      primaryForeground: const HSLColor.fromAHSL(1, 45, 0.30, 0.98).toColor(),

      // Secondary surfaces - slightly darker parchment for cards/buttons
      secondary: const HSLColor.fromAHSL(1, 38, 0.30, 0.85).toColor(),
      secondaryForeground: const HSLColor.fromAHSL(1, 25, 0.40, 0.22).toColor(),

      // Muted elements - subtle cream for backgrounds
      muted: const HSLColor.fromAHSL(1, 38, 0.25, 0.88).toColor(),
      mutedForeground: const HSLColor.fromAHSL(1, 25, 0.30, 0.45).toColor(),

      // Destructive actions - visible yet harmonious red
      destructive: const HSLColor.fromAHSL(1, 0, 0.72, 0.45).toColor(),
      destructiveForeground: const HSLColor.fromAHSL(
        1,
        45,
        0.30,
        0.98,
      ).toColor(),

      // Error - warm red for form validation
      error: const HSLColor.fromAHSL(1, 5, 0.78, 0.48).toColor(),
      errorForeground: const HSLColor.fromAHSL(1, 45, 0.30, 0.98).toColor(),

      // Borders - warm tan that defines without overwhelming
      border: const HSLColor.fromAHSL(1, 35, 0.25, 0.72).toColor(),
    ),
  );
}
