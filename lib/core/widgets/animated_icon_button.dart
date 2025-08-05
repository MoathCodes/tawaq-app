import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class AnimatedIconButton extends StatefulWidget {
  final IconData primaryIcon;
  final IconData secondaryIcon;
  final bool isSecondaryActive;
  final VoidCallback? onPressed;
  final double iconSize;
  final Duration animationDuration;
  final Duration opacityDuration;
  final FBaseButtonStyle Function(FButtonStyle)? buttonStyle;

  const AnimatedIconButton({
    super.key,
    required this.primaryIcon,
    required this.secondaryIcon,
    required this.isSecondaryActive,
    this.onPressed,
    this.buttonStyle,
    this.iconSize = 20,
    this.animationDuration = const Duration(milliseconds: 500),
    this.opacityDuration = const Duration(milliseconds: 300),
  });

  @override
  State<AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<AnimatedIconButton>
    with TickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  Widget build(BuildContext context) {
    return FButton(
      style: widget.buttonStyle?.call ?? FButtonStyle.ghost(),
      onPress: widget.onPressed,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          final rotationValue =
              _animationController.value * 3.14159; // 180 degrees
          final fadeValue = _animationController.value;

          return Transform.rotate(
            angle: rotationValue,
            child: AnimatedOpacity(
              opacity: !widget.isSecondaryActive && fadeValue != 1.0
                  ? (1.0 - fadeValue)
                  : fadeValue,
              duration: const Duration(milliseconds: 200),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Primary icon
                  AnimatedOpacity(
                    opacity: widget.isSecondaryActive ? 0.0 : 1.0,
                    duration: widget.opacityDuration,
                    child: Icon(
                      widget.primaryIcon,
                      size: widget.iconSize,
                    ),
                  ),
                  // Secondary icon
                  AnimatedOpacity(
                    opacity: widget.isSecondaryActive ? 1.0 : 0.0,
                    duration: widget.opacityDuration,
                    child: Icon(
                      widget.secondaryIcon,
                      size: widget.iconSize,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void didUpdateWidget(AnimatedIconButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSecondaryActive != widget.isSecondaryActive) {
      if (widget.isSecondaryActive) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
      value: widget.isSecondaryActive ? 1.0 : 0.0,
    );
  }
}
