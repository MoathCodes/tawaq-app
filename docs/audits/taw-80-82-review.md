# TAW-80 / TAW-82 review evidence

This branch covers the Hadith scan-and-select surface in TAW-80 and the
global title-bar recitation transport presentation in TAW-82. It does not
claim the Fortress or Quran badge portions owned by the other TAW-82 changes,
and it does not close TAW-69.

## Contract evidence

- Result cards receive an honest page-local ordinal from the rendered result
  list. The card and detail pane use the same `DetailedHadith` stable key for
  selection, and the detail header repeats the localized selected-result
  identity and source citation.
- Selection is expressed through a primary border, a leading marker, a subtle
  selected surface, and `Semantics(selected: true)`, so color is not the only
  signal. Favorites remain a separate action.
- The excerpt remains scan-sized, while the detail pane repeats the complete
  hadith for reading. Judgment text is a separate, neutral, wrapping block;
  narrator, scholar, and source metadata wrap without an ellipsis.
- Detail scroll resets only when the stable hadith identity changes. The side
  panel derives the ordinal from the visible collection, so a page/filter
  refresh cannot relabel an unrelated selection.
- The title-bar play control uses the hydrated recitation session projection
  already used by the player. Its visible tooltip and accessibility name carry
  the localized Play/Pause action plus available surah/reciter context; it
  reports loading and missing-selection guidance without hover-time provider
  work or fallback catalog selection.

## Checks

- `fvm exec bash tool/codegen.sh`
- `fvm flutter gen-l10n`
- `fvm flutter test test/feature/hadith/hadith_result_card_test.dart test/feature/hadith/hadith_search_controller_test.dart test/feature/hadith/hadith_split_layout_test.dart test/feature/quran/recitation_initialization_test.dart`
- `fvm flutter test` (999 tests passed)
- `fvm flutter analyze --no-fatal-infos` (exit 0; existing informational
  diagnostics remain, including the repository's known baseline audit noise)
- Impeccable layout detector: no findings for the touched Hadith and transport
  surfaces.

The focused widget tests provide render and semantics evidence for Arabic/RTL
and English/LTR card content, long neutral judgments, selected identity, and
transport ready/loading/missing states. A native Linux screenshot pass was not
captured in this container; no performance claim is made.

## Remaining TAW-82 contribution

This branch contributes only the global shell/recitation presentation and
Hadith work. Fortress search/badges and Quran badges remain owned by their
respective branches; TAW-82 should stay open until those contributions are
integrated.
