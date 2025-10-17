import 'package:flutter/material.dart';
import 'package:hasanat/core/widgets/mouse_click.dart';

/// A text button that displays a hover effect when the mouse is over it.
class CustomTextButton extends StatefulWidget {
  /// Creates a custom text button.
  const CustomTextButton(
      {required this.label, required this.onPressed, super.key,
      this.enabled,
      this.duration = const Duration(milliseconds: 100),});

  /// The text to display on the button.
  final String label;

  /// The callback that is called when the button is tapped.
  final VoidCallback onPressed;

  /// Whether the button is enabled.
  final bool? enabled;

  /// The duration of the hover animation.
  final Duration duration;

  @override
  _CustomTextButtonState createState() => _CustomTextButtonState();
}

class _CustomTextButtonState extends State<CustomTextButton> {
  bool _isHovered = false;
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return MouseClick(
      onClick: widget.onPressed,
      onHover: (event) => setState(() {
        _isHovered = true;
      }),
      onExit: (event) => setState(() {
        _isHovered = false;
      }),
      child: AnimatedScale(
        duration: widget.duration,
        scale: _isHovered ? 1.2 : 1.0,
        curve: Curves.easeInOut,
        child: TextButton(
          onPressed: widget.enabled ?? false ? null : widget.onPressed,
          child: Text(
            widget.label,
            style: TextStyle(
              color: widget.enabled == false
                  ? colorScheme.shadow
                  : colorScheme.primary,
              shadows: _isHovered
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