import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// An icon button that animates between a primary and a secondary icon.
///
/// This widget displays an icon button that can be tapped to trigger an action.
/// It can also be used to indicate a selected state by switching to a
/// secondary icon.
class AnimatedIconButton extends StatefulWidget {
  /// Creates an animated icon button.
  const AnimatedIconButton({
    required this.primaryIcon,
    required this.secondaryIcon,
    required this.isSecondaryActive,
    super.key,
    this.onPressed,
    this.buttonStyle,
    this.iconSize = 20,
    this.animationDuration = const Duration(milliseconds: 500),
    this.opacityDuration = const Duration(milliseconds: 300),
  });

  /// The icon to display when the button is in its primary state.
  final IconData primaryIcon;

  /// The icon to display when the button is in its secondary state.
  final IconData secondaryIcon;

  /// Whether the secondary icon is active.
  final bool isSecondaryActive;

  /// The callback that is called when the button is tapped.
  final VoidCallback? onPressed;

  /// The size of the icon.
  final double iconSize;

  /// The duration of the animation.
  final Duration animationDuration;

  /// The duration of the opacity animation.
  final Duration opacityDuration;

  /// The style of the button.
  final FBaseButtonStyle Function(FButtonStyle)? buttonStyle;

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
                    child: Icon(widget.primaryIcon, size: widget.iconSize),
                  ),
                  // Secondary icon
                  AnimatedOpacity(
                    opacity: widget.isSecondaryActive ? 1.0 : 0.0,
                    duration: widget.opacityDuration,
                    child: Icon(widget.secondaryIcon, size: widget.iconSize),
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