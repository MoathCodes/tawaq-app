# TAW-78 / TAW-81 / Quran TAW-82 review

## Contract proof

- Study Read mode keeps the compact source selector directly under the section
  heading and immediately above the loaded tafsir/translation prose. This
  keeps a long passage readable while the edition remains reachable without
  scrolling to its end. Selectors remain present in loading, empty, and error
  states and use a restrained separator. The translation selector keeps its
  localized `Translation` semantics name while removing the duplicate visible
  label.
- Tafsir uses an explicit RTL content direction. Translation direction is owned
  by `TranslationId` metadata (`languageCode` plus `TranslationDirection`) for
  every bundled edition: English, Bengali, Spanish, French, Indonesian,
  Russian, Swedish, Turkish, Urdu, and Chinese. Prose uses `TextAlign.start`
  inside an explicit `Directionality` and renders the exact model string.
- Study prose no longer falls below the existing scaled `body.md` tier in a
  narrow pane and uses `body.lg` at comfortable widths. Latin prose is upright
  with 1.6 leading; Urdu keeps its 2.0 leading and source font; tafsir keeps
  UthmanTN with 1.8 leading.
- Selected-ayah actions are in one flow-attached group below the reader, so
  they do not cover Quran lines or page metadata. Play remains the only primary
  action; Share and Copy are outline secondary actions; dismiss is a ghost
  action with a localized tooltip/semantic name. Existing popover choices,
  share/copy flows, keyboard shortcuts, and selection dismissal are retained.
  The action controls measure the actual reader toolbar width: wide readers
  show text labels and the Play chevron, while narrow readers wrap compact
  controls. Each named action forwards its callback into the semantic wrapper
  while the underlying Forui button remains the only keyboard focus stop.
  Semantic activation tests invoke Play, Copy, and Dismiss through
  `SemanticsAction.tap`; keyboard tests traverse with Tab and activate Play
  with Enter and Copy with Space, verifying the existing effects.
- Quran informational metadata uses plain text for the reflections count and
  ayah identity instead of filled badges. Interactive controls keep their
  button treatment.

## Visual evidence

- [Before reference](taw-78-81-screenshots/quran-study-before.png) is a
  portable rendering of the committed Quran study/read surface.
- [After light render](taw-78-81-screenshots/quran-study-after-light.png) and
  [after dark render](taw-78-81-screenshots/quran-study-after-dark.png) are
  native Linux Flutter widget captures using the shipped Manuscript theme,
  font assets, and Forui icon glyphs. The left column is the actual
  `StudyContentSection`/`TranslationProse` composition at a 350px narrow-pane
  width; the right column is the actual `QuranMushafPane` with a bundled Hive
  Mushaf page and the selected-ayah action group. The compact wide toolbar
  shows Play + chevron, Share, Copy, and dismiss on one row. The language rows
  below the study prose are explicitly labeled font specimens, not a second
  reader. The [after widget filename](taw-78-81-screenshots/quran-study-after-widget.png)
  remains a light-capture compatibility link.
- The committed capture harness is
  [`tool/quran_visual_harness.dart`](../../tool/quran_visual_harness.dart). It
  uses a dedicated `tawaq-quran-review-harness` app-data subdirectory, so it
  reads the shipped Mushaf Hive fixture without contending with a running
  Tawaq instance. Run it with `TAWAQ_SCREENSHOT=/tmp/quran-study-light.png
  fvm flutter run -d linux -t tool/quran_visual_harness.dart
  --dart-define=DARK=false` (set `DARK=true` for dark mode). The translation and
  labeled language specimens use the exact first-row strings from the shipped
  `saheeh_international`, `quran_ur`, `quran_bn`, and `quran_zh` databases.
  These PNGs are portable native evidence, not fabricated test snapshots.

The main Linux app also built successfully with `fvm flutter run -d linux
--debug`, but a separate running Tawaq process held the shared Mushaf Hive
lock at `/home/moath/Documents/tawaq/surahs.lock`; no user process was
terminated. The main app therefore could not initialize its reader content.
The screenshots above are the authorized native widget-harness fallback, not
claims about the locked main-app runtime.

## Validation

| Command | Result |
| --- | --- |
| `fvm exec bash tool/codegen.sh` | Passed; generated files are ignored by the repository as configured. |
| `fvm flutter gen-l10n` | Passed; tracked localization outputs updated. |
| `fvm flutter test test/feature/quran` | Passed: 481 tests. |
| `fvm flutter test` | Passed: 1,010 tests. |
| `fvm flutter analyze --no-fatal-infos` | Passed with no errors; 169 repository lint infos remain (including existing baseline infos and non-blocking preview/test style infos). |
| Impeccable type/layout detectors | Returned no findings for the affected Quran files. |

The known baseline docs/audits/taw-67-memory-2026-09-08/probe.dart dynamic-to-
Map errors were not touched.
