import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/widgets/mouse_click.dart';

class HoverCard extends StatefulWidget {
  final Widget child;
  final bool enableHoverEffect;
  final EdgeInsetsGeometry? padding;
  final BorderRadiusGeometry? borderRadius;
  final Color? borderColor;
  final Color? activeBorderColor;
  final Color? backgroundColor;
  const HoverCard(
      {super.key,
      required this.child,
      this.padding,
      this.enableHoverEffect = true,
      this.borderRadius,
      this.borderColor,
      this.activeBorderColor,
      this.backgroundColor});

  @override
  State<HoverCard> createState() => _HoverCardState();
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
      disabled: widget.enableHoverEffect == false,
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
        duration: const Duration(milliseconds: 200),
        padding: widget.padding,
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? colors.secondary,
          borderRadius:
              widget.borderRadius ?? BorderRadius.circular(_borderRadius),
          border: Border.all(
            color: _isHovering && widget.enableHoverEffect
                ? widget.activeBorderColor ?? colors.primary
                : widget.borderColor ??
                    colors.secondaryForeground.withAlpha(_borderOpacity),
          ),
          boxShadow: [
            _isHovering && widget.enableHoverEffect
                ? BoxShadow(
                    color: colors.primary.withAlpha(_borderOpacity),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: const Offset(0, 2),
                  )
                : const BoxShadow(
                    color: Colors.black38,
                    blurRadius: 10,
                    offset: Offset(0, 1),
                  ),
          ],
          // color: widget.backgroundColor ?? colors.secondary,
        ),
        child: widget.child,
      ),
    );
  }
}
