import 'package:flutter/material.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/shortcuts/shortcuts.dart';
import 'package:tawaq/core/widgets/shortcuts/shortcut_list_row.dart';
import 'package:tawaq/feature/settings/presentation/widgets/settings_section.dart';
import 'package:tawaq/theme/theme.dart';

/// Read-only reference list of keyboard shortcuts from the catalog.
class KeyboardShortcutsSection extends StatelessWidget {
  /// Creates the keyboard shortcuts settings section.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    if (!supportsKeyboardShortcuts) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;
    final grouped = appShortcutsByCategory();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.lg,
      children: [
        for (final category in AppShortcutCategory.values)
          if (grouped[category]?.isNotEmpty ?? false)
            SettingsGroup(
              title: category.title(l10n),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final shortcut in grouped[category]!)
                    ShortcutListRow(shortcut: shortcut),
                ],
              ),
            ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}
