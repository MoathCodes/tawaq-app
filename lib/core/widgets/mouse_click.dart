import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MouseClick extends StatelessWidget {
  final Widget child;
  final VoidCallback? onClick;
  final void Function(PointerHoverEvent event)? onHover;
  final void Function(PointerExitEvent event)? onExit;
  final SystemMouseCursor cursor;
  final bool? disabled;
  const MouseClick(
      {super.key,
      required this.child,
      this.onClick,
      this.onHover,
      this.onExit,
      this.cursor = SystemMouseCursors.click,
      this.disabled});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: onClick == null || disabled == true ? MouseCursor.defer : cursor,
      onHover: onHover,
      onExit: onExit,
      child: GestureDetector(
        onTap: disabled == true ? null : onClick,
        child: child,
      ),
    );
  }
}
