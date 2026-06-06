import 'package:tawaq/core/shortcuts/app_shortcut.dart';
import 'package:tawaq/core/shortcuts/app_shortcut_id.dart';
import 'package:tawaq/l10n/app_localizations.dart';

/// Localized labels and descriptions for [AppShortcutDefinition] entries.
extension AppShortcutL10n on AppShortcutDefinition {
  /// Localized action label.
  String label(AppLocalizations l10n) => switch (id) {
        AppShortcutId.toggleTheme => l10n.shortcutToggleThemeLabel,
        AppShortcutId.toggleLocale => l10n.shortcutToggleLocaleLabel,
        AppShortcutId.openSettings => l10n.shortcutOpenSettingsLabel,
        AppShortcutId.focusSearch => l10n.shortcutFocusSearchLabel,
        AppShortcutId.quranPageNext => l10n.shortcutQuranPageNextLabel,
        AppShortcutId.quranPagePrev => l10n.shortcutQuranPagePrevLabel,
        AppShortcutId.quranPageNextSpace =>
          l10n.shortcutQuranPageNextSpaceLabel,
        AppShortcutId.quranAyahNext => l10n.shortcutQuranAyahNextLabel,
        AppShortcutId.quranAyahPrev => l10n.shortcutQuranAyahPrevLabel,
        AppShortcutId.fortressCount => l10n.shortcutFortressCountLabel,
        AppShortcutId.fortressThikrNext => l10n.shortcutFortressThikrNextLabel,
        AppShortcutId.fortressThikrPrev => l10n.shortcutFortressThikrPrevLabel,
      };

  /// Localized description shown in the settings reference list.
  String description(AppLocalizations l10n) => switch (id) {
        AppShortcutId.toggleTheme => l10n.shortcutToggleThemeDescription,
        AppShortcutId.toggleLocale => l10n.shortcutToggleLocaleDescription,
        AppShortcutId.openSettings => l10n.shortcutOpenSettingsDescription,
        AppShortcutId.focusSearch => l10n.shortcutFocusSearchDescription,
        AppShortcutId.quranPageNext => l10n.shortcutQuranPageNextDescription,
        AppShortcutId.quranPagePrev => l10n.shortcutQuranPagePrevDescription,
        AppShortcutId.quranPageNextSpace =>
          l10n.shortcutQuranPageNextSpaceDescription,
        AppShortcutId.quranAyahNext => l10n.shortcutQuranAyahNextDescription,
        AppShortcutId.quranAyahPrev => l10n.shortcutQuranAyahPrevDescription,
        AppShortcutId.fortressCount => l10n.shortcutFortressCountDescription,
        AppShortcutId.fortressThikrNext =>
          l10n.shortcutFortressThikrNextDescription,
        AppShortcutId.fortressThikrPrev =>
          l10n.shortcutFortressThikrPrevDescription,
      };
}

/// Localized category titles for the settings reference list.
extension AppShortcutCategoryL10n on AppShortcutCategory {
  /// Localized category title.
  String title(AppLocalizations l10n) => switch (this) {
        AppShortcutCategory.global => l10n.shortcutCategoryGlobal,
        AppShortcutCategory.quran => l10n.shortcutCategoryQuran,
        AppShortcutCategory.fortress => l10n.shortcutCategoryFortress,
      };
}
