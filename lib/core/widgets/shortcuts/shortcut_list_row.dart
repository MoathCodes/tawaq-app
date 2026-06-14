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

    final labelColumn = Column(
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
    );

    final indicator = ShortcutIndicator(id: definition.id, showAliases: true);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stack = constraints.maxWidth < context.theme.breakpoints.sm;

          if (stack) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.sm,
              children: [
                labelColumn,
                indicator,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.md,
            children: [
              Expanded(child: labelColumn),
              indicator,
            ],
          );
        },
      ),
    );
  }
}
