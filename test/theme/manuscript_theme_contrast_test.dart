import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/theme/custom_themes.dart';

double _contrastRatio(Color foreground, Color background) {
  final foregroundLuminance = foreground.computeLuminance();
  final backgroundLuminance = background.computeLuminance();
  final lighter = foregroundLuminance > backgroundLuminance
      ? foregroundLuminance
      : backgroundLuminance;
  final darker = foregroundLuminance > backgroundLuminance
      ? backgroundLuminance
      : foregroundLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}

void _expectTextContrast(
  Color foreground,
  Color background, {
  required String pair,
  double minimum = 4.5,
}) {
  expect(
    _contrastRatio(foreground, background),
    greaterThanOrEqualTo(minimum),
    reason: '$pair should meet a $minimum:1 text contrast ratio',
  );
}

void _expectNonTextContrast(
  Color foreground,
  Color background, {
  required String pair,
}) {
  expect(
    _contrastRatio(foreground, background),
    greaterThanOrEqualTo(3),
    reason: '$pair should meet a 3:1 non-text contrast ratio',
  );
}

void _expectManuscriptContrast(FColors colors) {
  for (final surface in <String, Color>{
    'background': colors.background,
    'card': colors.card,
    'secondary': colors.secondary,
    'muted': colors.muted,
  }.entries) {
    _expectTextContrast(
      colors.mutedForeground,
      surface.value,
      pair: 'mutedForeground/${surface.key}',
    );
  }

  _expectTextContrast(
    colors.primaryForeground,
    colors.primary,
    pair: 'primaryForeground/primary',
  );
  _expectTextContrast(colors.primary, colors.card, pair: 'primary/card');
  _expectTextContrast(
    colors.secondaryForeground,
    colors.secondary,
    pair: 'secondaryForeground/secondary',
  );

  // These semantic colors are rendered directly as error copy in several
  // async/error states, not only as decorative status icons.
  _expectTextContrast(
    colors.destructive,
    colors.background,
    pair: 'destructive/background',
  );
  _expectTextContrast(
    colors.destructive,
    colors.card,
    pair: 'destructive/card',
  );
  _expectTextContrast(
    colors.error,
    colors.background,
    pair: 'error/background',
  );
  _expectTextContrast(colors.error, colors.card, pair: 'error/card');
  _expectTextContrast(
    colors.destructiveForeground,
    colors.destructive,
    pair: 'destructiveForeground/destructive',
  );
  _expectTextContrast(
    colors.errorForeground,
    colors.error,
    pair: 'errorForeground/error',
  );

  // Alert headers and selected tab indicators use a tinted blend rather than
  // a flat token, so verify the text against the resolved composite too.
  final alertHeaderSurface = Color.lerp(colors.primary, colors.card, 0.88)!;
  _expectTextContrast(
    colors.foreground,
    alertHeaderSurface,
    pair: 'foreground/primary-card composite',
  );
  final selectedIndicatorSurface = Color.alphaBlend(
    colors.primary.withValues(alpha: 0.18),
    colors.card,
  );
  _expectTextContrast(
    colors.foreground,
    selectedIndicatorSurface,
    pair: 'foreground/selected indicator composite',
  );

  // The focused outline is an actionable state indicator and must remain
  // visible against both common light/dark surfaces.
  _expectNonTextContrast(
    colors.primary,
    colors.background,
    pair: 'focus/background',
  );
  _expectNonTextContrast(colors.primary, colors.card, pair: 'focus/card');
}

void main() {
  test(
    'Manuscript light semantic roles meet contrast on their real surfaces',
    () {
      final colors = ManuscriptTheme.lightManuscript.desktop.colors;
      _expectManuscriptContrast(colors);
    },
  );

  test(
    'Manuscript dark semantic roles retain contrast on their real surfaces',
    () {
      final colors = ManuscriptTheme.darkManuscript.desktop.colors;
      _expectManuscriptContrast(colors);
    },
  );

  test('existing Neutral palette remains resolvable', () {
    expect(FTheme.neutral.light.desktop.colors, isNotNull);
    expect(FTheme.neutral.dark.desktop.colors, isNotNull);
  });
}
