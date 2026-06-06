import 'package:flutter/material.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/shortcuts/app_shortcut.dart';
import 'package:tawaq/core/shortcuts/app_shortcut_l10n.dart';
import 'package:tawaq/core/shortcuts/app_shortcut_platform.dart';
import 'package:tawaq/core/shortcuts/app_shortcut_registry.dart';
import 'package:tawaq/core/widgets/shortcuts/shortcut_list_row.dart';
import 'package:tawaq/feature/settings/presentation/widgets/settings_section.dart';
import 'package:tawaq/theme/theme.dart';

/// Read-only reference list of keyboard shortcuts from the registry.
class KeyboardShortcutsSection extends StatelessWidget {
  /// Creates the keyboard shortcuts settings section.
  const KeyboardShortcutsSection({super.key});

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
            SettingsSection(
              title: category.title(l10n),
              subtitle: l10n.keyboardShortcutsCategorySubtitle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final definition in grouped[category]!)
                    ShortcutListRow(definition: definition),
                ],
              ),
            ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}
