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
  required bool useQuranFont,
  double? customFontSize,
}) {
  if (!useQuranFont && customFontSize == null) return fieldStyles;

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
                    fontFamily: useQuranFont ? FontFamily.uthmanicHafs : null,
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
/// (surah names in the surah selector). [customFontSize] overrides the
/// inherited body size when set.
FSelectStyle selectStyle({
  required FColors colors,
  required FTypography typography,
  required FStyle style,
  bool? touch,
  bool useQuranFont = false,
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

  if (!useQuranFont && customFontSize == null) {
    return inherited;
  }

  return FSelectStyle(
    fieldStyles: _customFieldStyles(
      inherited.fieldStyles,
      useQuranFont: useQuranFont,
      customFontSize: customFontSize,
    ),
    searchStyle: inherited.searchStyle,
    contentStyle: inherited.contentStyle,
    emptyTextStyle: inherited.emptyTextStyle,
  );
}
