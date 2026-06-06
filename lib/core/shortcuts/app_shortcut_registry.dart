import 'package:tawaq/core/shortcuts/app_shortcut.dart';
import 'package:tawaq/core/shortcuts/app_shortcut_activators.dart';
import 'package:tawaq/core/shortcuts/app_shortcut_id.dart';
import 'package:tawaq/core/shortcuts/app_shortcut_platform.dart';

/// Canonical list of every application keyboard shortcut.
final List<AppShortcutDefinition> appShortcutRegistry = [
  AppShortcutDefinition(
    id: AppShortcutId.toggleTheme,
    category: AppShortcutCategory.global,
    scope: AppShortcutBindingScope.global,
    activators: toggleThemeActivators,
    allowWhenTextFieldFocused: true,
  ),
  AppShortcutDefinition(
    id: AppShortcutId.toggleLocale,
    category: AppShortcutCategory.global,
    scope: AppShortcutBindingScope.global,
    activators: toggleLocaleActivators,
    allowWhenTextFieldFocused: true,
  ),
  AppShortcutDefinition(
    id: AppShortcutId.openSettings,
    category: AppShortcutCategory.global,
    scope: AppShortcutBindingScope.global,
    activators: openSettingsActivators,
    allowWhenTextFieldFocused: true,
  ),
  AppShortcutDefinition(
    id: AppShortcutId.focusSearch,
    category: AppShortcutCategory.global,
    scope: AppShortcutBindingScope.global,
    activators: focusSearchActivators,
    allowWhenTextFieldFocused: true,
  ),
  AppShortcutDefinition(
    id: AppShortcutId.quranPageNext,
    category: AppShortcutCategory.quran,
    scope: AppShortcutBindingScope.route,
    routePath: '/quran',
    activators: [quranPageNextActivator],
  ),
  AppShortcutDefinition(
    id: AppShortcutId.quranPagePrev,
    category: AppShortcutCategory.quran,
    scope: AppShortcutBindingScope.route,
    routePath: '/quran',
    activators: [quranPagePrevActivator],
  ),
  AppShortcutDefinition(
    id: AppShortcutId.quranPageNextSpace,
    category: AppShortcutCategory.quran,
    scope: AppShortcutBindingScope.route,
    routePath: '/quran',
    activators: [quranPageNextSpaceActivator],
  ),
  AppShortcutDefinition(
    id: AppShortcutId.quranAyahNext,
    category: AppShortcutCategory.quran,
    scope: AppShortcutBindingScope.contextual,
    contextTag: 'quran.studyPanel',
    activators: quranAyahNextActivators,
  ),
  AppShortcutDefinition(
    id: AppShortcutId.quranAyahPrev,
    category: AppShortcutCategory.quran,
    scope: AppShortcutBindingScope.contextual,
    contextTag: 'quran.studyPanel',
    activators: quranAyahPrevActivators,
  ),
  AppShortcutDefinition(
    id: AppShortcutId.fortressCount,
    category: AppShortcutCategory.fortress,
    scope: AppShortcutBindingScope.contextual,
    contextTag: 'fortress.focusReading',
    activators: fortressCountActivators,
  ),
  AppShortcutDefinition(
    id: AppShortcutId.fortressThikrNext,
    category: AppShortcutCategory.fortress,
    scope: AppShortcutBindingScope.contextual,
    contextTag: 'fortress.focusReading',
    activators: fortressThikrNextActivators,
  ),
  AppShortcutDefinition(
    id: AppShortcutId.fortressThikrPrev,
    category: AppShortcutCategory.fortress,
    scope: AppShortcutBindingScope.contextual,
    contextTag: 'fortress.focusReading',
    activators: fortressThikrPrevActivators,
  ),
];

/// Lookup table from [AppShortcutId] to its definition.
final Map<AppShortcutId, AppShortcutDefinition> appShortcutById = {
  for (final definition in appShortcutRegistry) definition.id: definition,
};

/// Definitions visible in the settings reference list.
Iterable<AppShortcutDefinition> get visibleAppShortcuts =>
    appShortcutRegistry.where((definition) => definition.visibleInSettings);

/// Definitions grouped by category for the settings UI.
Map<AppShortcutCategory, List<AppShortcutDefinition>>
    appShortcutsByCategory() {
  final grouped = <AppShortcutCategory, List<AppShortcutDefinition>>{};
  for (final definition in visibleAppShortcuts) {
    grouped.putIfAbsent(definition.category, () => []).add(definition);
  }
  return grouped;
}

/// Returns duplicate activator keys within the same scope (for tests/debug).
Map<String, List<AppShortcutId>> findDuplicateActivatorsInRegistry() {
  final scopeActivators = <String, Map<String, AppShortcutId>>{};

  for (final definition in appShortcutRegistry) {
    final scopeMap = scopeActivators.putIfAbsent(
      definition.scopeKey,
      () => {},
    );
    for (final activator in definition.activators) {
      final key = activatorKey(activator);
      final existing = scopeMap[key];
      if (existing != null && existing != definition.id) {
        // Mark duplicate — collected below.
      }
      scopeMap[key] = definition.id;
    }
  }

  final duplicates = <String, List<AppShortcutId>>{};
  for (final entry in scopeActivators.entries) {
    final seen = <String, AppShortcutId>{};
    for (final definition in appShortcutRegistry) {
      if (definition.scopeKey != entry.key) continue;
      for (final activator in definition.activators) {
        final key = activatorKey(activator);
        final prior = seen[key];
        if (prior != null && prior != definition.id) {
          duplicates
              .putIfAbsent(entry.key, () => [])
              .addAll([prior, definition.id]);
        } else {
          seen[key] = definition.id;
        }
      }
    }
  }
  return duplicates;
}
