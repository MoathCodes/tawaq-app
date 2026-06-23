import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/layout/responsive.dart';
import 'package:tawaq/feature/quran/domain/models/translation_source.dart';
import 'package:tawaq/gen/fonts.gen.dart';

/// Typography helpers for Quran study-panel prose (tafsir and translations).
///
/// Uses scaled [FTypography] tokens from the app theme so content respects
/// the global app text-size setting.
abstract final class StudyPanelTextStyles {
  /// Viewport-bucket base style for Arabic tafsir commentary.
  ///
  /// Typography is chosen from discrete breakpoint tiers so split-pane resize
  /// does not recompute styles on every pixel of container width. Pass
  /// [containerWidth] when the style is scoped to a study-panel column.
  static TextStyle tafsirBase({
    required BuildContext context,
    required FTypography typography,
    required FColors colors,
    double? containerWidth,
  }) {
    final base = containerWidth != null
        ? responsiveValueForWidth(
            context,
            containerWidth,
            belowSm: typography.body.sm,
            sm: typography.body.md,
            md: typography.body.lg,
          )
        : responsiveValue(
            context,
            belowSm: typography.body.sm,
            sm: typography.body.md,
            md: typography.body.lg,
          );

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
    final base = typography.body.sm.copyWith(
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
