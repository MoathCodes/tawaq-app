import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';

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
    this.semanticsLabel,
    this.semanticsHint,
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

  /// Merged accessibility label when this control should be announced.
  final String? semanticsLabel;

  /// Optional hint merged with [semanticsLabel] for assistive technologies.
  final String? semanticsHint;

  @override
  Widget build(BuildContext context) {
    final isDisabled = disabled ?? false;
    final interactive = onClick != null && !isDisabled;
    final hasSemantics = semanticsLabel != null || semanticsHint != null;

    final content = interactive ? NonSelectable(child: child) : child;

    final pointer = MouseRegion(
      cursor: onClick == null || isDisabled ? MouseCursor.defer : cursor,
      onHover: onHover,
      onExit: onExit,
      child: GestureDetector(
        onTap: isDisabled ? null : onClick,
        child: content,
      ),
    );

    if (!hasSemantics && interactive) {
      return pointer;
    }
    if (!hasSemantics && !interactive) {
      return pointer;
    }

    return Semantics(
      label: semanticsLabel,
      hint: semanticsHint,
      button: interactive,
      enabled: interactive,
      excludeSemantics: hasSemantics,
      child: pointer,
    );
  }
}
