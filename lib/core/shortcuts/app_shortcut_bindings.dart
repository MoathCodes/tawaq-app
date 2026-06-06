import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tawaq/core/shortcuts/app_shortcut.dart';
import 'package:tawaq/core/shortcuts/app_shortcut_id.dart';
import 'package:tawaq/core/shortcuts/app_shortcut_platform.dart';
import 'package:tawaq/core/shortcuts/app_shortcut_registry.dart';

/// Builds a [CallbackShortcuts] binding map from registry definitions and
/// handlers.
Map<ShortcutActivator, VoidCallback> buildAppShortcutBindings({
  required Set<AppShortcutId> shortcuts,
  required Map<AppShortcutId, VoidCallback> handlers,
  bool Function(AppShortcutDefinition definition)? shouldInclude,
  bool Function(AppShortcutDefinition definition)? shouldSuppress,
}) {
  if (kDebugMode) {
    for (final id in shortcuts) {
      assert(
        handlers.containsKey(id),
        'Missing handler for AppShortcutId.$id',
      );
    }
  }

  final bindings = <ShortcutActivator, VoidCallback>{};
  final usedKeys = <String, AppShortcutId>{};

  for (final id in shortcuts) {
    final definition = appShortcutById[id];
    if (definition == null) {
      assert(false, 'Unknown AppShortcutId: $id');
      continue;
    }
    if (shouldInclude != null && !shouldInclude(definition)) continue;

    final handler = handlers[id];
    if (handler == null) continue;

    for (final activator in definition.activators) {
      final key = activatorKey(activator);
      if (kDebugMode) {
        final existing = usedKeys[key];
        assert(
          existing == null || existing == id,
          'Duplicate activator "$key" for ${existing.name} and ${id.name}',
        );
      }
      usedKeys[key] = id;

      bindings[activator] = () {
        if (shouldSuppress != null && shouldSuppress(definition)) {
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

/// Returns true when [definition] should be suppressed due to text-field focus.
bool shouldSuppressForTextFieldFocus(AppShortcutDefinition definition) {
  if (definition.allowWhenTextFieldFocused) return false;
  return isTextInputFocused();
}
