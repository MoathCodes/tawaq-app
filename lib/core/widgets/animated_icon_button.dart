import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';

/// An icon button that animates between a primary and a secondary icon.
///
/// This widget displays an icon button that can be tapped to trigger an action.
/// It can also be used to indicate a selected state by switching to a
/// secondary icon.
class AnimatedIconButton extends HookWidget {
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
  Widget build(BuildContext context) {
    final animationController = useAnimationController(
      duration: animationDuration,
      initialValue: isSecondaryActive ? 1.0 : 0.0,
    );

    // Handle isSecondaryActive changes (equivalent to didUpdateWidget)
    useEffect(
      () {
        if (isSecondaryActive) {
          unawaited(animationController.forward());
        } else {
          unawaited(animationController.reverse());
        }
        return null;
      },
      [isSecondaryActive],
    );

    return FButton(
      style: buttonStyle?.call ?? FButtonStyle.ghost(),
      onPress: onPressed,
      child: AnimatedBuilder(
        animation: animationController,
        builder: (context, child) {
          final rotationValue =
              animationController.value * 3.14159; // 180 degrees
          final fadeValue = animationController.value;

          return Transform.rotate(
            angle: rotationValue,
            child: AnimatedOpacity(
              opacity: !isSecondaryActive && fadeValue != 1.0
                  ? (1.0 - fadeValue)
                  : fadeValue,
              duration: const Duration(milliseconds: 200),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Primary icon
                  AnimatedOpacity(
                    opacity: isSecondaryActive ? 0.0 : 1.0,
                    duration: opacityDuration,
                    child: Icon(primaryIcon, size: iconSize),
                  ),
                  // Secondary icon
                  AnimatedOpacity(
                    opacity: isSecondaryActive ? 1.0 : 0.0,
                    duration: opacityDuration,
                    child: Icon(secondaryIcon, size: iconSize),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
