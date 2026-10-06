import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/tabs_styles.dart';
import 'package:tawaq/theme/theme_model.dart';

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

FThemeData _paletteTheme(
  AppPalette palette,
  ThemeMode mode, {
  bool touch = false,
}) => buildAppTheme(
  palette: palette,
  themeMode: mode,
  touch: touch,
  textScale: 1,
);

void _expectPaletteContrast(FThemeData theme) {
  final colors = theme.colors;

  // These are normal metadata/supporting-copy surfaces used by result cards,
  // settings, tabs, and the share cards. This intentionally does not include
  // disabled or decorative alpha-reduced marks.
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
    _expectTextContrast(
      colors.primary,
      surface.value,
      pair: 'primary/${surface.key} active label',
    );
  }

  // Hadith grading badges and the selected scale-step preview put the fully
  // opaque primary label on a translucent primary tint, rather than on the
  // raw background token.
  for (final surface in <String, Color>{
    'background': colors.background,
    'card': colors.card,
    'secondary': colors.secondary,
    'muted': colors.muted,
  }.entries) {
    final badgeSurface = Color.alphaBlend(
      colors.primary.withAlpha(28),
      surface.value,
    );
    _expectTextContrast(
      colors.primary,
      badgeSurface,
      pair: 'primary/primary-tinted ${surface.key} badge',
    );
  }
  _expectTextContrast(
    colors.primary,
    Color.alphaBlend(colors.primary.withValues(alpha: 0.12), colors.background),
    pair: 'primary/primary-tinted background scale preview',
  );

  // Quran selected ayahs and the recitation play control use the paired
  // foreground token on a primary fill. Error copy uses the semantic red
  // roles directly on the common content surfaces.
  _expectTextContrast(
    colors.primaryForeground,
    colors.primary,
    pair: 'primaryForeground/primary selected ayah',
  );
  _expectTextContrast(
    colors.secondaryForeground,
    colors.secondary,
    pair: 'secondaryForeground/secondary',
  );
  for (final surface in <String, Color>{
    'background': colors.background,
    'card': colors.card,
  }.entries) {
    _expectTextContrast(
      colors.destructive,
      surface.value,
      pair: 'destructive/${surface.key}',
    );
    _expectTextContrast(
      colors.error,
      surface.value,
      pair: 'error/${surface.key}',
    );
  }
  _expectTextContrast(
    colors.destructiveForeground,
    colors.destructive,
    pair: 'destructiveForeground/destructive control',
  );
  _expectTextContrast(
    colors.errorForeground,
    colors.error,
    pair: 'errorForeground/error control',
  );

  // buildAppTheme installs the actual tab extension used by the app. Verify
  // both its unselected metadata label and selected tinted indicator against
  // the resolved surfaces, rather than only checking the color scheme.
  final tabs = theme.extension<AppTabsStyles>();
  expect(theme.tabsStyle, same(tabs.standard));
  expect(tabs.standard.labelTextStyle.base.color, colors.mutedForeground);
  expect(
    tabs.standard.labelTextStyle.resolve({FTabVariant.selected}).color,
    colors.foreground,
  );
  _expectTextContrast(
    colors.foreground,
    colors.muted,
    pair: 'foreground/standard selected tab',
  );
  _expectTextContrast(
    colors.foreground,
    Color.alphaBlend(colors.primary.withValues(alpha: 0.18), colors.background),
    pair: 'foreground/compact selected tab indicator',
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
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    for (final touch in [false, true]) {
      test('Sage ${mode.name} contrast and Material roles (touch: $touch)', () {
        final theme = _paletteTheme(AppPalette.sage, mode, touch: touch);
        _expectPaletteContrast(theme);
        final colors = theme.colors;
        for (final surface in [
          colors.background,
          colors.card,
          colors.secondary,
          colors.muted,
        ]) {
          _expectTextContrast(
            colors.foreground,
            surface,
            pair: 'foreground/content',
          );
          _expectTextContrast(
            colors.secondaryForeground,
            surface,
            pair: 'secondaryForeground/content',
          );
        }
        final material = buildAppMaterialTheme(theme, palette: AppPalette.sage);
        expect(material.colorScheme.primary, colors.primary);
        expect(material.colorScheme.onPrimary, colors.primaryForeground);
        expect(material.colorScheme.surface, colors.background);
        expect(material.colorScheme.onSurface, colors.foreground);
        expect(material.colorScheme.error, colors.error);
        expect(material.colorScheme.surfaceContainer, colors.card);
        expect(material.colorScheme.outline, colors.border);
        expect(material.textSelectionTheme.cursorColor, colors.primary);
        _expectTextContrast(
          colors.foreground,
          Color.alphaBlend(
            material.textSelectionTheme.selectionColor!,
            colors.background,
          ),
          pair: 'selected text',
        );
        _expectTextContrast(
          colors.primaryForeground,
          colors.hover(colors.primary),
          pair: 'hovered primary control',
        );
        expect(material.colorScheme.brightness, colors.brightness);
      });
    }
  }

  test(
    'Manuscript light roles meet contrast through the app theme builder',
    () => _expectPaletteContrast(
      _paletteTheme(AppPalette.manuscript, ThemeMode.light),
    ),
  );

  test(
    'Manuscript dark roles meet contrast through the app theme builder',
    () => _expectPaletteContrast(
      _paletteTheme(AppPalette.manuscript, ThemeMode.dark),
    ),
  );

  test('alternate palette remains resolved by the app theme builder', () {
    final manuscript = buildAppTheme(
      palette: AppPalette.manuscript,
      themeMode: ThemeMode.light,
      touch: false,
      textScale: 1,
    );
    final neutral = buildAppTheme(
      palette: AppPalette.neutral,
      themeMode: ThemeMode.light,
      touch: false,
      textScale: 1,
    );

    expect(neutral.colors, isNot(same(manuscript.colors)));
    expect(neutral.extension<AppTabsStyles>(), isA<AppTabsStyles>());
    expect(neutral.tabsStyle, isNotNull);
  });
}
