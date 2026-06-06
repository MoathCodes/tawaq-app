/// Stable identifiers for every application keyboard shortcut.
enum AppShortcutId {
  /// Toggle light/dark theme.
  toggleTheme,

  /// Toggle English/Arabic locale.
  toggleLocale,

  /// Open the settings screen.
  openSettings,

  /// Focus the contextual search field (route-dependent).
  focusSearch,

  /// Advance to the next mushaf page (RTL reading direction).
  quranPageNext,

  /// Go to the previous mushaf page.
  quranPagePrev,

  /// Advance to the next mushaf page via Space.
  quranPageNextSpace,

  /// Select the next ayah in study mode.
  quranAyahNext,

  /// Select the previous ayah in study mode.
  quranAyahPrev,

  /// Decrement the fortress thikr repeat counter.
  fortressCount,

  /// Go to the next thikr in fortress focus reading.
  fortressThikrNext,

  /// Go to the previous thikr in fortress focus reading.
  fortressThikrPrev,
}
