import 'package:flumpose/flumpose.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/widgets/mouse_click.dart';

/// A card that displays a hover effect when the mouse is over it.
class HoverCard extends StatefulWidget {
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

  /// The widget below this widget in the tree.
  final Widget child;

  /// Whether to enable the hover effect.
  final bool enableHoverEffect;

  /// The padding around the card.
  final EdgeInsets? padding;

  /// The border radius of the card.
  final double? borderRadius;

  /// The color of the border.
  final Color? borderColor;

  /// The color of the border when the mouse is over the card.
  final Color? activeBorderColor;

  /// The background color of the card.
  final Color? backgroundColor;

  @override
  State<HoverCard> createState() => _HoverCardState();
}

/// A card that does not have any hover effects.
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

  /// The widget below this widget in the tree.
  final Widget child;

  /// The padding around the card.
  final EdgeInsets? padding;

  /// The border radius of the card.
  final BorderRadiusGeometry? borderRadius;

  /// The color of the border.
  final Color? borderColor;

  /// The background color of the card.
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final colors = FTheme.of(context).colors;
    const defaultBorderRadius = 15.0;
    const borderOpacity = 100;

    return child.decorateWithPadding(
      padding: padding ?? const EdgeInsets.all(8),
      builder: (d) => d
          .color(backgroundColor ?? colors.secondary)
          .circular(defaultBorderRadius)
          .borderAll(
            color: borderColor ??
                colors.secondaryForeground.withAlpha(borderOpacity),
          ),
    );
  }
}

class _HoverCardState extends State<HoverCard> {
  // static const _cardPadding = EdgeInsets.all(16.0);
  static const _borderRadius = 15.0;
  static const _borderOpacity = 100;
  bool _isHovering = false;
  @override
  Widget build(BuildContext context) {
    final colors = FTheme.of(context).colors;
    return MouseClick(
      disabled: !widget.enableHoverEffect,
      onExit: (event) {
        setState(() {
          _isHovering = false;
        });
      },
      onHover: (event) {
        setState(() {
          _isHovering = true;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        padding: widget.padding ,
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? colors.secondary,
          borderRadius: BorderRadius.circular(
            widget.borderRadius ?? _borderRadius,
          ),
          border: Border.all(
            color: _isHovering && widget.enableHoverEffect
                ? widget.activeBorderColor ?? colors.primary
                : widget.borderColor ??
                    colors.secondaryForeground.withAlpha(_borderOpacity),
          ),
          boxShadow: _isHovering && widget.enableHoverEffect
              ? <BoxShadow>[
                  // Soft, wide ambient shadow
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.18),
                    blurRadius: 28,
                    spreadRadius: 1,
                    offset: const Offset(0, 10),
                  ),
                  // Subtle contact shadow for depth
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
          // color: widget.backgroundColor ?? colors.secondary,
        ),
        child: widget.child,
      ),
    );
  }
}