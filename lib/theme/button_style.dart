import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Creates a custom [FButtonStyle] with the given colors and typography.
FButtonStyle buttonStyle({
  required FColors colors,
  required FTypography typography,
  required FStyle style,
  required Color color,
  required Color foregroundColor,
}) {
  final disabled = colors.disable(foregroundColor, colors.disable(color));
  return FButtonStyle(
    decoration: FWidgetStateMap({
      WidgetState.disabled: BoxDecoration(
        borderRadius: style.borderRadius,
        color: colors.disable(color),
      ),
      WidgetState.hovered | WidgetState.pressed: BoxDecoration(
        borderRadius: style.borderRadius,
        color: colors.hover(color),
        border: Border.all(
          color: color.withValues(alpha: 1),
          width: style.borderWidth,
        ),
      ),
      WidgetState.any: BoxDecoration(
        borderRadius: style.borderRadius,
        border: Border.all(
          color: foregroundColor.withValues(alpha: .5),
          width: style.borderWidth,
        ),
      ),
    }),
    focusedOutlineStyle: style.focusedOutlineStyle,
    contentStyle: _contentStyle(typography, foregroundColor, disabled),
    iconContentStyle: _iconStyle(foregroundColor, disabled),
    tappableStyle: style.tappableStyle,
  );
}

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
    hoverBorder: Colors.red.withValues(alpha: isLight ? 0.2 : 0.3),
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
    hoverBorder: colors.border,
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
  required Color hoverBorder,
  required Color hoverColor,
  required Color normalColor,
  required Color normalBorder,
  BorderRadius? borderRadius,
}) {
  final radius = borderRadius ?? style.borderRadius;
  return FButtonStyle(
    decoration: FWidgetStateMap({
      WidgetState.hovered: BoxDecoration(
        borderRadius: radius,
        color: hoverBg,
        border: Border.all(color: hoverBorder, width: style.borderWidth),
      ),
      WidgetState.any: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: normalBorder, width: style.borderWidth),
        color: Colors.transparent,
      ),
    }),
    focusedOutlineStyle: style.focusedOutlineStyle,
    contentStyle: FButtonContentStyle(
      circularProgressStyle: FWidgetStateMap({
        WidgetState.any: FCircularProgressStyle(
          iconStyle: IconThemeData(color: colors.primary),
        ),
      }),
      textStyle: FWidgetStateMap({
        WidgetState.hovered: typography.base.copyWith(
          color: hoverColor,
          fontWeight: FontWeight.w500,
          height: 1,
        ),
        WidgetState.any: typography.base.copyWith(
          color: normalColor,
          fontWeight: FontWeight.w500,
          height: 1,
        ),
      }),
      iconStyle: FWidgetStateMap({
        WidgetState.hovered: IconThemeData(color: hoverColor, size: 14),
        WidgetState.any: IconThemeData(color: normalColor, size: 14),
      }),
      padding: const .all(7),
      spacing: 0,
    ),
    iconContentStyle: FButtonIconContentStyle(
      iconStyle: FWidgetStateMap({
        WidgetState.hovered: IconThemeData(color: hoverColor, size: 14),
        WidgetState.any: IconThemeData(color: normalColor, size: 14),
      }),
    ),
    tappableStyle: style.tappableStyle,
  );
}

FButtonContentStyle _contentStyle(
  FTypography typography,
  Color enabled,
  Color disabled,
) => FButtonContentStyle(
  circularProgressStyle: FWidgetStateMap({
    WidgetState.any: FCircularProgressStyle(
      iconStyle: IconThemeData(color: enabled),
    ),
  }),
  textStyle: FWidgetStateMap({
    WidgetState.disabled: typography.base.copyWith(
      color: disabled,
      fontWeight: FontWeight.w500,
      height: 1,
    ),
    WidgetState.any: typography.base.copyWith(
      color: enabled,
      fontWeight: FontWeight.w500,
      height: 1,
    ),
  }),
  iconStyle: FWidgetStateMap({
    WidgetState.disabled: IconThemeData(color: disabled, size: 20),
    WidgetState.any: IconThemeData(color: enabled, size: 20),
  }),
);

FButtonIconContentStyle _iconStyle(Color enabled, Color disabled) =>
    FButtonIconContentStyle(
      iconStyle: FWidgetStateMap({
        WidgetState.disabled: IconThemeData(color: disabled, size: 20),
        WidgetState.any: IconThemeData(color: enabled, size: 20),
      }),
    );
