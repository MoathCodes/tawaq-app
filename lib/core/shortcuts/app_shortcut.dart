import 'package:flutter/material.dart';
import 'package:tawaq/core/shortcuts/app_shortcut_id.dart';

/// High-level grouping for the settings reference list.
enum AppShortcutCategory {
  /// Shortcuts available everywhere in the shell.
  global,

  /// Quran reader shortcuts.
  quran,

  /// Muslim Fortress shortcuts.
  fortress,
}

/// Where a shortcut is active and may be bound.
enum AppShortcutBindingScope {
  /// Active for the entire application shell.
  global,

  /// Active on a specific route path prefix.
  route,

  /// Active only in a feature sub-mode (e.g. fortress focus reading).
  contextual,
}

/// Metadata and activators for a single keyboard shortcut.
class AppShortcutDefinition {
  /// Creates a shortcut definition.
  const AppShortcutDefinition({
    required this.id,
    required this.category,
    required this.scope,
    required this.activators,
    this.routePath,
    this.contextTag,
    this.visibleInSettings = true,
    this.allowWhenTextFieldFocused = false,
  });

  /// Unique shortcut identifier.
  final AppShortcutId id;

  /// Settings grouping category.
  final AppShortcutCategory category;

  /// Binding scope.
  final AppShortcutBindingScope scope;

  /// Route path prefix when [scope] is [AppShortcutBindingScope.route].
  final String? routePath;

  /// Human-readable sub-mode tag when [scope] is
  /// [AppShortcutBindingScope.contextual].
  final String? contextTag;

  /// Keyboard activators (aliases included).
  final List<SingleActivator> activators;

  /// Whether this shortcut appears in the settings reference list.
  final bool visibleInSettings;

  /// When false, suppressed while a text field has focus (except global
  /// shortcuts that set this to true, e.g. [AppShortcutId.focusSearch]).
  final bool allowWhenTextFieldFocused;

  /// Scope key used for duplicate-detection in tests.
  String get scopeKey {
    return switch (scope) {
      AppShortcutBindingScope.global => 'global',
      AppShortcutBindingScope.route => 'route:$routePath',
      AppShortcutBindingScope.contextual => 'contextual:$contextTag',
    };
  }
}
