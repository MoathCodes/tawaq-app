import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tawaq/app/shortcuts/app_shortcut_global_handlers.dart';
import 'package:tawaq/core/shortcuts/shortcuts.dart';

/// Global keyboard shortcuts for the application shell.
///
/// Uses a [HardwareKeyboard] handler so shortcuts work even when no widget in
/// the tree currently holds focus (e.g. the settings reference tab).
class ShellShortcutScope extends ConsumerStatefulWidget {
  /// Creates a shell shortcut scope.
  const ShellShortcutScope({required this.child, super.key});

  /// Child widget tree.
  final Widget child;

  /// Global shortcuts dispatched via [invokeGlobalShortcut].
  static final List<ShortcutDef> globalShortcuts = [
    AppShortcut.toggleTheme,
    AppShortcut.toggleLocale,
    AppShortcut.openSettings,
    AppShortcut.focusSearch,
  ];

  @override
  ConsumerState<ShellShortcutScope> createState() => _ShellShortcutScopeState();
}

class _ShellShortcutScopeState extends ConsumerState<ShellShortcutScope> {
  late final Map<ShortcutActivator, VoidCallback> _bindings =
      buildGlobalShortcutBindings(
        shortcuts: ShellShortcutScope.globalShortcuts,
        invocationFor: () => AppShortcutInvocation(ref: ref, context: context),
        onInvoke: invokeGlobalShortcut,
        shouldSuppress: shouldSuppressForTextFieldFocus,
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
}
