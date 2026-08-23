import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/shortcuts/shortcuts.dart';
import 'package:tawaq/core/widgets/shortcuts/shortcut_indicator.dart';

/// Wraps [child] with a Forui tooltip that shows the shortcut key combo on hover.
class ShortcutTooltip extends StatelessWidget {
  /// Creates a shortcut tooltip from a catalog [shortcut].
  const new({
    required this.shortcut,
    required this.child,
    super.key,
  })  : activators = null,
        hintTokens = null;

  /// Creates a shortcut tooltip from raw [activators] (no catalog entry).
  const new activators({
    required this.activators,
    required this.child,
    super.key,
  })  : shortcut = null,
        hintTokens = null;

  /// Creates a shortcut tooltip from preformatted key-cap [hintTokens].
  const new tokens({
    required this.hintTokens,
    required this.child,
    super.key,
  })  : shortcut = null,
        activators = null;

  /// Catalog shortcut to display in the tooltip.
  final ShortcutDef? shortcut;

  /// Raw activators when not using a catalog [shortcut].
  final List<SingleActivator>? activators;

  /// Preformatted key-cap labels (e.g. `['Ctrl', 'K']`).
  final List<String>? hintTokens;

  /// The control that triggers the tooltip on hover.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!supportsKeyboardShortcuts) {
      return child;
    }

    final Widget indicator;
    if (shortcut != null) {
      indicator = ShortcutIndicator(shortcut: shortcut, showAliases: true);
    } else if (activators != null) {
      indicator = ShortcutIndicator.activators(
        activators: activators,
        showAliases: true,
      );
    } else {
      indicator = ShortcutIndicator.tokens(tokens: hintTokens ?? const []);
    }

    return FTooltip(
      tipBuilder: (context, controller) => indicator,
      child: child,
    );
  }
}
