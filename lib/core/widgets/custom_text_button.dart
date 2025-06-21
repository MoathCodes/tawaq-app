import 'package:hasanat/core/widgets/mouse_click.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

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
      this.duration = const Duration(milliseconds: 200)});

  @override
  _CustomTextButtonState createState() => _CustomTextButtonState();
}

class _CustomTextButtonState extends State<CustomTextButton> {
  bool _isHovered = false;
  @override
  Widget build(BuildContext context) {
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
        scale: _isHovered ? 1.05 : 1.0,
        curve: Curves.easeInOut,
        child: TextButton(
          onPressed: widget.onPressed,
          enabled: widget.enabled,
          child: Text(
            widget.label,
            style: TextStyle(
              color: widget.enabled == false
                  ? Theme.of(context).colorScheme.muted
                  : Theme.of(context).colorScheme.primary,
              shadows: _isHovered
                  ? [
                      Shadow(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withAlpha(100),
                        blurRadius: 4.0,
                      ),
                    ]
                  : [],
            ),
          ).bold,
        ),
      ),
    );
  }
}
