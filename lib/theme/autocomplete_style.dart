import 'package:flutter/foundation.dart';
import 'package:forui/forui.dart';

bool _useTouchVariant() =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.fuchsia);

/// Returns a project-wide autocomplete style built on Forui's current API.
///
/// The field uses the app body font (via inherit) so users type with the
/// standard keyboard script; result rows set Uthmani/Hafs per item.
FAutocompleteStyle autocompleteStyle({
  required FColors colors,
  required FTypography typography,
  required FStyle style,
  bool? touch,
}) {
  final resolvedTouch = touch ?? _useTouchVariant();
  return FAutocompleteStyle.inherit(
    colors: colors,
    typography: typography,
    style: style,
    touch: resolvedTouch,
  );
}
