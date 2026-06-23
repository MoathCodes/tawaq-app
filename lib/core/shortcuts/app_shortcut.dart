import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/locale/locale_provider.dart';
import 'package:tawaq/core/routing/route_provider.dart';
import 'package:tawaq/core/shortcuts/app_search_focus_registry.dart';
import 'package:tawaq/core/shortcuts/app_shortcut_invocation.dart';
import 'package:tawaq/core/shortcuts/app_shortcut_platform.dart';
import 'package:tawaq/feature/settings/presentation/provider/theme_settings_provider.dart';

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

/// Canonical catalog entry for a keyboard shortcut.
sealed class AppShortcut {
  const AppShortcut();

  /// Toggle light/dark theme.
  static const toggleTheme = ToggleThemeShortcut();

  /// Toggle English/Arabic locale.
  static const toggleLocale = ToggleLocaleShortcut();

  /// Open the settings screen.
  static const openSettings = OpenSettingsShortcut();

  /// Focus the contextual search field.
  static const focusSearch = FocusSearchShortcut();

  /// Advance to the next mushaf page (RTL reading direction).
  static const quranPageNext = QuranPageNextShortcut();

  /// Go to the previous mushaf page.
  static const quranPagePrev = QuranPagePrevShortcut();

  /// Advance to the next mushaf page via Space.
  static const quranPageNextSpace = QuranPageNextSpaceShortcut();

  /// Select the next ayah in study mode.
  static const quranAyahNext = QuranAyahNextShortcut();

  /// Select the previous ayah in study mode.
  static const quranAyahPrev = QuranAyahPrevShortcut();

  /// Decrement the fortress thikr repeat counter.
  static const fortressCount = FortressCountShortcut();

  /// Go to the next thikr in fortress focus reading.
  static const fortressThikrNext = FortressThikrNextShortcut();

  /// Go to the previous thikr in fortress focus reading.
  static const fortressThikrPrev = FortressThikrPrevShortcut();

  /// Select the next hadith in the results list.
  static const hadithResultNext = HadithResultNextShortcut();

  /// Select the previous hadith in the results list.
  static const hadithResultPrev = HadithResultPrevShortcut();

  /// Every shortcut in the application.
  static const List<AppShortcut> all = [
    toggleTheme,
    toggleLocale,
    openSettings,
    focusSearch,
    quranPageNext,
    quranPagePrev,
    quranPageNextSpace,
    quranAyahNext,
    quranAyahPrev,
    fortressCount,
    fortressThikrNext,
    fortressThikrPrev,
    hadithResultNext,
    hadithResultPrev,
  ];

  /// Settings grouping category.
  AppShortcutCategory get category;

  /// Keyboard activators (aliases included).
  List<SingleActivator> get activators;

  /// Whether this shortcut appears in the settings reference list.
  bool get visibleInSettings => true;

  /// When false, suppressed while a text field has focus.
  bool get allowWhenTextFieldFocused => false;

  /// Scope key used for duplicate-detection in tests.
  String get scopeKey;
}

/// Shortcuts active for the entire application shell.
sealed class GlobalAppShortcut extends AppShortcut {
  const GlobalAppShortcut();

  @override
  String get scopeKey => 'global';

  /// Invoked by shell shortcut scope via dynamic dispatch.
  void invokeGlobal(AppShortcutInvocation invocation);
}

/// Shortcuts active on a typed navigation route.
sealed class RouteAppShortcut extends AppShortcut {
  /// Creates a route-scoped shortcut.
  const RouteAppShortcut(this.route);

  /// Typed route this shortcut belongs to.
  final AppNavigationRoute route;

  @override
  String get scopeKey => 'route:${route.path}';
}

/// Shortcuts active only in a feature sub-mode.
sealed class ContextualAppShortcut extends AppShortcut {
  /// Creates a contextual shortcut.
  const ContextualAppShortcut(this.contextTag);

  /// Human-readable sub-mode tag.
  final String contextTag;

  @override
  String get scopeKey => 'contextual:$contextTag';
}

/// Toggle theme: Ctrl/Cmd+Shift+D.
final class ToggleThemeShortcut extends GlobalAppShortcut {
  /// Creates the toggle-theme shortcut.
  const ToggleThemeShortcut();

  @override
  AppShortcutCategory get category => AppShortcutCategory.global;

  @override
  List<SingleActivator> get activators =>
      desktopModShortcut(LogicalKeyboardKey.keyD, shift: true);

  @override
  bool get allowWhenTextFieldFocused => true;

  @override
  void invokeGlobal(AppShortcutInvocation invocation) {
    invocation.ref.read(themeProvider.notifier).toggleThemeMode();
  }
}

/// Toggle locale: Ctrl/Cmd+Shift+L.
final class ToggleLocaleShortcut extends GlobalAppShortcut {
  /// Creates the toggle-locale shortcut.
  const ToggleLocaleShortcut();

  @override
  AppShortcutCategory get category => AppShortcutCategory.global;

  @override
  List<SingleActivator> get activators =>
      desktopModShortcut(LogicalKeyboardKey.keyL, shift: true);

  @override
  bool get allowWhenTextFieldFocused => true;

  @override
  void invokeGlobal(AppShortcutInvocation invocation) {
    invocation.ref.read(localeProvider.notifier).toggleLocale();
  }
}

/// Open settings: Ctrl/Cmd+,.
final class OpenSettingsShortcut extends GlobalAppShortcut {
  /// Creates the open-settings shortcut.
  const OpenSettingsShortcut();

  @override
  AppShortcutCategory get category => AppShortcutCategory.global;

  @override
  List<SingleActivator> get activators =>
      desktopModShortcut(LogicalKeyboardKey.comma);

  @override
  bool get allowWhenTextFieldFocused => true;

  @override
  void invokeGlobal(AppShortcutInvocation invocation) {
    if (!invocation.context.mounted) {
      return;
    }
    const SettingsRoute().go(invocation.context);
  }
}

/// Focus search: Ctrl/Cmd+K.
final class FocusSearchShortcut extends GlobalAppShortcut {
  /// Creates the focus-search shortcut.
  const FocusSearchShortcut();

  @override
  AppShortcutCategory get category => AppShortcutCategory.global;

  @override
  List<SingleActivator> get activators =>
      desktopModShortcut(LogicalKeyboardKey.keyK);

  @override
  bool get allowWhenTextFieldFocused => true;

  @override
  void invokeGlobal(AppShortcutInvocation invocation) {
    if (AppSearchFocusRegistry.instance.focus()) {
      return;
    }

    if (!invocation.context.mounted) {
      return;
    }

    showFToast(
      context: invocation.context,
      title: Text(invocation.context.l10n.shortcutFocusSearchUnavailable),
    );
  }
}

/// Next mushaf page (RTL): Left arrow.
final class QuranPageNextShortcut extends RouteAppShortcut {
  /// Creates the next-page shortcut.
  const QuranPageNextShortcut() : super(_route);

  static const _route = QuranRoute();

  @override
  AppShortcutCategory get category => AppShortcutCategory.quran;

  @override
  List<SingleActivator> get activators => [
        plainShortcut(LogicalKeyboardKey.arrowLeft),
      ];
}

/// Previous mushaf page: Right arrow.
final class QuranPagePrevShortcut extends RouteAppShortcut {
  /// Creates the previous-page shortcut.
  const QuranPagePrevShortcut() : super(_route);

  static const _route = QuranRoute();

  @override
  AppShortcutCategory get category => AppShortcutCategory.quran;

  @override
  List<SingleActivator> get activators => [
        plainShortcut(LogicalKeyboardKey.arrowRight),
      ];
}

/// Next mushaf page: Space.
final class QuranPageNextSpaceShortcut extends RouteAppShortcut {
  /// Creates the space-to-next-page shortcut.
  const QuranPageNextSpaceShortcut() : super(_route);

  static const _route = QuranRoute();

  @override
  AppShortcutCategory get category => AppShortcutCategory.quran;

  @override
  List<SingleActivator> get activators => [
        plainShortcut(LogicalKeyboardKey.space),
      ];
}

/// Next ayah in study panel.
final class QuranAyahNextShortcut extends ContextualAppShortcut {
  /// Creates the next-ayah shortcut.
  const QuranAyahNextShortcut() : super('quran.studyPanel');

  @override
  AppShortcutCategory get category => AppShortcutCategory.quran;

  @override
  List<SingleActivator> get activators => [
        plainShortcut(LogicalKeyboardKey.arrowLeft),
        plainShortcut(LogicalKeyboardKey.arrowDown),
      ];
}

/// Previous ayah in study panel.
final class QuranAyahPrevShortcut extends ContextualAppShortcut {
  /// Creates the previous-ayah shortcut.
  const QuranAyahPrevShortcut() : super('quran.studyPanel');

  @override
  AppShortcutCategory get category => AppShortcutCategory.quran;

  @override
  List<SingleActivator> get activators => [
        plainShortcut(LogicalKeyboardKey.arrowRight),
        plainShortcut(LogicalKeyboardKey.arrowUp),
      ];
}

/// Fortress count decrement.
final class FortressCountShortcut extends ContextualAppShortcut {
  /// Creates the fortress count shortcut.
  const FortressCountShortcut() : super('fortress.focusReading');

  @override
  AppShortcutCategory get category => AppShortcutCategory.fortress;

  @override
  List<SingleActivator> get activators => [
        plainShortcut(LogicalKeyboardKey.space),
        plainShortcut(LogicalKeyboardKey.enter),
      ];
}

/// Next thikr in fortress focus reading.
final class FortressThikrNextShortcut extends ContextualAppShortcut {
  /// Creates the next-thikr shortcut.
  const FortressThikrNextShortcut() : super('fortress.focusReading');

  @override
  AppShortcutCategory get category => AppShortcutCategory.fortress;

  @override
  List<SingleActivator> get activators => [
        plainShortcut(LogicalKeyboardKey.arrowLeft),
        plainShortcut(LogicalKeyboardKey.arrowDown),
      ];
}

/// Previous thikr in fortress focus reading.
final class FortressThikrPrevShortcut extends ContextualAppShortcut {
  /// Creates the previous-thikr shortcut.
  const FortressThikrPrevShortcut() : super('fortress.focusReading');

  @override
  AppShortcutCategory get category => AppShortcutCategory.fortress;

  @override
  List<SingleActivator> get activators => [
        plainShortcut(LogicalKeyboardKey.arrowRight),
        plainShortcut(LogicalKeyboardKey.arrowUp),
      ];
}

/// Next hadith in the results list.
final class HadithResultNextShortcut extends RouteAppShortcut {
  /// Creates the next-result shortcut.
  const HadithResultNextShortcut() : super(_route);

  static const _route = HadithRoute();

  @override
  AppShortcutCategory get category => AppShortcutCategory.hadith;

  @override
  List<SingleActivator> get activators => [
        plainShortcut(LogicalKeyboardKey.arrowLeft),
        plainShortcut(LogicalKeyboardKey.arrowDown),
      ];
}

/// Previous hadith in the results list.
final class HadithResultPrevShortcut extends RouteAppShortcut {
  /// Creates the previous-result shortcut.
  const HadithResultPrevShortcut() : super(_route);

  static const _route = HadithRoute();

  @override
  AppShortcutCategory get category => AppShortcutCategory.hadith;

  @override
  List<SingleActivator> get activators => [
        plainShortcut(LogicalKeyboardKey.arrowRight),
        plainShortcut(LogicalKeyboardKey.arrowUp),
      ];
}

/// Shortcuts visible in the settings reference list.
Iterable<AppShortcut> get visibleAppShortcuts =>
    AppShortcut.all.where((shortcut) => shortcut.visibleInSettings);

/// Shortcuts grouped by category for the settings UI.
Map<AppShortcutCategory, List<AppShortcut>> appShortcutsByCategory() {
  final grouped = <AppShortcutCategory, List<AppShortcut>>{};
  for (final shortcut in visibleAppShortcuts) {
    grouped.putIfAbsent(shortcut.category, () => []).add(shortcut);
  }
  return grouped;
}

/// Returns duplicate activator keys within the same scope (for tests/debug).
Map<String, List<AppShortcut>> findDuplicateActivators() {
  final duplicates = <String, List<AppShortcut>>{};

  final byScope = <String, List<AppShortcut>>{};
  for (final shortcut in AppShortcut.all) {
    byScope.putIfAbsent(shortcut.scopeKey, () => []).add(shortcut);
  }

  for (final entry in byScope.entries) {
    final seen = <String, AppShortcut>{};
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
