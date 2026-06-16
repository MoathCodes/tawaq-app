import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/feature/quran/domain/models/translation_source.dart';
import 'package:tawaq/gen/fonts.gen.dart';

/// Typography helpers for Quran study-panel prose (tafsir and translations).
///
/// Uses scaled [FTypography] tokens from the app theme so content respects
/// the global app text-size setting.
abstract final class StudyPanelTextStyles {
  /// Container-width–responsive base style for Arabic tafsir commentary.
  static TextStyle tafsirBase({
    required FTypography typography,
    required FColors colors,
    required FBreakpoints breakpoints,
    required double containerWidth,
  }) {
    final base = containerWidth < breakpoints.sm
        ? typography.sm
        : containerWidth < breakpoints.md
        ? typography.md
        : typography.lg;

    return base.copyWith(
      color: colors.foreground,
      fontFamily: FontFamily.uthmanTN,
      height: 1.8,
    );
  }

  /// Body style for a translation paragraph.
  static TextStyle translation({
    required FTypography typography,
    required FColors colors,
    required TranslationId source,
  }) {
    final base = typography.sm.copyWith(
      color: colors.foreground,
      height: source == TranslationId.urdu ? 2.0 : 1.6,
      fontStyle: source.usesItalicQuoteStyle
          ? FontStyle.italic
          : FontStyle.normal,
    );
    final fontFamily = source.fontFamily;
    return fontFamily == null ? base : base.copyWith(fontFamily: fontFamily);
  }
}
