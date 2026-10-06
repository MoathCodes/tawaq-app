import 'package:flutter/widgets.dart';

/// A single accessibility node for icon-only or composite controls.
///
/// Preserves real descendant actions unless an explicit activation replaces them.
/// Use on shell
/// chrome and shared widgets — not on page body content.
class MergedActionSemantics extends StatelessWidget {
  /// Creates merged action semantics.
  const new({
    required this.label,
    required this.child,
    this.hint,
    this.onTap,
    this.selected = false,
    this.enabled = true,
    this.button = true,
    super.key,
  });

  /// Primary announcement (required).
  final String label;

  /// Optional activation or state hint.
  final String? hint;

  /// Explicit activation for a composite that replaces descendant semantics.
  final VoidCallback? onTap;

  /// Whether this control is in a selected state (e.g. current tab).
  final bool selected;

  /// Whether the control can be activated.
  final bool enabled;

  /// Whether assistive tech should treat this as a button.
  final bool button;

  /// The control subtree.
  final Widget child;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Semantics(
      label: label,
      hint: hint,
      selected: selected,
      enabled: enabled,
      button: button,
      onTap: enabled ? onTap : null,
      excludeSemantics: onTap != null,
      child: child,
    ),
  );
}
