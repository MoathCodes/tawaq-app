import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';

/// Explicit button semantics for fortress nav actions (prev / next / study).
class FortressLabeledNavButton extends StatelessWidget {
  /// Creates a labeled nav button.
  const FortressLabeledNavButton({
    required this.label,
    required this.enabled,
    required this.onPress,
    required this.child,
    this.prefix,
    this.iconOnly = false,
    super.key,
  });

  final String label;
  final bool enabled;
  final VoidCallback? onPress;
  final Widget child;
  final Widget? prefix;

  /// When true, only [prefix] is shown (accessibility via [label]).
  final bool iconOnly;

  @override
  Widget build(BuildContext context) => NonSelectable(
    child: FButton(
      variant: .outline,
      semanticsLabel: label,
      onPress: enabled ? onPress : null,
      prefix: prefix,
      child: iconOnly ? const SizedBox.shrink() : child,
    ),
  );
}
