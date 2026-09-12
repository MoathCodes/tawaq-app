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
  controls. Each named action now forwards its callback into the semantic
  wrapper and retains a focusable node. Semantic activation tests invoke Play,
  Copy, and Dismiss through `SemanticsAction.tap` and verify the existing
  effects.
- Quran informational metadata uses plain text for the reflections count and
  ayah identity instead of filled badges. Interactive controls keep their
  button treatment.

## Visual evidence

- [Before reference](taw-78-81-screenshots/quran-study-before.png) is a
  portable rendering of the committed Quran study/read surface.
- [After light render](taw-78-81-screenshots/quran-study-after-light.png) and
  [after dark render](taw-78-81-screenshots/quran-study-after-dark.png) are
  native Linux Flutter widget captures using the shipped Manuscript theme,
  font assets, and Forui icon glyphs. They show a 360px study column (the
  narrow-pane target), English and Arabic reader content, the wide action
  group, and bundled Urdu, Bengali, and Chinese font samples. The historical
  [after widget filename](taw-78-81-screenshots/quran-study-after-widget.png)
  is kept as the light capture for existing review links.
- The capture harness used the exact first-row strings from the shipped
  `saheeh_international`, `quran_ur`, `quran_bn`, and `quran_zh` databases and
  the existing Al-Fatihah fixture. It was a temporary native Linux entrypoint
  removed after capture; the PNGs are portable evidence, not fabricated test
  snapshots.

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
| `fvm flutter test test/feature/quran` | Passed: 479 tests. |
| `fvm flutter test` | Passed: 1,008 tests. |
| `fvm flutter analyze --no-fatal-infos` | Passed with no errors; 164 repository lint infos remain (including existing baseline infos and non-blocking new-test style infos). |
| Impeccable type/layout detectors | Returned no findings for the affected Quran files. |

The known baseline docs/audits/taw-67-memory-2026-09-08/probe.dart dynamic-to-
Map errors were not touched.
