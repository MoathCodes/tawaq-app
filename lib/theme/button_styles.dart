import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Creates a [FButtonStyle] for a close button.
FButtonStyle closeButtonStyle({
  required FColors colors,
  required FTypography typography,
  required FStyle style,
}) {
  final isLight = colors.background.computeLuminance() > 0.5;
  final hoverColor = isLight
      ? const Color(0xFFb91c1c)
      : const Color(0xFFef4444);

  return _windowButton(
    colors: colors,
    typography: typography,
    style: style,
    hoverBg: Colors.red.withValues(alpha: isLight ? 0.1 : 0.2),
    hoverColor: hoverColor,
    normalColor: colors.mutedForeground,
    normalBorder: colors.border,
  );
}

/// Creates a [FButtonStyle] for window control buttons (minimize, maximize).
FButtonStyle windowControlButtonStyle({
  required FColors colors,
  required FTypography typography,
  required FStyle style,
}) {
  return _windowButton(
    colors: colors,
    typography: typography,
    style: style,
    hoverBg: colors.muted.withValues(alpha: 0.7),
    hoverColor: colors.foreground,
    normalColor: colors.mutedForeground,
    normalBorder: colors.border,
    borderRadius: BorderRadius.circular(6),
  );
}

FButtonStyle _windowButton({
  required FColors colors,
  required FTypography typography,
  required FStyle style,
  required Color hoverBg,
  required Color hoverColor,
  required Color normalColor,
  required Color normalBorder,
  BorderRadiusGeometry? borderRadius,
}) {
  final radius = borderRadius ?? style.borderRadius.md;
  final disabledColor = colors.disable(normalColor);

  return FButtonStyle(
    decoration: FVariants.from(
      ShapeDecoration(
        shape: RoundedSuperellipseBorder(
          borderRadius: radius,
          side: BorderSide(color: normalBorder, width: style.borderWidth),
        ),
        color: Colors.transparent,
      ),
      variants: {
        [.hovered]: .shapeDelta(color: hoverBg),
      },
    ),
    focusedOutlineStyle: style.focusedOutlineStyle,
    contentStyle: FButtonContentStyle(
      circularProgressStyle: FVariants.from(
        FCircularProgressStyle(
          iconStyle: IconThemeData(color: normalColor, size: 14),
        ),
        variants: {
          [.hovered]: .delta(iconStyle: .delta(color: hoverColor)),
          [.disabled]: .delta(iconStyle: .delta(color: disabledColor)),
        },
      ),
      textStyle: FVariants.from(
        typography.body.sm.copyWith(
          color: normalColor,
          fontWeight: .w500,
          height: 1,
        ),
        variants: {
          [.hovered]: .delta(color: hoverColor),
          [.disabled]: .delta(color: disabledColor),
        },
      ),
      iconStyle: FVariants.from(
        IconThemeData(color: normalColor, size: 14),
        variants: {
          [.hovered]: .delta(color: hoverColor),
          [.disabled]: .delta(color: disabledColor),
        },
      ),
      padding: const EdgeInsets.all(7),
      spacing: 0,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    ),
    iconContentStyle: FButtonIconContentStyle(
      iconStyle: FVariants.from(
        IconThemeData(color: normalColor, size: 14),
        variants: {
          [.hovered]: .delta(color: hoverColor),
          [.disabled]: .delta(color: disabledColor),
        },
      ),
      padding: const EdgeInsets.all(7),
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    ),
    tappableStyle: style.tappableStyle,
  );
}
