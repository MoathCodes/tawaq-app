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
  reports loading, initialization failure, missing reciter/moshaf/surah, and
  range-timing guidance from the exact hydrated fields without hover-time
  provider work or fallback catalog selection. Ended playback says Replay.
- The card's right-click context menu remains available, while a labeled
  keyboard-reachable More actions button exposes the same open/copy/bookmark
  actions. The selected-row semantics retain their descendant controls.

## Checks

- `fvm exec bash tool/codegen.sh`
- `fvm flutter gen-l10n`
- `fvm flutter test test/feature/hadith/hadith_result_card_test.dart test/feature/hadith/hadith_detail_selection_test.dart test/feature/hadith/hadith_search_controller_test.dart test/feature/hadith/hadith_split_layout_test.dart test/feature/quran/recitation_initialization_test.dart`
- `fvm flutter test` (1003 tests passed)
- `fvm flutter analyze --no-fatal-infos` (exit 0; existing informational
  diagnostics remain, including the repository's known baseline audit noise)
- Impeccable layout detector: no findings for the touched Hadith and transport
  surfaces.

The focused widget tests provide render and semantics evidence for Arabic/RTL
and English/LTR card content, long neutral judgments, selected identity,
same-result scroll preservation, different-result scroll reset, independent
favorite/selection keyboard actions, More actions availability, and transport
ready/playing/ended/loading/error/missing states. The transport focus test
opens the tooltip through keyboard focus and activates Play with Enter.

## Runtime artifacts

These are cropped from the isolated preview target
[`tool/taw_80_preview.dart`](../../tool/taw_80_preview.dart) running as a
native Linux Flutter profile app. They use shipped fonts/icons and synthetic,
non-private fixture inputs; the Arabic source phrase and its Bukhari citation
are shown exactly, while the long judgment is explicitly synthetic. The
English capture is Manuscript light at normal text size. The Arabic capture is
Manuscript dark at 1.3 text scale with a narrow detail pane. The tooltip
captures show the localized global playback name with surah and reciter
context.

- [Hadith English / Manuscript light](artifacts/hadith-en-manuscript-light.png)
- [Hadith Arabic / Manuscript dark / text 1.3](artifacts/hadith-ar-manuscript-dark-text-1_3.png)
- [Global playback English tooltip](artifacts/global-playback-en-tooltip.png)
- [Global playback Arabic tooltip](artifacts/global-playback-ar-tooltip.png)

Runtime capture is evidence of the updated composition only; no performance
claim is made. The GUI accessibility bridge was not used for the crop because
the environment could not reliably discover the preview window, so the
artifacts are labeled native runtime captures rather than accessibility-tree
captures.

## Remaining TAW-82 contribution

This branch contributes only the global shell/recitation presentation and
Hadith work. Fortress search/badges and Quran badges remain owned by their
respective branches; TAW-82 should stay open until those contributions are
integrated.
