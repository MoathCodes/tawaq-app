import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tawaq/core/hooks/hooks.dart';
import 'package:tawaq/core/widgets/mouse_click.dart';

/// A text button that displays a hover effect when the mouse is over it.
class CustomTextButton extends HookWidget {
  /// Creates a custom text button.
  const CustomTextButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.enabled,
    this.duration = const Duration(milliseconds: 100),
  });

  /// The text to display on the button.
  final String label;

  /// The callback that is called when the button is tapped.
  final VoidCallback onPressed;

  /// Whether the button is enabled.
  final bool? enabled;

  /// The duration of the hover animation.
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final (:isHovered, :setHovered) = useHoverState();
    final colorScheme = Theme.of(context).colorScheme;

    return MouseClick(
      onClick: onPressed,
      onHover: (event) => setHovered(value: true),
      onExit: (event) => setHovered(value: false),
      child: AnimatedScale(
        duration: duration,
        scale: isHovered ? 1.2 : 1.0,
        curve: Curves.easeInOut,
        child: TextButton(
          onPressed: enabled ?? false ? null : onPressed,
          child: Text(
            label,
            style: TextStyle(
              color: enabled == false
                  ? colorScheme.shadow
                  : colorScheme.primary,
              shadows: isHovered
                  ? [
                      Shadow(
                        color: colorScheme.primary.withAlpha(100),
                        blurRadius: 4,
                      ),
                    ]
                  : [],
            ),
          ),
        ),
      ),
    );
  }
}
