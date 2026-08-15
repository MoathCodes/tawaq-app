import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/feature/quran/presentation/models/quran_ui_models.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_screen_settings_provider.dart';
import 'package:tawaq/theme/app_theme_builder.dart';

part 'quran_mushaf_style.g.dart';

/// Builds the themed [MushafStyle] used by the Quran reader layouts.
///
/// Zoom above [kMushafZoomFitPage] lerps toward width-fit (vertical scroll OK).
MushafStyle buildQuranMushafStyle(
  FThemeData theme, {
  double zoom = kMushafZoomDefault,
}) => MushafStyle(
  scale: MushafScale(
    readingBoost: clampMushafZoom(zoom),
  ),
  ayahStyleModifier: (s) => s.copyWith(color: theme.colors.foreground),
  juzStyleModifier: (s) => s.copyWith(color: theme.colors.mutedForeground),
  pageNumberStyleModifier: (s) =>
      s.copyWith(color: theme.colors.mutedForeground),
  surahNameStyleModifier: (s) =>
      s.copyWith(color: theme.colors.mutedForeground),
  basmalahStyleModifier: (s) => s.copyWith(color: theme.colors.foreground),
  activeAyahStyleModifier: (s) => s.copyWith(
    backgroundColor: theme.colors.primary,
    color: theme.colors.primaryForeground,
  ),
  headerSurahNameStyleModifier: (s) => s.copyWith(
    // Banner SVG switches with theme; secondaryForeground contrasts on both.
    color: theme.colors.secondaryForeground,
  ),
);

/// Stable mushaf style keyed by palette, brightness, and mushaf zoom.
@Riverpod(keepAlive: true)
MushafStyle mushafStyle(Ref ref) {
  final theme = ref.watch(appThemeDataProvider);
  final zoom = ref.watch(
    quranScreenSettingsProvider.select(
      (v) => v.value?.mushafZoom ?? kMushafZoomDefault,
    ),
  );
  return buildQuranMushafStyle(theme, zoom: zoom);
}
