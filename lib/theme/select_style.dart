import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/gen/fonts.gen.dart';

bool _useTouchVariant() =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.fuchsia);

FTextFieldSizeStyles _customFieldStyles(
  FTextFieldSizeStyles fieldStyles, {
  bool useQuranFont = false,
  bool useGlyphFont = false,
  double? customFontSize,
}) {
  if (!useQuranFont && !useGlyphFont && customFontSize == null) {
    return fieldStyles;
  }

  final String? fontFamily;
  final String? package;
  if (useGlyphFont) {
    fontFamily = 'QCF4_BSML';
    package = 'mushaf_reader';
  } else if (useQuranFont) {
    fontFamily = FontFamily.uthmanicHafs;
    package = null;
  } else {
    fontFamily = null;
    package = null;
  }

  return FTextFieldSizeStyles(
    fieldStyles.apply([
      FVariantOperation<
        FTextFieldSizeVariantConstraint,
        FTextFieldSizeVariant,
        FTextFieldStyle,
        FTextFieldStyleDelta
      >.all(
        FTextFieldStyleDelta.delta(
          contentTextStyle:
              FVariantsDelta<
                FTextFieldVariantConstraint,
                FTextFieldVariant,
                TextStyle,
                TextStyleDelta
              >.delta([
                FVariantOperation<
                  FTextFieldVariantConstraint,
                  FTextFieldVariant,
                  TextStyle,
                  TextStyleDelta
                >.all(
                  TextStyleDelta.delta(
                    fontFamily: fontFamily,
                    package: package,
                    fontSize: customFontSize,
                  ),
                ),
              ]),
        ),
      ),
    ]),
  );
}

/// Returns a project-wide select style built on Forui's current API.
///
/// This intentionally starts from `inherit(...)` so it stays compatible
/// across Forui style schema updates.
///
/// When [useQuranFont] is true the closed-field value uses Uthmanic Hafs
/// (surah names in the surah selector). When [useGlyphFont] is true the
/// closed-field value uses QCF4_BSML from `mushaf_reader` (juz glyphs).
/// If both are true, [useGlyphFont] wins. [customFontSize] overrides the
/// inherited body size when set.
FSelectStyle selectStyle({
  required FColors colors,
  required FTypography typography,
  required FStyle style,
  bool? touch,
  bool useQuranFont = false,
  bool useGlyphFont = false,
  double? customFontSize,
}) {
  final resolvedTouch = touch ?? _useTouchVariant();
  final inherited = FSelectStyle.inherit(
    colors: colors,
    icons: FIcons.lucide(),
    typography: typography,
    style: style,
    touch: resolvedTouch,
  );

  if (!useQuranFont && !useGlyphFont && customFontSize == null) {
    return inherited;
  }

  return FSelectStyle(
    fieldStyles: _customFieldStyles(
      inherited.fieldStyles,
      useQuranFont: useQuranFont,
      useGlyphFont: useGlyphFont,
      customFontSize: customFontSize,
    ),
    searchStyle: inherited.searchStyle,
    contentStyle: inherited.contentStyle,
    emptyTextStyle: inherited.emptyTextStyle,
  );
}
