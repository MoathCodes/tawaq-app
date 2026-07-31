import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/hooks/hooks.dart';
import 'package:tawaq/core/widgets/mouse_click.dart';
import 'package:tawaq/theme/theme.dart';

const _kBorderOpacity = 100;
const _kAnimDuration = Duration(milliseconds: 260);

/// Space a [HoverCard]'s hover glow needs outside its own box.
///
/// The glow is painted by the card's [BoxDecoration], so it falls outside the
/// card's layout bounds. When cards fill the width of a scroll viewport the
/// viewport's clip cuts the glow off flush with the card edge. Reserve this
/// much room around cards inside any clipping ancestor — use
/// [hoverCardListPadding] for scrollables.
///
/// A [BoxShadow] reaches `spreadRadius + blurRadius` past its box, so this must
/// stay >= the largest reach in [HoverCard]'s shadows (currently `0 + 14` to
/// the sides and `4 + 14` downwards). Keep them in sync when tuning the glow.
const double kHoverCardGlowGutter = 18;

/// Scrollable padding that leaves room for [HoverCard] hover glows.
///
/// Pass to `ListView.padding` (or an equivalent sliver padding) when the list
/// renders [HoverCard]s, so the glow is not clipped by the viewport.
EdgeInsets hoverCardListPadding({
  double horizontal = kHoverCardGlowGutter,
  double top = 0,
  double bottom = 0,
}) => EdgeInsets.only(
  left: horizontal,
  right: horizontal,
  top: top + kHoverCardGlowGutter,
  bottom: bottom + kHoverCardGlowGutter,
);

/// A card that displays a hover effect when hovered.
class HoverCard extends HookWidget {
  /// Creates a hover card.
  const HoverCard({
    required this.child,
    super.key,
    this.padding,
    this.enableHoverEffect = true,
    this.onPress,
    this.borderRadius,
    this.borderColor,
    this.activeBorderColor,
    this.backgroundColor,
    this.semanticsLabel,
  });

  /// The card content.
  final Widget child;

  /// Whether the hover transition should be enabled.
  final bool enableHoverEffect;

  /// Optional press handler; when set the card becomes interactive.
  final VoidCallback? onPress;

  /// Optional inner padding.
  final EdgeInsets? padding;

  /// Optional border radius override.
  final double? borderRadius;

  /// Border color used when the card is not hovered.
  final Color? borderColor;

  /// Border color used when the card is hovered.
  final Color? activeBorderColor;

  /// Optional background color override.
  final Color? backgroundColor;

  /// Merged accessibility label when the card is interactive.
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final (:isHovered, :setHovered) = useHoverState();
    final theme = context.theme;
    final colors = theme.colors;
    final hovered = isHovered && enableHoverEffect;
    final radius = borderRadius != null
        ? BorderRadius.circular(borderRadius!)
        : theme.radii.xl;

    final interactive = onPress != null;

    return MouseClick(
      disabled: !enableHoverEffect && !interactive,
      onClick: onPress,
      semanticsLabel: semanticsLabel,
      onHoverChange: enableHoverEffect
          ? (hovering) => setHovered(value: hovering)
          : null,
      child: AnimatedContainer(
        duration: _kAnimDuration,
        curve: Curves.easeOutCubic,
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor ?? colors.secondary,
          borderRadius: radius,
          border: Border.all(
            color: hovered
                ? activeBorderColor ?? colors.primary
                : borderColor ??
                      colors.secondaryForeground.withAlpha(_kBorderOpacity),
          ),
          // Reach is kept within [kHoverCardGlowGutter] so ancestor clips
          // (scroll viewports, stacks) do not slice the glow off.
          boxShadow: hovered
              ? [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.22),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: child,
      ),
    );
  }
}

/// A card without hover effects.
class StaticCard extends StatelessWidget {
  /// Creates a static card.
  const StaticCard({
    required this.child,
    super.key,
    this.padding,
    this.borderRadius,
    this.borderColor,
    this.backgroundColor,
  });

  /// The card content.
  final Widget child;

  /// Optional inner padding.
  final EdgeInsets? padding;

  /// Optional border radius override.
  final BorderRadiusGeometry? borderRadius;

  /// Optional border color override.
  final Color? borderColor;

  /// Optional background color override.
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    return Container(
      padding: padding ?? const .all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: backgroundColor ?? colors.secondary,
        borderRadius: borderRadius ?? theme.radii.xl,
        border: Border.all(
          color: borderColor ?? colors.border,
        ),
      ),
      child: child,
    );
  }
}
