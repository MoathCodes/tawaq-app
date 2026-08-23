import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/shortcuts/shortcuts.dart';
import 'package:tawaq/core/widgets/animated_icon_button.dart';
import 'package:tawaq/core/widgets/merged_action_semantics.dart';
import 'package:tawaq/core/widgets/shell_a11y.dart';
import 'package:tawaq/core/widgets/shortcuts/shortcut_hint.dart';
import 'package:tawaq/feature/settings/presentation/provider/theme_settings_provider.dart';

/// A button that toggles the theme mode between light and dark.
class ThemeModeButton extends ConsumerWidget {
  /// Creates a theme mode button.
  const new({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(
      themeProvider.select((s) => s.value?.themeMode == ThemeMode.dark),
    );
    return ShortcutTooltip(
      shortcut: AppShortcut.toggleTheme,
      child: MergedActionSemantics(
        label: ShellA11y.themeToggleLabel(context.l10n, isDark: isDark),
        child: AnimatedIconButton(
          primaryIcon: FLucideIcons.sun,
          secondaryIcon: FLucideIcons.moon,
          animationDuration: const Duration(milliseconds: 300),
          variant: .ghost,
          size: FButtonSizeVariant.xs,
          iconSize: 16,
          isSecondaryActive: isDark,
          onPressed: () {
            ref.read(themeProvider.notifier).toggleThemeMode();
          },
        ),
      ),
    );
  }
}
