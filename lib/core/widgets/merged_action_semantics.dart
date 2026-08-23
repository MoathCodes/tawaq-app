import 'package:flutter/widgets.dart';

/// A single accessibility node for icon-only or composite controls.
///
/// Hides descendant semantics to avoid duplicate announcements. Use on shell
/// chrome and shared widgets — not on page body content.
class MergedActionSemantics extends StatelessWidget {
  /// Creates merged action semantics.
  const new({
    required this.label,
    required this.child,
    this.hint,
    this.selected = false,
    this.enabled = true,
    this.button = true,
    super.key,
  });

  /// Primary announcement (required).
  final String label;

  /// Optional activation or state hint.
  final String? hint;

  /// Whether this control is in a selected state (e.g. current tab).
  final bool selected;

  /// Whether the control can be activated.
  final bool enabled;

  /// Whether assistive tech should treat this as a button.
  final bool button;

  /// The control subtree.
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    hint: hint,
    selected: selected,
    enabled: enabled,
    button: button,
    excludeSemantics: true,
    child: child,
  );
}
