import 'package:tawaq/core/shortcuts/app_shortcut.dart';
import 'package:tawaq/l10n/app_localizations.dart';

/// Localized labels and descriptions for [AppShortcut] entries.
extension AppShortcutL10n on AppShortcut {
  /// Localized action label.
  String label(AppLocalizations l10n) => switch (this) {
        ToggleThemeShortcut() => l10n.shortcutToggleThemeLabel,
        ToggleLocaleShortcut() => l10n.shortcutToggleLocaleLabel,
        OpenSettingsShortcut() => l10n.shortcutOpenSettingsLabel,
        FocusSearchShortcut() => l10n.shortcutFocusSearchLabel,
        QuranPageNextShortcut() => l10n.shortcutQuranPageNextLabel,
        QuranPagePrevShortcut() => l10n.shortcutQuranPagePrevLabel,
        QuranPageNextSpaceShortcut() => l10n.shortcutQuranPageNextSpaceLabel,
        QuranAyahNextShortcut() => l10n.shortcutQuranAyahNextLabel,
        QuranAyahPrevShortcut() => l10n.shortcutQuranAyahPrevLabel,
        FortressCountShortcut() => l10n.shortcutFortressCountLabel,
        FortressThikrNextShortcut() => l10n.shortcutFortressThikrNextLabel,
        FortressThikrPrevShortcut() => l10n.shortcutFortressThikrPrevLabel,
        HadithResultNextShortcut() => l10n.shortcutHadithResultNextLabel,
        HadithResultPrevShortcut() => l10n.shortcutHadithResultPrevLabel,
      };

  /// Localized description shown in the settings reference list.
  String description(AppLocalizations l10n) => switch (this) {
        ToggleThemeShortcut() => l10n.shortcutToggleThemeDescription,
        ToggleLocaleShortcut() => l10n.shortcutToggleLocaleDescription,
        OpenSettingsShortcut() => l10n.shortcutOpenSettingsDescription,
        FocusSearchShortcut() => l10n.shortcutFocusSearchDescription,
        QuranPageNextShortcut() => l10n.shortcutQuranPageNextDescription,
        QuranPagePrevShortcut() => l10n.shortcutQuranPagePrevDescription,
        QuranPageNextSpaceShortcut() =>
          l10n.shortcutQuranPageNextSpaceDescription,
        QuranAyahNextShortcut() => l10n.shortcutQuranAyahNextDescription,
        QuranAyahPrevShortcut() => l10n.shortcutQuranAyahPrevDescription,
        FortressCountShortcut() => l10n.shortcutFortressCountDescription,
        FortressThikrNextShortcut() =>
          l10n.shortcutFortressThikrNextDescription,
        FortressThikrPrevShortcut() =>
          l10n.shortcutFortressThikrPrevDescription,
        HadithResultNextShortcut() =>
          l10n.shortcutHadithResultNextDescription,
        HadithResultPrevShortcut() =>
          l10n.shortcutHadithResultPrevDescription,
      };
}

/// Localized category titles for the settings reference list.
extension AppShortcutCategoryL10n on AppShortcutCategory {
  /// Localized category title.
  String title(AppLocalizations l10n) => switch (this) {
        AppShortcutCategory.global => l10n.shortcutCategoryGlobal,
        AppShortcutCategory.quran => l10n.shortcutCategoryQuran,
        AppShortcutCategory.fortress => l10n.shortcutCategoryFortress,
        AppShortcutCategory.hadith => l10n.shortcutCategoryHadith,
      };
}
