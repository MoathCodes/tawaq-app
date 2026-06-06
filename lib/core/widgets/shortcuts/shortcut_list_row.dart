import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/shortcuts/app_shortcut.dart';
import 'package:tawaq/core/shortcuts/app_shortcut_l10n.dart';
import 'package:tawaq/core/widgets/shortcuts/shortcut_indicator.dart';
import 'package:tawaq/theme/theme.dart';

/// A read-only settings row showing a shortcut label and key combo.
class ShortcutListRow extends StatelessWidget {
  /// Creates a shortcut list row.
  const ShortcutListRow({
    required this.definition,
    super.key,
  });

  /// Shortcut metadata from the registry.
  final AppShortcutDefinition definition;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = context.theme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.xs,
              children: [
                Text(
                  definition.label(l10n),
                  style: theme.typography.sm.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  definition.description(l10n),
                  style: theme.typography.xs.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          ShortcutIndicator(id: definition.id, showAliases: true),
        ],
      ),
    );
  }
}
