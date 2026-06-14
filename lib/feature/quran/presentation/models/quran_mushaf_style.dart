import 'package:forui/forui.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/feature/quran/domain/models/quran_text_scale.dart';

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
