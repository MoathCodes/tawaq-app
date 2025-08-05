import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';

class ManuscriptTheme {
  /// Dark Manuscript → FColors (Improved)
  static final FThemeData darkManuscript = FThemeData(
    colors: FColors(
      brightness: Brightness.dark,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      barrier: Colors.black54,

      // Slightly lighter background for better readability
      background: const HSLColor.fromAHSL(1, 25.0, 0.25, 0.16).toColor(),
      // Higher contrast cream foreground
      foreground: const HSLColor.fromAHSL(1, 45.0, 0.30, 0.92).toColor(),

      // More vibrant gold primary with better contrast
      primary: const HSLColor.fromAHSL(1, 43.0, 0.75, 0.55).toColor(),
      primaryForeground: const HSLColor.fromAHSL(1, 25.0, 0.25, 0.12).toColor(),

      // Better secondary with more distinction
      secondary: const HSLColor.fromAHSL(1, 28.0, 0.20, 0.28).toColor(),
      secondaryForeground:
          const HSLColor.fromAHSL(1, 45.0, 0.25, 0.85).toColor(),

      // More visible muted colors
      muted: const HSLColor.fromAHSL(1, 26.0, 0.18, 0.24).toColor(),
      mutedForeground: const HSLColor.fromAHSL(1, 40.0, 0.20, 0.70).toColor(),

      // Warmer, more visible destructive
      destructive: const HSLColor.fromAHSL(1, 12.0, 0.70, 0.58).toColor(),
      destructiveForeground:
          const HSLColor.fromAHSL(1, 45.0, 0.30, 0.95).toColor(),

      // Slightly different error tone
      error: const HSLColor.fromAHSL(1, 0.0, 0.68, 0.60).toColor(),
      errorForeground: const HSLColor.fromAHSL(1, 45.0, 0.30, 0.95).toColor(),

      // More visible border
      border: const HSLColor.fromAHSL(1, 28.0, 0.15, 0.35).toColor(),
    ),
  );

  /// Light Manuscript → FColors (Improved)
  static final FThemeData lightManuscript = FThemeData(
    colors: FColors(
      brightness: Brightness.light,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      barrier: Colors.black38,

      // Warmer, more authentic parchment background
      background: const HSLColor.fromAHSL(1, 38.0, 0.35, 0.95).toColor(),
      // Darker, more readable foreground with better contrast
      foreground: const HSLColor.fromAHSL(1, 20.0, 0.40, 0.20).toColor(),

      // Deeper, richer primary gold
      primary: const HSLColor.fromAHSL(1, 42.0, 0.85, 0.35).toColor(),
      primaryForeground: const HSLColor.fromAHSL(1, 45.0, 0.25, 0.98).toColor(),

      // Better contrast secondary
      secondary: const HSLColor.fromAHSL(1, 35.0, 0.25, 0.82).toColor(),
      secondaryForeground:
          const HSLColor.fromAHSL(1, 20.0, 0.35, 0.25).toColor(),

      // More distinct muted colors
      muted: const HSLColor.fromAHSL(1, 36.0, 0.20, 0.85).toColor(),
      mutedForeground: const HSLColor.fromAHSL(1, 22.0, 0.30, 0.45).toColor(),

      // More visible destructive action
      destructive: const HSLColor.fromAHSL(1, 358.0, 0.75, 0.45).toColor(),
      destructiveForeground:
          const HSLColor.fromAHSL(1, 45.0, 0.25, 0.98).toColor(),

      // Slightly different error color
      error: const HSLColor.fromAHSL(1, 2.0, 0.80, 0.48).toColor(),
      errorForeground: const HSLColor.fromAHSL(1, 45.0, 0.25, 0.98).toColor(),

      // More defined border
      border: const HSLColor.fromAHSL(1, 32.0, 0.20, 0.75).toColor(),
    ),
  );
}
