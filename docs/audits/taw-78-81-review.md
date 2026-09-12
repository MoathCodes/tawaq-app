# TAW-78 / TAW-81 / Quran TAW-82 review

## Contract proof

- Study Read mode now puts loaded tafsir/translation prose before the source
  selector. Selectors remain reachable in loading, empty, and error states and
  use a restrained separator. The translation selector keeps its localized
  `Translation` semantics name while removing the duplicate visible label.
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
  The action controls wrap at narrow widths and expose Play, Share, Copy, and
  Dismiss names in the semantics tree.
- Quran informational metadata uses plain text for the reflections count and
  ayah identity instead of filled badges. Interactive controls keep their
  button treatment.

## Visual evidence

- [Before reference](taw-78-81-screenshots/quran-study-before.png) is a
  portable rendering of the committed Quran study/read surface.
- [After widget render](taw-78-81-screenshots/quran-study-after-widget.png)
  captures the updated upright prose/action treatment at a 320px content
  width. This is Flutter widget-render evidence, not a native-window capture.

The Linux app built successfully with `fvm flutter run -d linux --debug`, but a
second running Tawaq process held the shared Mushaf Hive lock at
`/home/moath/Documents/tawaq/surahs.lock`. The native window therefore could
not initialize its reader content; no native runtime claim is made here.

## Validation

| Command | Result |
| --- | --- |
| `fvm exec bash tool/codegen.sh` | Passed; generated files are ignored by the repository as configured. |
| `fvm flutter gen-l10n` | Passed; tracked localization outputs updated. |
| `fvm flutter test test/feature/quran` | Passed: 472 tests. |
| `fvm flutter test` | Passed: 1,002 tests. |
| `fvm flutter analyze --no-fatal-infos` | Passed with the repository's existing infos only; no errors. |
| Impeccable type/layout detectors | Returned no findings for the affected Quran files. |

The known baseline docs/audits/taw-67-memory-2026-09-08/probe.dart dynamic-to-
Map errors were not touched.
