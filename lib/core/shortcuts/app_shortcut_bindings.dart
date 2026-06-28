import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tawaq/core/shortcuts/app_shortcut.dart';
import 'package:tawaq/core/shortcuts/app_shortcut_global_handlers.dart';
import 'package:tawaq/core/shortcuts/app_shortcut_invocation.dart';
import 'package:tawaq/core/shortcuts/app_shortcut_platform.dart';

/// Builds activator bindings for global shortcuts.
Map<ShortcutActivator, VoidCallback> buildGlobalShortcutBindings({
  required Iterable<ShortcutDef> shortcuts,
  required AppShortcutInvocation Function() invocationFor,
  bool Function(ShortcutDef shortcut)? shouldSuppress,
}) {
  final bindings = <ShortcutActivator, VoidCallback>{};
  final usedKeys = <String, ShortcutDef>{};

  for (final shortcut in shortcuts) {
    for (final activator in shortcut.activators) {
      final key = activatorKey(activator);
      if (kDebugMode) {
        final existing = usedKeys[key];
        assert(
          existing == null || identical(existing, shortcut),
          'Duplicate activator "$key" for $existing and $shortcut',
        );
      }
      usedKeys[key] = shortcut;

      bindings[activator] = () {
        if (shouldSuppress != null && shouldSuppress(shortcut)) {
          return;
        }
        invokeGlobalShortcut(shortcut, invocationFor());
      };
    }
  }

  return bindings;
}

/// Builds a [CallbackShortcuts] binding map for route/contextual shortcuts.
Map<ShortcutActivator, VoidCallback> buildAppShortcutBindings({
  required Set<ShortcutDef> shortcuts,
  required Map<ShortcutDef, VoidCallback> handlers,
  bool Function(ShortcutDef shortcut)? shouldSuppress,
}) {
  if (kDebugMode) {
    for (final shortcut in shortcuts) {
      assert(
        shortcut.scope != ShortcutScope.global,
        'Global shortcuts belong in ShellShortcutScope, not AppShortcutScope: '
        '$shortcut',
      );
      assert(
        handlers.containsKey(shortcut),
        'Missing handler for $shortcut',
      );
    }
  }

  final bindings = <ShortcutActivator, VoidCallback>{};
  final usedKeys = <String, ShortcutDef>{};

  for (final shortcut in shortcuts) {
    final handler = handlers[shortcut];
    if (handler == null) {
      continue;
    }

    for (final activator in shortcut.activators) {
      final key = activatorKey(activator);
      if (kDebugMode) {
        final existing = usedKeys[key];
        assert(
          existing == null || identical(existing, shortcut),
          'Duplicate activator "$key" for $existing and $shortcut',
        );
      }
      usedKeys[key] = shortcut;

      bindings[activator] = () {
        if (shouldSuppress != null && shouldSuppress(shortcut)) {
          return;
        }
        handler();
      };
    }
  }

  return bindings;
}

/// Whether a descendant text field currently has focus.
bool isTextInputFocused() {
  final focus = FocusManager.instance.primaryFocus;
  if (focus == null || !focus.hasFocus) return false;

  final context = focus.context;
  if (context == null) return false;

  return context.findAncestorWidgetOfExactType<EditableText>() != null;
}

/// Returns true when [shortcut] should be suppressed due to text-field focus.
bool shouldSuppressForTextFieldFocus(ShortcutDef shortcut) {
  if (shortcut.allowWhenTextFieldFocused) return false;
  return isTextInputFocused();
}
