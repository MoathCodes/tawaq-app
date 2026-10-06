import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/desktop/omarchy_theme_source.dart';
import 'package:tawaq/feature/settings/data/models/theme_prefs.dart';
import 'package:tawaq/feature/settings/presentation/provider/theme_settings_provider.dart';
import 'package:tawaq/gen/fonts.gen.dart';
import 'package:tawaq/core/utils/platform_brightness_provider.dart';
import 'package:tawaq/theme/custom_themes.dart';
import 'package:tawaq/theme/omarchy_theme.dart';
import 'package:tawaq/theme/omarchy_theme_provider.dart';
import 'package:tawaq/theme/theme.dart';
import 'package:tawaq/theme/theme_model.dart';

part 'app_theme_builder.g.dart';

bool _isTouchThemePlatform() =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.fuchsia);

/// Builds the root [FThemeData] with palette, density, text scale, app font,
/// and the app's tab styles.
FThemeData buildAppTheme({
  required AppPalette palette,
  required ThemeMode themeMode,
  required bool touch,
  required double textScale,
  OmarchyThemeSnapshot? omarchyTheme,
  Brightness platformBrightness = Brightness.light,
}) {
  final fallbackPalette = palette == AppPalette.omarchy
      ? AppPalette.manuscript
      : palette;
  final effectiveMode = themeMode == ThemeMode.system
      ? (platformBrightness == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light)
      : themeMode;
  final base = resolveColorScheme(fallbackPalette, effectiveMode, touch: touch);
  final colors =
      palette == AppPalette.omarchy && omarchyTheme?.isAvailable == true
      ? buildOmarchyColors(omarchyTheme!)
      : base.colors;
  final typeface = FTypeface.inherit(
    colors: colors,
    touch: touch,
    fontFamily: FontFamily.iBMPlexSansArabic,
  );
  final typography = FTypography(
    display: typeface,
    body: typeface,
  ).scale(sizeScalar: textScale);
  final style = FStyle.inherit(
    colors: colors,
    typography: typography,
    touch: touch,
  );

  const radii = AppRadii.standard();
  final tabs = AppTabsStyles.inherit(
    colors: colors,
    typography: typography,
    style: style,
    radii: radii,
  );

  return FThemeData(
    colors: colors,
    touch: touch,
    typography: typography,
    style: style,
    icons: base.icons,
    tabsStyle: tabs.standard,
    extensions: [radii, const AppDurations.standard(), tabs],
  );
}

/// Appearance-only theme (palette + mode + density), excluding text scale.
@riverpod
FThemeData appThemeData(Ref ref) {
  final palette = ref.watch(
    themeProvider.select((t) => t.value?.appPalette ?? AppPalette.manuscript),
  );
  final themeMode = ref.watch(
    themeProvider.select((t) => t.value?.themeMode ?? ThemeMode.light),
  );
  final omarchyTheme = ref.watch(omarchyThemeProvider).value;
  return buildAppTheme(
    palette: palette,
    themeMode: themeMode,
    platformBrightness:
        ref.watch(platformBrightnessProvider).value ??
        WidgetsBinding.instance.platformDispatcher.platformBrightness,
    touch: _isTouchThemePlatform(),
    textScale: 1,
    omarchyTheme: omarchyTheme,
  );
}

/// Applies persisted app text scale on top of [appThemeDataProvider].
@riverpod
FThemeData appThemeWithTextScale(Ref ref) {
  final scale = ref.watch(
    themeProvider.select(
      (t) => (t.value ?? ThemePrefs.defaults()).appTextScale.scalar,
    ),
  );
  return buildAppTheme(
    palette: ref.watch(
      themeProvider.select((t) => t.value?.appPalette ?? AppPalette.manuscript),
    ),
    themeMode: ref.watch(
      themeProvider.select((t) => t.value?.themeMode ?? ThemeMode.light),
    ),
    platformBrightness:
        ref.watch(platformBrightnessProvider).value ??
        WidgetsBinding.instance.platformDispatcher.platformBrightness,
    touch: _isTouchThemePlatform(),
    textScale: scale,
    omarchyTheme: ref.watch(omarchyThemeProvider).value,
  );
}

/// Completes Material compatibility roles for Sage's tonal surface hierarchy.
/// Other palettes retain their existing Forui approximation.
ThemeData buildAppMaterialTheme(
  FThemeData theme, {
  required AppPalette palette,
}) {
  final material = theme.toApproximateMaterialTheme();
  if (palette != AppPalette.sage) return material;
  final colors = theme.colors;
  return material.copyWith(
    colorScheme: material.colorScheme.copyWith(
      primaryContainer: colors.secondary,
      onPrimaryContainer: colors.secondaryForeground,
      tertiary: colors.primary,
      onTertiary: colors.primaryForeground,
      tertiaryContainer: colors.secondary,
      onTertiaryContainer: colors.secondaryForeground,
      onSurfaceVariant: colors.mutedForeground,
      outline: colors.border,
      outlineVariant: colors.border,
      surfaceDim: colors.muted,
      surfaceBright: colors.card,
      surfaceContainerLowest: colors.background,
      surfaceContainerLow: colors.card,
      surfaceContainer: colors.card,
      surfaceContainerHigh: colors.muted,
      surfaceContainerHighest: colors.secondary,
      surfaceTint: colors.primary,
      inverseSurface: colors.foreground,
      onInverseSurface: colors.background,
      inversePrimary: colors.brightness == Brightness.light
          ? SageTheme.darkColors.primary
          : SageTheme.lightColors.primary,
    ),
    scaffoldBackgroundColor: colors.background,
    dividerColor: colors.border,
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: colors.primary,
      selectionColor: colors.primary.withValues(alpha: 0.22),
      selectionHandleColor: colors.primary,
    ),
  );
}
