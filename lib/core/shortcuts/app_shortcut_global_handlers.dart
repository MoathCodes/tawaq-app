import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/locale/locale_provider.dart';
import 'package:tawaq/core/routing/route_provider.dart';
import 'package:tawaq/core/shortcuts/app_search_focus_registry.dart';
import 'package:tawaq/core/shortcuts/app_shortcut.dart';
import 'package:tawaq/core/shortcuts/app_shortcut_invocation.dart';
import 'package:tawaq/feature/settings/presentation/provider/theme_settings_provider.dart';

/// Dispatches a global [ShortcutDef] from shell shortcut scope.
void invokeGlobalShortcut(
  ShortcutDef shortcut,
  AppShortcutInvocation invocation,
) {
  switch (shortcut.id) {
    case 'toggleTheme':
      invocation.ref.read(themeProvider.notifier).toggleThemeMode();
    case 'toggleLocale':
      invocation.ref.read(localeProvider.notifier).toggleLocale();
    case 'openSettings':
      if (invocation.context.mounted) {
        const SettingsRoute().go(invocation.context);
      }
    case 'focusSearch':
      if (AppSearchFocusRegistry.instance.focus()) {
        return;
      }
      if (invocation.context.mounted) {
        showFToast(
          context: invocation.context,
          title: Text(invocation.context.l10n.shortcutFocusSearchUnavailable),
        );
      }
  }
}
