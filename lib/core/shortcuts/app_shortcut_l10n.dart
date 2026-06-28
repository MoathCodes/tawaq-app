import 'package:tawaq/core/shortcuts/app_shortcut.dart';
import 'package:tawaq/l10n/app_localizations.dart';

/// Localized labels and descriptions for [ShortcutDef] entries.
extension ShortcutDefL10n on ShortcutDef {
  /// Localized action label.
  String label(AppLocalizations l10n) => switch (id) {
        'toggleTheme' => l10n.shortcutToggleThemeLabel,
        'toggleLocale' => l10n.shortcutToggleLocaleLabel,
        'openSettings' => l10n.shortcutOpenSettingsLabel,
        'focusSearch' => l10n.shortcutFocusSearchLabel,
        'quranPageNext' => l10n.shortcutQuranPageNextLabel,
        'quranPagePrev' => l10n.shortcutQuranPagePrevLabel,
        'quranPageNextSpace' => l10n.shortcutQuranPageNextSpaceLabel,
        'quranAyahNext' => l10n.shortcutQuranAyahNextLabel,
        'quranAyahPrev' => l10n.shortcutQuranAyahPrevLabel,
        'fortressCount' => l10n.shortcutFortressCountLabel,
        'fortressThikrNext' => l10n.shortcutFortressThikrNextLabel,
        'fortressThikrPrev' => l10n.shortcutFortressThikrPrevLabel,
        'hadithResultNext' => l10n.shortcutHadithResultNextLabel,
        'hadithResultPrev' => l10n.shortcutHadithResultPrevLabel,
        _ => id,
      };

  /// Localized description shown in the settings reference list.
  String description(AppLocalizations l10n) => switch (id) {
        'toggleTheme' => l10n.shortcutToggleThemeDescription,
        'toggleLocale' => l10n.shortcutToggleLocaleDescription,
        'openSettings' => l10n.shortcutOpenSettingsDescription,
        'focusSearch' => l10n.shortcutFocusSearchDescription,
        'quranPageNext' => l10n.shortcutQuranPageNextDescription,
        'quranPagePrev' => l10n.shortcutQuranPagePrevDescription,
        'quranPageNextSpace' => l10n.shortcutQuranPageNextSpaceDescription,
        'quranAyahNext' => l10n.shortcutQuranAyahNextDescription,
        'quranAyahPrev' => l10n.shortcutQuranAyahPrevDescription,
        'fortressCount' => l10n.shortcutFortressCountDescription,
        'fortressThikrNext' => l10n.shortcutFortressThikrNextDescription,
        'fortressThikrPrev' => l10n.shortcutFortressThikrPrevDescription,
        'hadithResultNext' => l10n.shortcutHadithResultNextDescription,
        'hadithResultPrev' => l10n.shortcutHadithResultPrevDescription,
        _ => id,
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
