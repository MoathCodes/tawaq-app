import 'package:flutter/material.dart';
import 'package:hasanat/core/widgets/mouse_click.dart';

class CustomTextButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool? enabled;
  final Duration duration;
  const CustomTextButton(
      {super.key,
      required this.label,
      this.enabled,
      required this.onPressed,
      this.duration = const Duration(milliseconds: 100)});

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
                        blurRadius: 4.0,
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
