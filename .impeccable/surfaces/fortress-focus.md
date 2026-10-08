---
name: Tawaq Fortress focus
description: Native focus reader, persistent side details, and explicit chapter booklet sharing.
---

# Fortress focus surface

## Overview

This surface extends Tawaq's incumbent Manuscript/Sage world. An open reading stage carries the dhikr, chapter progress sits above it, and a circular repetition control anchors the counting dock. Available supporting fields open in a persistent side reading surface. Sharing follows the app's existing Forui dialog conventions.

This is a bounded surface record. `docs/design/fortress-focus-spec.md` records its finished interaction contract; production source owns implementation facts. The supplied HTML is a composition reference, never a religious source or an app-wide identity replacement.

## Colors

Colours inherit the active `FThemeData`. Manuscript supplies warm paper or charcoal with gold; Sage supplies parchment or green charcoal with green. Neutral and custom palettes use the same semantic roles.

- **Primary:** repetition ring, segment fill/current marker, selected detail accents, labelled virtue tint, and booklet headings.
- **Secondary:** tonal counter fill/hover and incumbent selected-control variants.
- **Neutral:** `background`/`foreground` carry the reading stage, side-sheet body, and booklet; `card` carries expanded browse cards; `border` separates tracks, panels, and page notes; `mutedForeground` carries item identity, source, virtue, target, chapter summary, and input hint.

**The Active Theme Rule.** This surface inherits colour roles rather than establishing parallel gold or green tokens.

## Typography

Interface copy inherits IBM Plex Sans Arabic. Focus prose uses bundled `UthmanTN`, regular weight, with line height (1.85). Measured layout selects desktop tiers (56, 40, 30 logical pixels) or compact tiers (40, 32, 26); measurement and stage content are cached across counting. User scaling remains effective; overflowing text scrolls.

Structured Quran keeps the existing Mushaf-backed renderer. Full pages use read-only `MushafPageRange.onPage`, preserving surah headers, basmalah, and verse glyphs without page-number chrome. Literal supplied Quran quotations in prose use `UthmanicHafs` on the quoted span; surrounding prose keeps `UthmanTN`. Display removes only ornamental quote brackets. Original strings and semantic quotation labels retain them; ayah numerals and font glyphs remain those supplied by the source.

Details reuse the commentary renderer at (18 logical pixels), source at (16), both with line height (1.8). Focus virtue is secondary interface text at (16), compact (14), with line height (1.6). Counter digits use tabular figures. Completion uses a centred title at (36), with muted chapter and factual progress underneath.

**The Source Boundary Rule.** Font and display transformations never rewrite religious source text or manufacture ayah markers.

## Layout

Focus contains a chapter header, independently scrolling stage, detail rail, supplied virtue when present, and stable counting dock. Stage measure is capped at (720 logical pixels), with horizontal padding (32) and vertical padding (24). Short text centres vertically; taller text begins at the top. Header progress takes its own row at header widths of (650 or less).

All focus and browse details use Forui `FSheets`/`showFPersistentSheet` at logical end: left in Arabic, right in English. Focus pane width is the greater of (420) and the measured full-word tab requirement. It docks only when the viewport is at least (720) and leaves at least (280) for reading; otherwise it uses a full-width side reading surface. An (800) wide window retains the reader beside the pane at normal and 1.3 interface scale in the reviewed English composition. The compact-controls threshold remains below (1,040), or scaled detail type above (27); it does not choose sheet topology. Expand/Restore changes the persistent-sheet controller's presentation. Browse width is the greater of (480) and the tab requirement, clamped to the viewport. Its host wraps the complete catalog and reading composition outside padding, so the pane reaches the surface's top, bottom, and logical-end edges. Details have no resizable-dock or bottom-sheet variant.

The primary circle stays (128) on desktop, (96) with compact controls, and (160) with enlarged type. All Previous/Next actions use icons with localized semantics and one RTL mirroring path.

Expanded browse cards use `FCard` and internal padding (24), full prose/Quran content, ordinal and repetition target, tinted labelled virtue, muted two-line source opening the source pane, individual available detail/share chips, and Collapse. A short body tap also collapses; selection drags, long presses, and nested source/detail/share controls retain their own actions. Collapsed preview metadata uses `none`, without an arbitrary benefit-only badge. Chips use minimum content width and align at logical start: right in Arabic, left in English. Repeated generic category icons are absent.

Chapter end centres a bounded (680) content column: a tonal check/book circle (88), title (36), muted chapter, progress summary (360), primary action (208), and outline/ghost secondary actions (176). It distinguishes completed targets from an unfinished end; Undo remains available.

## Elevation & Depth

The stage and side-sheet body use the flat background. Tonal counter fill, virtue tint, card surface, thin dividers, and the incumbent Forui share-dialog surface provide separation. Browse details add a theme Forui `FModalBarrier` spanning both catalog and reading with blur/dim and outside-dismiss. Focus adds a visual-only black `0x14` shade (about 8% opacity) behind the pane. Its `IgnorePointer` keeps the visible stage and counter usable; the shade neither blurs nor dismisses. No new ornamental shadow or glow vocabulary is established.

## Shapes

The circle belongs to repetition progress and chapter-end status. Chapter tracks are gently rounded and (4 logical pixels) high, with a distinct current marker. Expanded browse cards retain incumbent `theme.radii.lg` top corners and square bottom corners (0). Chips, buttons, tabs, sheets, and dialogs retain incumbent Forui geometry. The focus stage has no enclosing card.

## Components

- **Repetition control:** completed/target value, clockwise determinate ring, completion check, focus border, tonal hover, and pressed scale (0.97). Ring interpolation uses fast duration (150 ms); press uses instant (100 ms). Reduced motion disables movement. Short primary taps in the stage count even through selectable prose/ayah/Mushaf children; selection drags, scrolling, long presses, and other controls do not count. Undo is available from the counter context menu and registered command.
- **Chapter progress:** one read-only segment per canonical item, retained partial fill, complete fill, and current marker. Narrow views show a segment window with continuation markers. `TweenAnimationBuilder` animates fill over (260 ms), `easeOutCubic`; reduced motion uses zero duration. Navigation does not complete an item.
- **Persistent details:** only available fields appear, in stable order. An active rail button closes its field; another switches the existing pane. The cached Forui pane owns a reactive notifier subtree, so selection and item reconciliation update the visible body as well as tabs. One field uses a heading. Multiple fields use full-width `FTabs(scrollable: false)` with complete labels, natural wrapping between words, and zero tracking. The host measures the longest complete word in the localized labels using theme type and `MediaQuery.textScaler`, including selected weight; pane width accommodates equal tab allocation with (4) horizontal label padding on each side. Header, Close, and focus Expand/Restore stay accessible. Compact header navigation uses the same icon contract. Only the selected field renders; its selectable viewport remembers scroll per item/field. Loading and Retry stay local without duplicating the complete item as a fallback.
- **Session boundary:** `FortressFocusSession` owns counts, navigation, completion, Undo, and (600 ms) completion dwell. Details leave visible-stage/counter counting and auto-advance active. The pane follows automatic and deliberate item changes, retaining the selected field when available, otherwise selecting the first available field or closing. Share, inactivity, and context menus pause; closing the final pause resumes a fresh dwell for the same pending completion. Reaching the end is distinct from completing all targets.
- **Share dialog:** explicit This dhikr / Entire chapter scope, individual inclusion tiles, continuous text-size slider (80–160%, default 100%), Images/PDF, page preview, and export controls use the existing dialog shell and `ShareCardDialogLayout`. Slider preparation is debounced (150 ms) and refreshed at drag end; extra horizontal track inset (24) keeps endpoint marks inside the scrolling settings viewport. Footer actions use minimum content width with icons; generation shows a compact icon Cancel. Both align at logical start, right in Arabic. Default inclusions are repetition, supplied virtue, and app name; source and supporting fields are optional. Reading/study edition toggles are removed. Preferred bounds are (1,000 × 720), clamped by shared viewport constraints. Missing promised detail names its item/field, retains choices, offers Retry, and disables export until a valid plan exists.
- **Booklet pages:** preview, PNG, and raster PDF share one measured page plan (540 × 675), margin (36); PNG paints at double size (1,080 × 1,350). At 100%, PNG type is dhikr (44), supporting prose (36), virtue (33), source (30); the same clamped `double textScale` (0.8–1.6) applies to measurement and rendered body type. Quran uses `UthmanicHafs`, prose `UthmanTN`, commentary/reference IBM Plex Sans Arabic. Fitting reading groups stay together; oversized selected content splits at measured grapheme-safe boundaries, preferring whitespace. Continuations retain item/section identity. Export repetition labels are source targets, never session progress.
- **Booklet notes:** virtue has a bold label, section gap (12 plan units), and muted body (16.5). Optional source uses canonical item number in brackets, short right-aligned rule (112 plan units), and muted body (15). PNG files are ordered; PDF is a visual booklet without selectable text. Successful jobs share `Downloads/Tawaq` (Documents fallback), with a title and unique job suffix preventing overwrites. Complete Copy as text remains available. Cancellation/failure removes temporary job output and permits retry.
- **PDF generation and feedback:** canvas pages render sequentially on the UI isolate with yields. A killable worker handles PNG decode, PDF assembly, compression, and writing; only file paths and progress/status messages cross its boundary. Owned staging output is removed on cancellation/failure. PDF progress reserves 50% for rendering and 40% for assembly, then shows a localized preparing-PDF message while serialization finishes. Successful save shows an (8 s) Forui toast with circle-check icon, chapter, page count/format, and Open folder action; failed reveal shows a failure toast.

## Do's and Don'ts

- **Do** preserve canonical religious text, ordering, Quran structure, references, and stored data.
- **Do** let an available visible stage count while details are open and reconcile details when the item advances.
- **Do** distinguish short activation from selection drags and scrolling; keep detail/share controls outside stage counting.
- **Do** inherit themes, localization, accessible scaling, and reduced motion.
- **Don't** promote this surface's circle, composition, or booklet dimensions into app-wide primitives.

Evidence: production focus/session, text spans, structured Quran content, full browse screen and study host/panel, share dialog/page plan/PDF worker; `PRODUCT.md`; incumbent theme and duration definitions.

Current native evidence is under `/home/moath/.local/state/tawaq-delivery/fortress-pr-20261009/evidence/`: eleven settled Linux production-widget captures cover full browse before/after the barrier, flush five-tab panes, Arabic action alignment, focus shade and count 0→1 with details open, English (800 × 900) normal/1.3 labels, and Arabic export actions/Cancel/ready. `rtl-report.json` records `errors: []` and completed outputs under one `Tawaq` directory. The scored English label fix keeps Explanation intact and wraps Related hadith between words. `review-verdict.md` records `disposition: ship` for that scored fix within the original review scope.

The three browse captures contain the complete production `MuslimFortressScreen`; these RepaintBoundary captures do not establish complete app-shell, all-platform, all-theme, or exhaustive interaction approval. Earlier correction and interaction evidence remains historical support for ayah/Mushaf taps, motion, completion, pagination, and worker responsiveness; its previous geometry, label, and backdrop contracts are superseded here. The same 24-page assembly comparison measured maximum event-loop heartbeat gaps of (2.52129 s) on the main isolate and (36.81 ms) in the worker, with elapsed times (3.424 s)/(3.471 s). It establishes responsiveness for that assembly flow, not rendering speed, throughput, or full-app performance.

Latest delivery logs record 1,308 root tests, 35 focused browse/share regressions, 10 goldens, and 25 final preview/focus tests passing. The final longest-word regression uses the actual `MediaQuery` scaler and `paragraph.textScaler`; `review-fix-tests-final.log` confirms all 25 pass. Final analysis exits 0 with 836 infos and no warnings/errors; the default production Linux debug build succeeds. Package analyzers/tests complete on retry; the first Dorar run hit a transient SQLite lock and the retry passes all 363 tests, without a source fix. FVM code generation ran in delivery. This documentation pass changes no app or generated files and runs no build.

Pre-existing drift not repaired: global `DESIGN.md` is absent. This ordinary Manuscript/Sage extension preserves broader product/system files and does not create a global system or sidecar.
