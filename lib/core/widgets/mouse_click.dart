import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/foundation.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';

/// A widget that detects mouse clicks and hover events.
class MouseClick extends StatelessWidget {
  /// Creates a mouse click detector.
  const MouseClick({
    this.child = const SizedBox.shrink(),
    super.key,
    this.onClick,
    this.builder,
    this.onHoverChange,
    this.disabled,
    this.semanticsLabel,
    this.semanticsTooltip,
  });

  /// The widget below this widget in the tree.
  final Widget child;

  /// The callback that is called when the widget is clicked.
  final VoidCallback? onClick;

  /// The callback that is called when the mouse pointer enters the widget.
  final void Function(bool hovering)? onHoverChange;

  /// Whether the widget is disabled.
  final bool? disabled;

  /// Merged accessibility label when this control should be announced.
  final String? semanticsLabel;

  /// Merged accessibility tooltip when this control should be announced.
  final String? semanticsTooltip;

  /// Optional builder for customizing the child widget based on the current state of the mouse click.
  final Widget Function(
    BuildContext context,
    Set<FTappableVariant> states,
    Widget? child,
  )?
  builder;

  @override
  Widget build(BuildContext context) {
    final isDisabled = disabled ?? false;
    final interactive = onClick != null && !isDisabled;

    final content = interactive ? NonSelectable(child: child) : child;

    return FTappable.static(
      style: .delta(
        cursor: .delta([
          .all(
            interactive ? SystemMouseCursors.click : MouseCursor.defer,
          ),
        ]),
      ),
      shortcuts: interactive
          ? const {
              SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
              SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
            }
          : null,
      builder:
          builder ??
          (context, states, child) => FFocusedOutline(
            focused: states.contains(FTappableVariant.primaryFocused),
            child: child,
          ),
      excludeSemantics: semanticsLabel != null,
      semanticsLabel: semanticsLabel,
      semanticsTooltip: semanticsTooltip,
      onHoverChange: onHoverChange,
      onPress: isDisabled ? null : onClick,
      child: content,
    );
  }
}
