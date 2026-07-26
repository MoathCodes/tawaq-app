import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tawaq/core/shortcuts/app_shortcut_platform.dart';

/// High-level grouping for the settings reference list.
enum AppShortcutCategory {
  /// Shortcuts available everywhere in the shell.
  global,

  /// Quran reader shortcuts.
  quran,

  /// Muslim Fortress shortcuts.
  fortress,

  /// Hadith search and detail shortcuts.
  hadith,
}

/// Whether a shortcut is shell-global, route-scoped, or contextual.
enum ShortcutScope {
  /// Active everywhere in the shell.
  global,

  /// Active on a typed navigation route.
  route,

  /// Active in a feature sub-mode.
  contextual,
}

/// Canonical keyboard shortcut entry (activators + metadata).
final class ShortcutDef {
  /// Creates a shortcut definition.
  const ShortcutDef({
    required this.id,
    required this.category,
    required this.activators,
    required this.scope,
    this.routePath,
    this.contextTag,
    this.visibleInSettings = true,
    this.allowWhenTextFieldFocused = false,
  });

  /// Stable identifier used for handler dispatch and l10n lookup.
  final String id;

  /// Settings grouping category.
  final AppShortcutCategory category;

  /// Keyboard activators (aliases included).
  final List<SingleActivator> activators;

  /// Scope that controls duplicate-detection and binding placement.
  final ShortcutScope scope;

  /// Route path when [scope] is [ShortcutScope.route].
  final String? routePath;

  /// Sub-mode tag when [scope] is [ShortcutScope.contextual].
  final String? contextTag;

  /// Whether this shortcut appears in the settings reference list.
  final bool visibleInSettings;

  /// When false, suppressed while a text field has focus.
  final bool allowWhenTextFieldFocused;

  /// Scope key used for duplicate-detection in tests.
  String get scopeKey => switch (scope) {
        ShortcutScope.global => 'global',
        ShortcutScope.route => 'route:$routePath',
        ShortcutScope.contextual => 'contextual:$contextTag',
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ShortcutDef && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Catalog of every application keyboard shortcut.
abstract final class AppShortcut {
  static final toggleTheme = ShortcutDef(
    id: 'toggleTheme',
    category: AppShortcutCategory.global,
    scope: ShortcutScope.global,
    activators: desktopModShortcut(LogicalKeyboardKey.keyD, shift: true),
    allowWhenTextFieldFocused: true,
  );

  static final toggleLocale = ShortcutDef(
    id: 'toggleLocale',
    category: AppShortcutCategory.global,
    scope: ShortcutScope.global,
    activators: desktopModShortcut(LogicalKeyboardKey.keyL, shift: true),
    allowWhenTextFieldFocused: true,
  );

  static final openSettings = ShortcutDef(
    id: 'openSettings',
    category: AppShortcutCategory.global,
    scope: ShortcutScope.global,
    activators: desktopModShortcut(LogicalKeyboardKey.comma),
    allowWhenTextFieldFocused: true,
  );

  static final focusSearch = ShortcutDef(
    id: 'focusSearch',
    category: AppShortcutCategory.global,
    scope: ShortcutScope.global,
    activators: desktopModShortcut(LogicalKeyboardKey.keyK),
    allowWhenTextFieldFocused: true,
  );

  static final quranPageNext = ShortcutDef(
    id: 'quranPageNext',
    category: AppShortcutCategory.quran,
    scope: ShortcutScope.route,
    routePath: '/quran',
    activators: [plainShortcut(LogicalKeyboardKey.arrowLeft)],
  );

  static final quranPagePrev = ShortcutDef(
    id: 'quranPagePrev',
    category: AppShortcutCategory.quran,
    scope: ShortcutScope.route,
    routePath: '/quran',
    activators: [plainShortcut(LogicalKeyboardKey.arrowRight)],
  );

  static final quranPageNextSpace = ShortcutDef(
    id: 'quranPageNextSpace',
    category: AppShortcutCategory.quran,
    scope: ShortcutScope.route,
    routePath: '/quran',
    activators: [plainShortcut(LogicalKeyboardKey.space)],
  );

  static final quranZoomIn = ShortcutDef(
    id: 'quranZoomIn',
    category: AppShortcutCategory.quran,
    scope: ShortcutScope.route,
    routePath: '/quran',
    activators: [
      ...desktopModShortcut(LogicalKeyboardKey.equal),
      ...desktopModShortcut(LogicalKeyboardKey.add),
    ],
  );

  static final quranZoomOut = ShortcutDef(
    id: 'quranZoomOut',
    category: AppShortcutCategory.quran,
    scope: ShortcutScope.route,
    routePath: '/quran',
    activators: desktopModShortcut(LogicalKeyboardKey.minus),
  );

  static final quranZoomReset = ShortcutDef(
    id: 'quranZoomReset',
    category: AppShortcutCategory.quran,
    scope: ShortcutScope.route,
    routePath: '/quran',
    activators: desktopModShortcut(LogicalKeyboardKey.digit0),
  );

  static final quranAyahNext = ShortcutDef(
    id: 'quranAyahNext',
    category: AppShortcutCategory.quran,
    scope: ShortcutScope.contextual,
    contextTag: 'quran.studyPanel',
    activators: [
      plainShortcut(LogicalKeyboardKey.arrowLeft),
      plainShortcut(LogicalKeyboardKey.arrowDown),
    ],
  );

  static final quranAyahPrev = ShortcutDef(
    id: 'quranAyahPrev',
    category: AppShortcutCategory.quran,
    scope: ShortcutScope.contextual,
    contextTag: 'quran.studyPanel',
    activators: [
      plainShortcut(LogicalKeyboardKey.arrowRight),
      plainShortcut(LogicalKeyboardKey.arrowUp),
    ],
  );

  static final fortressCount = ShortcutDef(
    id: 'fortressCount',
    category: AppShortcutCategory.fortress,
    scope: ShortcutScope.contextual,
    contextTag: 'fortress.focusReading',
    activators: [
      plainShortcut(LogicalKeyboardKey.space),
      plainShortcut(LogicalKeyboardKey.enter),
    ],
  );

  static final fortressThikrNext = ShortcutDef(
    id: 'fortressThikrNext',
    category: AppShortcutCategory.fortress,
    scope: ShortcutScope.contextual,
    contextTag: 'fortress.focusReading',
    activators: [
      plainShortcut(LogicalKeyboardKey.arrowLeft),
      plainShortcut(LogicalKeyboardKey.arrowDown),
    ],
  );

  static final fortressThikrPrev = ShortcutDef(
    id: 'fortressThikrPrev',
    category: AppShortcutCategory.fortress,
    scope: ShortcutScope.contextual,
    contextTag: 'fortress.focusReading',
    activators: [
      plainShortcut(LogicalKeyboardKey.arrowRight),
      plainShortcut(LogicalKeyboardKey.arrowUp),
    ],
  );

  static final hadithResultNext = ShortcutDef(
    id: 'hadithResultNext',
    category: AppShortcutCategory.hadith,
    scope: ShortcutScope.route,
    routePath: '/hadith',
    activators: [
      plainShortcut(LogicalKeyboardKey.arrowLeft),
      plainShortcut(LogicalKeyboardKey.arrowDown),
    ],
  );

  static final hadithResultPrev = ShortcutDef(
    id: 'hadithResultPrev',
    category: AppShortcutCategory.hadith,
    scope: ShortcutScope.route,
    routePath: '/hadith',
    activators: [
      plainShortcut(LogicalKeyboardKey.arrowRight),
      plainShortcut(LogicalKeyboardKey.arrowUp),
    ],
  );

  /// Every shortcut in the application.
  static final List<ShortcutDef> all = [
    toggleTheme,
    toggleLocale,
    openSettings,
    focusSearch,
    quranPageNext,
    quranPagePrev,
    quranPageNextSpace,
    quranZoomIn,
    quranZoomOut,
    quranZoomReset,
    quranAyahNext,
    quranAyahPrev,
    fortressCount,
    fortressThikrNext,
    fortressThikrPrev,
    hadithResultNext,
    hadithResultPrev,
  ];
}

/// Shortcuts visible in the settings reference list.
Iterable<ShortcutDef> get visibleAppShortcuts =>
    AppShortcut.all.where((shortcut) => shortcut.visibleInSettings);

/// Shortcuts grouped by category for the settings UI.
Map<AppShortcutCategory, List<ShortcutDef>> appShortcutsByCategory() {
  final grouped = <AppShortcutCategory, List<ShortcutDef>>{};
  for (final shortcut in visibleAppShortcuts) {
    grouped.putIfAbsent(shortcut.category, () => []).add(shortcut);
  }
  return grouped;
}

/// Returns duplicate activator keys within the same scope (for tests/debug).
Map<String, List<ShortcutDef>> findDuplicateActivators() {
  final duplicates = <String, List<ShortcutDef>>{};

  final byScope = <String, List<ShortcutDef>>{};
  for (final shortcut in AppShortcut.all) {
    byScope.putIfAbsent(shortcut.scopeKey, () => []).add(shortcut);
  }

  for (final entry in byScope.entries) {
    final seen = <String, ShortcutDef>{};
    for (final shortcut in entry.value) {
      for (final activator in shortcut.activators) {
        final key = activatorKey(activator);
        final prior = seen[key];
        if (prior != null && prior != shortcut) {
          duplicates
              .putIfAbsent(entry.key, () => [])
              .addAll([prior, shortcut]);
        } else {
          seen[key] = shortcut;
        }
      }
    }
  }

  return duplicates;
}
