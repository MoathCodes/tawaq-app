import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/locale/locale_provider.dart';
import 'package:tawaq/core/routing/route_provider.dart';
import 'package:tawaq/core/shortcuts/app_search_focus_registry.dart';
import 'package:tawaq/core/shortcuts/app_shortcut_bindings.dart';
import 'package:tawaq/core/shortcuts/app_shortcut_id.dart';
import 'package:tawaq/core/shortcuts/app_shortcut_platform.dart';
import 'package:tawaq/feature/settings/presentation/provider/theme_settings_provider.dart';

/// Global keyboard shortcuts for the application shell.
///
/// Uses a [HardwareKeyboard] handler so shortcuts work even when no widget in
/// the tree currently holds focus (e.g. the settings reference tab).
class ShellShortcutScope extends ConsumerStatefulWidget {
  /// Creates a shell shortcut scope.
  const ShellShortcutScope({required this.child, super.key});

  /// Child widget tree.
  final Widget child;

  static const Set<AppShortcutId> globalShortcuts = {
    AppShortcutId.toggleTheme,
    AppShortcutId.toggleLocale,
    AppShortcutId.openSettings,
    AppShortcutId.focusSearch,
  };

  @override
  ConsumerState<ShellShortcutScope> createState() => _ShellShortcutScopeState();
}

class _ShellShortcutScopeState extends ConsumerState<ShellShortcutScope> {
  late final Map<ShortcutActivator, VoidCallback> _bindings =
      buildAppShortcutBindings(
        shortcuts: ShellShortcutScope.globalShortcuts,
        handlers: {
          AppShortcutId.toggleTheme: _toggleTheme,
          AppShortcutId.toggleLocale: _toggleLocale,
          AppShortcutId.openSettings: _openSettings,
          AppShortcutId.focusSearch: _handleFocusSearch,
        },
      );

  @override
  void initState() {
    super.initState();
    if (supportsKeyboardShortcuts) {
      HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    }
  }

  @override
  void dispose() {
    if (supportsKeyboardShortcuts) {
      HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;

  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return false;
    }

    for (final MapEntry(:key, :value) in _bindings.entries) {
      if (key.accepts(event, HardwareKeyboard.instance)) {
        value();
        return true;
      }
    }
    return false;
  }

  void _toggleTheme() {
    ref.read(themeProvider.notifier).toggleThemeMode();
  }

  void _toggleLocale() {
    ref.read(localeProvider.notifier).toggleLocale();
  }

  void _openSettings() {
    if (!mounted) return;
    const SettingsRoute().go(context);
  }

  void _handleFocusSearch() {
    if (AppSearchFocusRegistry.instance.focus()) {
      return;
    }

    if (!mounted) {
      return;
    }

    showFToast(
      context: context,
      title: Text(context.l10n.shortcutFocusSearchUnavailable),
    );
  }
}
