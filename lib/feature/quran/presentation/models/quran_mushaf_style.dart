import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/feature/quran/domain/models/quran_text_scale.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_screen_settings_provider.dart';
import 'package:tawaq/theme/app_theme_builder.dart';

part 'quran_mushaf_style.g.dart';

/// Builds the themed [MushafStyle] used by the Quran reader layouts.
MushafStyle buildQuranMushafStyle(
  FThemeData theme, [
  QuranTextScale textScale = QuranTextScale.medium,
]) => MushafStyle(
  scale: MushafScale(readingBoost: textScale.boost),
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

/// Stable mushaf style keyed by palette, brightness, and [QuranTextScale].
@Riverpod(keepAlive: true)
MushafStyle mushafStyle(Ref ref) {
  final theme = ref.watch(appThemeDataProvider);
  final textScale = ref.watch(
    quranScreenSettingsProvider.select(
      (v) => v.value?.quranTextScale ?? QuranTextScale.medium,
    ),
  );
  return buildQuranMushafStyle(theme, textScale);
}
