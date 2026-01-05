import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A widget that detects mouse clicks and hover events.
class MouseClick extends StatelessWidget {
  /// Creates a mouse click detector.
  const MouseClick({
    required this.child,
    super.key,
    this.onClick,
    this.onHover,
    this.onExit,
    this.cursor = SystemMouseCursors.click,
    this.disabled,
  });

  /// The widget below this widget in the tree.
  final Widget child;

  /// The callback that is called when the widget is clicked.
  final VoidCallback? onClick;

  /// The callback that is called when the mouse pointer enters the widget.
  final void Function(PointerHoverEvent event)? onHover;

  /// The callback that is called when the mouse pointer exits the widget.
  final void Function(PointerExitEvent event)? onExit;

  /// The mouse cursor to display when the mouse pointer is over the widget.
  final SystemMouseCursor cursor;

  /// Whether the widget is disabled.
  final bool? disabled;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: onClick == null || (disabled ?? false)
          ? MouseCursor.defer
          : cursor,
      onHover: onHover,
      onExit: onExit,
      child: GestureDetector(
        onTap: disabled ?? false ? null : onClick,
        child: child,
      ),
    );
  }
}
