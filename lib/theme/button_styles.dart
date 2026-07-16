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

/// Segmented layout toggle chip used in the Quran header.
FButtonStyle layoutSegmentButtonStyle({
  required FColors colors,
  required FTypography typography,
  required FStyle style,
  required BorderRadiusGeometry borderRadius,
  bool compact = false,
}) {
  final selectedBorder = RoundedSuperellipseBorder(
    side: BorderSide(color: colors.primary.withValues(alpha: 0.35)),
    borderRadius: borderRadius,
  );
  final baseShape = RoundedSuperellipseBorder(borderRadius: borderRadius);
  final selectedShadow = [
    BoxShadow(
      color: colors.barrier.withValues(alpha: 0.05),
      blurRadius: 6,
      offset: const Offset(0, 1),
    ),
  ];

  final decoration =
      FVariants<
        FTappableVariantConstraint,
        FTappableVariant,
        Decoration,
        DecorationDelta
      >.from(
        ShapeDecoration(shape: baseShape, color: Colors.transparent),
        variants: {
          [FTappableVariant.hovered, FTappableVariant.pressed]:
              DecorationDelta.shapeDelta(color: colors.card),
          [FTappableVariant.selected]: DecorationDelta.shapeDelta(
            color: colors.card,
            shape: selectedBorder,
            shadows: selectedShadow,
          ),
        },
      );

  final textStyle = typography.body.xs.copyWith(
    color: colors.mutedForeground,
    fontWeight: FontWeight.w500,
    height: 1,
  );

  return FButtonStyle(
    decoration: decoration,
    focusedOutlineStyle: style.focusedOutlineStyle,
    contentStyle: FButtonContentStyle(
      textStyle: FVariants.from(
        textStyle,
        variants: {
          [.selected]: TextStyleDelta.delta(
            color: colors.foreground,
            fontWeight: FontWeight.w600,
          ),
        },
      ),
      iconStyle: FVariants.from(
        IconThemeData(color: colors.mutedForeground, size: 16),
        variants: {
          [.selected]: IconThemeDataDelta.delta(color: colors.primary),
        },
      ),
      circularProgressStyle: FVariants.from(
        FCircularProgressStyle(
          iconStyle: IconThemeData(color: colors.mutedForeground, size: 16),
        ),
        variants: {
          [.selected]: FCircularProgressStyleDelta.delta(
            iconStyle: IconThemeDataDelta.delta(color: colors.primary),
          ),
        },
      ),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: 8,
      ),
      spacing: 4,
    ),
    iconContentStyle: FButtonIconContentStyle(
      iconStyle: FVariants.from(
        IconThemeData(color: colors.mutedForeground, size: 16),
        variants: {
          [.selected]: IconThemeDataDelta.delta(color: colors.primary),
        },
      ),
      padding: const EdgeInsets.all(8),
    ),
    tappableStyle: style.tappableStyle,
  );
}


