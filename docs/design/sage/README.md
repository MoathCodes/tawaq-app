# Sage palette

Sage is a selectable palette inspired by the approved Turning ت icon. Light
mode pairs warm parchment with deep green actions and quiet sage surfaces.
Dark mode uses green charcoal, elevated olive planes and readable sage actions.
Manuscript remains the default. Neutral and Omarchy retain their existing colors,
wire values and behavior. No persisted schema or religious content changes.

## Color authority and roles

The [authoritative SVG](../../../tooling/icons/artwork/folio_ribbon.svg),
[approved icon](../../../tooling/icons/source/app_icon.png) and
[refinement comparison](../icons/turning-refined-comparison.png) supply the
parchment and green family. The SVG's #F7F4ED parchment, #FFFDF7 paper,
#37583C fold and #B9C78D leaf highlight anchor the theme. Supporting shades
are adjusted for UI contrast. Pale icon highlights are not light-theme text.

| Role | Light | Dark |
| --- | --- | --- |
| Canvas | #F7F4ED | #171F19 |
| Card / elevated plane | #FFFDF7 | #212C23 |
| Primary action / focus | #37583C | #B9C78D |
| Text on primary | #FFFDF7 | #1C2B20 |
| Main text | #24382B | #F0EADF |
| Secondary surface | #E4E8DA | #303B2C |
| Secondary text | #2E4533 | #E6EAD9 |
| Muted surface | #EEEDE3 | #293329 |
| Supporting text | #52604C | #B6BDAA |
| Decorative border / separator | #BEC5B2 | #475442 |
| Error / destructive | #A33332 | #FFA49A |
| Text on error / destructive | #FFFDF7 | #351C18 |

Depth comes from surface tones and the app's existing subtle elevations.
Spacing, fonts, layout rules and content are retained. Focus uses the primary
role; text selection uses a primary tint with normal foreground text.

## Ownership and affected consumers

- `lib/theme/custom_themes.dart` owns Sage's semantic Forui roles in both
  brightness modes and desktop/touch densities.
- `lib/theme/theme_model.dart` adds Sage to resolution, JSON decoding and the
  localized enum selector. Persistence continues to store `sage` as a string;
  current/legacy palette names and fallback behavior remain compatible.
- `lib/theme/app_theme_builder.dart` keeps shared typography, focus and tab
  styles. Its Sage Material adapter supplies tonal containers, outlines,
  inverse roles, text selection and caret colors rather than leaving them at
  Material defaults. Other palettes keep their original Material conversion.
- `lib/main.dart` uses that adapter for bootstrap, error and routed app shells.
- The settings palette selector wraps into two columns at narrow widths.
  Its existing hydration gate and mode controls remain intact. The shared
  title-bar mode button still hides only for Omarchy.
- Prayer, Quran, Hadith, Fortress, shared cards/tabs/controls and desktop alert
  surfaces consume the resolved theme. Their owning providers and behavior
  are unchanged. Baked Mushaf ornament artwork remains intentionally unchanged.
- English and Arabic ARBs name Sage and use a palette-neutral settings hint.
  `fvm flutter gen-l10n` regenerated the three tracked localization outputs.

## Native visual evidence

Captures come from the real app routes running in a Linux debug build, using
[`tool/sage_visual_harness.dart`](../../../tool/sage_visual_harness.dart).
These are native Flutter render captures (`RepaintBoundary.toImage`), not web
mockups or OS window screenshots. The harness forces 1200×860 and 800×860 logical
viewports independently of compositor tiling. 800px is the shipped desktop
minimum width. It isolates Hive state, uses Riyadh prayer settings and bundled
reader data, and does not modify personal app preferences.

The matrix covers Prayer, Quran, Hadith, Fortress and Settings in both languages,
both modes and both widths: 40 Manuscript baseline captures and 40 Sage captures.
Settings is scrolled to show the selector. Wide sidebars are expanded; narrow
sidebars are collapsed. Prayer clocks naturally advance between captures.

| Context | Before / after comparison |
| --- | --- |
| English light, wide | [Comparison](comparison-en-light-1200.jpg) |
| English dark, wide | [Comparison](comparison-en-dark-1200.jpg) |
| English light, narrow | [Comparison](comparison-en-light-800.jpg) |
| English dark, narrow | [Comparison](comparison-en-dark-800.jpg) |
| Arabic light, wide | [Comparison](comparison-ar-light-1200.jpg) |
| Arabic dark, wide | [Comparison](comparison-ar-dark-1200.jpg) |
| Arabic light, narrow | [Comparison](comparison-ar-light-800.jpg) |
| Arabic dark, narrow | [Comparison](comparison-ar-dark-800.jpg) |

Full-size originals are in `captures/`, named
`<palette>-<locale>-<mode>-<width>-<route>.png`. The comparison sheets place
Manuscript on the left and Sage on the right, in the screen order above.

Reproduce with:

```bash
SAGE_REVIEW_DIR=/tmp/tawaq-sage-review fvm flutter run -d linux -t tool/sage_visual_harness.dart
SAGE_REVIEW_DIR=/tmp/tawaq-sage-review fvm flutter run -d linux -t tool/sage_visual_harness.dart --dart-define=RESTORE_ONLY=true
```

## Validation and limits

- The contrast suite checks both Sage modes in both densities through the actual
  app builder: normal/supporting/action text, tinted badges, tab selections,
  focused indicators, error/destructive controls, hovered primary controls,
  Material roles and selected text. Text checks require 4.5:1; focus checks 3:1.
  Decorative separators and disabled controls are not body-text contrast roles.
- Selector tests cover selection and all four options in a 360px Arabic viewport.
  Storage tests cover flush and provider restart, all palette wire values and
  the unchanged default/fallback.
- Full `fvm flutter analyze --no-fatal-infos` passes with existing informational
  diagnostics. Full `fvm flutter test` passes: 1,076 tests.
- The native harness flushes Sage dark to isolated disk storage. A second native
  process verifies that palette and mode restore.
- Visual coverage includes the Hadith empty/search-ready screen, Quran reading
  and disabled study fields, Fortress browse/recommendations, Prayer's schedule
  and empty analytics, and Settings controls. Remote Hadith result/detail states,
  playback, live adhan alerts, macOS/Windows, and screen-reader behavior were not
  visually exercised. Token contrast checks cover common badge/error/selection
  roles, but do not substitute for those runtime flows.
- Capture-only semantics exclusion avoids Flutter debug AT-SPI assertions also
  seen with Manuscript. Manual sidebar transitions exposed an existing transient
  3.6px button overflow with Manuscript; settled captures have no overflow marks.
  No sidebar or Material tab-bar behavior was changed by this palette task.

## Changed files

- `lib/theme/custom_themes.dart`
- `lib/theme/theme_model.dart`
- `lib/theme/app_theme_builder.dart`
- `lib/main.dart`
- `lib/feature/settings/presentation/widgets/theme/app_theme_selector.dart`
- `lib/l10n/app_en.arb` and `lib/l10n/app_ar.arb`
- Generated: `lib/l10n/app_localizations.dart`,
  `lib/l10n/app_localizations_en.dart`, `lib/l10n/app_localizations_ar.dart`
- `test/theme/manuscript_theme_contrast_test.dart`
- `test/feature/settings/app_theme_selector_test.dart`
- `test/feature/settings/settings_storage_gate_test.dart`
- `tool/sage_visual_harness.dart`
- This report, `validation.txt`, eight comparison sheets and 80 native captures
  under `docs/design/sage/`
