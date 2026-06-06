import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/shortcuts/app_shortcut_id.dart';
import 'package:tawaq/core/shortcuts/app_shortcut_platform.dart';
import 'package:tawaq/core/widgets/shortcuts/shortcut_indicator.dart';

/// Wraps [child] with a Forui tooltip that shows the shortcut key combo on hover.
class ShortcutTooltip extends StatelessWidget {
  /// Creates a shortcut tooltip wrapper.
  const ShortcutTooltip({
    required this.id,
    required this.child,
    super.key,
  });

  /// Registry shortcut to display in the tooltip.
  final AppShortcutId id;

  /// The control that triggers the tooltip on hover.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!supportsKeyboardShortcuts) {
      return child;
    }

    return FTooltip(
      tipBuilder: (context, controller) => ShortcutIndicator(
        id: id,
        showAliases: true,
      ),
      child: child,
    );
  }
}
