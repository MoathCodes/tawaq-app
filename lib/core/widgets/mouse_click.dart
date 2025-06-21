import 'package:flutter/services.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class MouseClick extends StatelessWidget {
  final Widget child;
  final VoidCallback onClick;
  final void Function(PointerHoverEvent)? onHover;
  final void Function(PointerExitEvent)? onExit;
  final SystemMouseCursor cursor;
  final bool? disabled;
  const MouseClick(
      {super.key,
      required this.child,
      required this.onClick,
      this.onHover,
      this.onExit,
      this.cursor = SystemMouseCursors.click,
      this.disabled});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: cursor,
      onHover: onHover,
      onExit: onExit,
      child: GestureDetector(
        onTap: disabled == true ? null : onClick,
        child: child,
      ),
    );
  }
}
