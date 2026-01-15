import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/hooks/hooks.dart';
import 'package:hasanat/core/widgets/mouse_click.dart';
import 'package:hasanat/theme/theme.dart';

const _kBorderRadius = 15.0;
const _kBorderOpacity = 100;
const _kAnimDuration = Duration(milliseconds: 260);

/// A card that displays a hover effect when hovered.
class HoverCard extends HookWidget {
  /// Creates a hover card.
  const HoverCard({
    required this.child,
    super.key,
    this.padding,
    this.enableHoverEffect = true,
    this.borderRadius,
    this.borderColor,
    this.activeBorderColor,
    this.backgroundColor,
  });

  final Widget child;
  final bool enableHoverEffect;
  final EdgeInsets? padding;
  final double? borderRadius;
  final Color? borderColor;
  final Color? activeBorderColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final (:isHovered, :setHovered) = useHoverState();
    final colors = FTheme.of(context).colors;
    final hovered = isHovered && enableHoverEffect;

    return MouseClick(
      disabled: !enableHoverEffect,
      onExit: (_) => setHovered(value: false),
      onHover: (_) => setHovered(value: true),
      child: AnimatedContainer(
        duration: _kAnimDuration,
        curve: Curves.easeOutCubic,
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor ?? colors.secondary,
          borderRadius: BorderRadius.circular(borderRadius ?? _kBorderRadius),
          border: Border.all(
            color: hovered
                ? activeBorderColor ?? colors.primary
                : borderColor ??
                      colors.secondaryForeground.withAlpha(_kBorderOpacity),
          ),
          boxShadow: hovered
              ? [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.18),
                    blurRadius: 28,
                    spreadRadius: 1,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
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

  final Widget child;
  final EdgeInsets? padding;
  final BorderRadiusGeometry? borderRadius;
  final Color? borderColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final colors = FTheme.of(context).colors;
    return Container(
      padding: padding ?? const .all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: backgroundColor ?? colors.secondary,
        borderRadius: BorderRadius.circular(_kBorderRadius),
        border: Border.all(
          color:
              borderColor ??
              colors.secondaryForeground.withAlpha(_kBorderOpacity),
        ),
      ),
      child: child,
    );
  }
}
