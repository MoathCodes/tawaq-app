import 'dart:ui';

import 'package:shadcn_flutter/shadcn_flutter.dart';

class IslamicTheme {
  // Enhanced Dark Islamic Theme - Better contrast and warmer tones
  static ColorScheme darkIslamic() {
    return ColorScheme(
      brightness: Brightness.dark,
      // Deeper, richer background - like aged leather manuscripts
      background: const HSLColor.fromAHSL(1, 28.0, 0.30, 0.12).toColor(),
      // Warmer, more readable cream foreground
      foreground: const HSLColor.fromAHSL(1, 42.0, 0.35, 0.88).toColor(),
      // Warmer card background with better contrast
      card: const HSLColor.fromAHSL(1, 30.0, 0.32, 0.16).toColor(),
      cardForeground: const HSLColor.fromAHSL(1, 42.0, 0.35, 0.88).toColor(),
      // Slightly elevated popover
      popover: const HSLColor.fromAHSL(1, 32.0, 0.28, 0.20).toColor(),
      popoverForeground: const HSLColor.fromAHSL(1, 42.0, 0.35, 0.88).toColor(),
      // Richer, more vibrant primary - like illuminated manuscript gold
      primary: const HSLColor.fromAHSL(1, 42.0, 0.65, 0.48).toColor(),
      // Lighter cream text for better contrast on golden primary buttons
      primaryForeground: const HSLColor.fromAHSL(1, 42.0, 0.40, 0.92).toColor(),
      // Better secondary with more warmth
      secondary: const HSLColor.fromAHSL(1, 30.0, 0.25, 0.22).toColor(),
      secondaryForeground:
          const HSLColor.fromAHSL(1, 42.0, 0.30, 0.78).toColor(),
      // Enhanced muted colors
      muted: const HSLColor.fromAHSL(1, 28.0, 0.22, 0.18).toColor(),
      mutedForeground: const HSLColor.fromAHSL(1, 38.0, 0.28, 0.60).toColor(),
      // Warmer accent matching the theme
      accent: const HSLColor.fromAHSL(0.25, 35.0, 0.60, 0.45)
          .toColor(), // Golden saffron accent
      accentForeground: const HSLColor.fromAHSL(1, 42.0, 0.30, 0.78).toColor(),
      // Warmer destructive that fits the palette
      destructive: const HSLColor.fromAHSL(1, 8.0, 0.65, 0.55).toColor(),
      destructiveForeground:
          const HSLColor.fromAHSL(1, 42.0, 0.35, 0.88).toColor(),
      // More defined borders
      border: const HSLColor.fromAHSL(1, 30.0, 0.22, 0.28).toColor(),
      input: const HSLColor.fromAHSL(1, 30.0, 0.25, 0.22).toColor(),
      // Golden ring to match primary
      ring: const HSLColor.fromAHSL(1, 42.0, 0.65, 0.48).toColor(),
      // Enhanced chart colors with better contrast
      chart1:
          const HSLColor.fromAHSL(1, 42.0, 0.65, 0.55).toColor(), // Warm gold
      chart2:
          const HSLColor.fromAHSL(1, 25.0, 0.55, 0.50).toColor(), // Rich brown
      chart3:
          const HSLColor.fromAHSL(1, 145.0, 0.40, 0.50).toColor(), // Sage green
      chart4: const HSLColor.fromAHSL(1, 15.0, 0.55, 0.55)
          .toColor(), // Warm terracotta
      chart5:
          const HSLColor.fromAHSL(1, 200.0, 0.40, 0.55).toColor(), // Muted teal
    );
  }

  // Light Islamic Theme - Inspired by traditional Islamic manuscripts and parchment
  static ColorScheme lightIslamic() {
    return ColorScheme(
      brightness: Brightness.light,
      // Warm sandy beige background like ancient parchment
      background: const HSLColor.fromAHSL(1, 35.0, 0.25, 0.92).toColor(),
      // Dark brown text like traditional ink
      foreground: const HSLColor.fromAHSL(1, 25.0, 0.35, 0.25).toColor(),
      // Slightly lighter beige for cards
      card: const HSLColor.fromAHSL(1, 38.0, 0.30, 0.95).toColor(),
      cardForeground: const HSLColor.fromAHSL(1, 25.0, 0.35, 0.25).toColor(),
      // Clean cream for popovers
      popover: const HSLColor.fromAHSL(1, 40.0, 0.35, 0.97).toColor(),
      popoverForeground: const HSLColor.fromAHSL(1, 25.0, 0.35, 0.25).toColor(),
      // Deeper golden primary for better contrast on light backgrounds
      primary: const HSLColor.fromAHSL(1, 42.0, 0.60, 0.40).toColor(),
      primaryForeground: const HSLColor.fromAHSL(1, 42.0, 0.40, 0.95).toColor(),
      // Soft beige secondary
      secondary: const HSLColor.fromAHSL(1, 35.0, 0.20, 0.85).toColor(),
      secondaryForeground:
          const HSLColor.fromAHSL(1, 25.0, 0.30, 0.30).toColor(),
      // Muted sand color
      muted: const HSLColor.fromAHSL(1, 32.0, 0.18, 0.88).toColor(),
      mutedForeground: const HSLColor.fromAHSL(1, 25.0, 0.25, 0.50).toColor(),
      // Golden accent for hover & highlights
      accent: const HSLColor.fromAHSL(0.25, 45.0, 0.65, 0.55)
          .toColor(), // Vibrant gold accent
      accentForeground: const HSLColor.fromAHSL(1, 25.0, 0.30, 0.30).toColor(),
      // Muted red for destructive actions
      destructive: const HSLColor.fromAHSL(1, 355.0, 0.60, 0.50).toColor(),
      destructiveForeground:
          const HSLColor.fromAHSL(1, 40.0, 0.35, 0.97).toColor(),
      // Very subtle borders
      border: const HSLColor.fromAHSL(1, 32.0, 0.15, 0.80).toColor(),
      input: const HSLColor.fromAHSL(1, 35.0, 0.20, 0.88).toColor(),
      // Golden ring matching new darker primary
      ring: const HSLColor.fromAHSL(1, 42.0, 0.60, 0.42).toColor(),
      // Chart colors inspired by manuscript illumination
      chart1: const HSLColor.fromAHSL(1, 42.0, 0.60, 0.50).toColor(), // Gold
      chart2: const HSLColor.fromAHSL(1, 25.0, 0.50, 0.45)
          .toColor(), // Brown swapped for variety
      chart3: const HSLColor.fromAHSL(1, 145.0, 0.40, 0.40)
          .toColor(), // Muted green
      chart4:
          const HSLColor.fromAHSL(1, 15.0, 0.60, 0.50).toColor(), // Terracotta
      chart5:
          const HSLColor.fromAHSL(1, 210.0, 0.30, 0.45).toColor(), // Muted blue
    );
  }
}
