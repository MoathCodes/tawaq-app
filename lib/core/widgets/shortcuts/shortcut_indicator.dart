import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/shortcuts/shortcuts.dart';
import 'package:tawaq/core/widgets/shortcuts/shortcut_display.dart';
import 'package:tawaq/theme/theme.dart';

/// Renders keyboard shortcut key caps in a Forui-native style.
class ShortcutIndicator extends StatelessWidget {
  /// Creates a shortcut indicator from a catalog [shortcut].
  const ShortcutIndicator({
    required this.shortcut,
    super.key,
    this.showAliases = false,
  }) : activators = null;

  /// Creates a shortcut indicator from raw activators.
  const ShortcutIndicator.activators({
    required this.activators,
    super.key,
    this.showAliases = false,
  }) : shortcut = null;

  /// Catalog shortcut to display.
  final AppShortcut? shortcut;

  /// Raw activators when not using a catalog [shortcut].
  final List<SingleActivator>? activators;

  /// When true, shows alternate activators separated by "or".
  final bool showAliases;

  List<SingleActivator> get _resolvedActivators {
    if (activators != null) return activators!;
    return shortcut?.activators ?? const [];
  }

  @override
  Widget build(BuildContext context) {
    final resolved = _resolvedActivators;
    if (resolved.isEmpty) {
      return const SizedBox.shrink();
    }

    final combos = showAliases
        ? resolved.map((activator) => [activator]).toList()
        : [
            [resolved.first],
          ];

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < combos.length; i++) ...[
          if (i > 0)
            Text(
              'or',
              style: context.theme.typography.body.xs.copyWith(
                color: context.theme.colors.mutedForeground,
              ),
            ),
          _ShortcutCombo(tokens: activatorDisplayTokens(combos[i].first)),
        ],
      ],
    );
  }
}

/// Renders multiple distinct shortcut combos (e.g. ↑ and ↓).
class ShortcutIndicatorGroup extends StatelessWidget {
  /// Creates a group of shortcut indicators.
  const ShortcutIndicatorGroup({
    required this.shortcuts,
    super.key,
  });

  /// Catalog shortcuts to display.
  final List<AppShortcut> shortcuts;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < shortcuts.length; i++) ...[
          if (i > 0)
            Text(
              '/',
              style: context.theme.typography.body.xs.copyWith(
                color: context.theme.colors.mutedForeground,
              ),
            ),
          ShortcutIndicator(shortcut: shortcuts[i]),
        ],
      ],
    );
  }
}

class _ShortcutCombo extends StatelessWidget {
  const _ShortcutCombo({required this.tokens});

  final List<String> tokens;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.xs,
      children: [
        for (var i = 0; i < tokens.length; i++) ...[
          if (i > 0)
            Text(
              '+',
              style: theme.typography.body.xs.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
          _KeyCap(label: tokens[i]),
        ],
      ],
    );
  }
}

class _KeyCap extends StatelessWidget {
  const _KeyCap({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.colors.secondary,
        borderRadius: theme.radii.sm,
        border: Border.all(color: theme.colors.border),
      ),
      child: Text(
        label,
        style: theme.typography.body.xs.copyWith(
          color: theme.colors.mutedForeground,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
