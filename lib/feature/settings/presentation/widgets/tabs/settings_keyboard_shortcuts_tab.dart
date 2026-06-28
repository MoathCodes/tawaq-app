import 'package:flutter/material.dart';
import 'package:tawaq/feature/settings/presentation/widgets/keyboard_shortcuts/keyboard_shortcuts_section.dart';

/// Keyboard shortcuts settings tab body.
class SettingsKeyboardShortcutsTab extends StatelessWidget {
  /// Creates [SettingsKeyboardShortcutsTab].
  const SettingsKeyboardShortcutsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const KeyboardShortcutsSection();
  }
}
