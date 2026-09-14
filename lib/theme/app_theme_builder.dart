import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/desktop/omarchy_theme_source.dart';
import 'package:tawaq/feature/settings/data/models/theme_prefs.dart';
import 'package:tawaq/feature/settings/presentation/provider/theme_settings_provider.dart';
import 'package:tawaq/gen/fonts.gen.dart';
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
}) {
  final fallbackPalette = palette == AppPalette.omarchy
      ? AppPalette.manuscript
      : palette;
  final base = resolveColorScheme(fallbackPalette, themeMode, touch: touch);
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
@Riverpod(keepAlive: true)
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
    touch: _isTouchThemePlatform(),
    textScale: 1,
    omarchyTheme: omarchyTheme,
  );
}

/// Applies persisted app text scale on top of [appThemeDataProvider].
@Riverpod(keepAlive: true)
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
    touch: _isTouchThemePlatform(),
    textScale: scale,
    omarchyTheme: ref.watch(omarchyThemeProvider).value,
  );
}
