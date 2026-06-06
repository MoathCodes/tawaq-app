import 'package:flutter/foundation.dart';
import 'package:forui/forui.dart';

bool _useTouchVariant() =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.fuchsia);

/// Returns a project-wide select style built on Forui's current API.
///
/// This intentionally starts from `inherit(...)` so it stays compatible
/// across Forui style schema updates.
FSelectStyle selectStyle({
  required FColors colors,
  required FTypography typography,
  required FStyle style,
  bool? touch,
  bool useQuranFont = false,
  double? customFontSize,
}) {
  final _ = useQuranFont || customFontSize != null;
  final resolvedTouch = touch ?? _useTouchVariant();
  return FSelectStyle.inherit(
    colors: colors,
    icons: FIcons.lucide(),
    typography: typography,
    style: style,
    touch: resolvedTouch,
  );
}
