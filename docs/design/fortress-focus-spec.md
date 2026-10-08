# Fortress focus reading and chapter booklets

Status: implemented correction and interaction contract. Final isolated native recaptures cover the named surfaces; both reports record no Flutter errors. The finish verdict resolves the last slider endpoint clipping finding within that scope.

## Purpose and scope

Reading and repeating a chapter uses a calm open stage with clear chapter progress and a substantial counter. Full supporting material remains available in a persistent side reading surface. Chapter and item sharing use explicit inclusions and complete pagination.

This extends Tawaq's Manuscript/Sage identity on native desktop in Flutter/Forui. Arabic and English interfaces, mouse, keyboard, trackpad, compact windows, enlarged type, and reduced motion remain supported. The supplied HTML is a composition reference only. No new religious source, translation, invented ayah marker, stored-data contract, or global identity is introduced.

Confirmed choices are automatic advance after reaching the repetition target; side sheets for all focus/browse details; active counting/advance with details visible; individual share inclusions rather than editions; and default repetition, supplied virtue, and app name, with source optional.

## Content and source boundary

Canonical content, item order, repetition targets, references, and structured Quran presentations come from `FortressRepository` and the checked-out `packages/hisn_elmoslem` source. Raw source stays separate from typography and display transformations. English interface labels do not imply an English religious translation.

The bundled database inspection on 2026-10-08 established these content constraints:

| Content | Observed range / maximum |
| --- | --- |
| Items in a populated chapter | 1–24 |
| Raw dhikr body | 6–1,416 characters |
| Repetition target | Maximum 100 |
| Virtue | Maximum 241 characters |
| Source | Maximum 480 characters |
| Sharh | Mean about 4,571; maximum 14,746 characters |
| Related hadith | Mean about 2,413; maximum 18,458 characters |
| Benefits | Mean about 2,702; maximum 10,709 characters |

These are raw field lengths, not rendered line counts. Quran can span passages or multiple Mushaf pages. The morning chapter's 24 items, rather than the HTML's four examples, define its actual session.

## Focus composition and typography

The page contains a chapter header with Exit, title, segmented progress, item position, and chapter sharing; an independently scrolling reading stage; an available-detail rail with item Share; supplied virtue when present; and a stable counting dock. The app navigation rail and chapter browser leave the focus composition. Native window integration remains in place.

The stage stays open rather than enclosing the dhikr in a card. Theme `background`, `foreground`, `primary`, `secondary`, `border`, and `mutedForeground` provide the composition; the side sheet uses background, the expanded browse item uses card. Warm charcoal/gold belong to Manuscript dark; other palettes retain their semantic colours.

Focus prose uses bundled `UthmanTN`, regular weight, line height 1.85. Measured line layout selects desktop tiers 56/40/30 logical pixels or compact 40/32/26. Cache measurement and rendered stage content per item, constraints, typography, theme, and text scale so counting does not remeasure the passage. Respect user scaling and scroll overflow. Stage width caps at 720 with 32 horizontal/24 vertical padding. Short invocations centre; sustained passages align to their content direction and begin at the top. Preserve source block boundaries and labels.

Structured Quran keeps the existing Mushaf path and typography. Full pages render read-only through `MushafPageRange.onPage`, preserving line breaks, surah headers, basmalah, and verse glyphs while omitting page-number chrome. Supplied literal quotations in prose use bundled `UthmanicHafs` on the quoted span; surrounding prose uses `UthmanTN`. Only ornamental quote brackets are removed for display; the original source and semantic label retain them. Ayah numerals and font glyphs are supplied content, never newly added text or markers.

Quran loading and failure stay local to the affected block. Failure exposes Retry rather than repeating the whole item's fallback text for each failed Quran block.

## Counting and chapter progress

The large circle value means completed repetitions, beginning at zero; the smaller label states the target. `FortressFocusSession` owns remaining counts, with completed derived as target minus remaining. Circle diameter remains 128 desktop, 96 compact, and 160 enlarged. The ring fills clockwise from twelve o'clock. Counter digits use tabular figures; hover, press, focus, completion check, and localized semantics remain visible.

A short primary pointer tap in the reading stage counts even when selectable prose, ayah, or Mushaf children handle selection. Pointer movement beyond the tap threshold, long presses, scrolling, and selection drags do not count. Detail, header, and share actions are outside stage counting. A counter click or registered count shortcut also counts; holding a key does not consume repeated counts. Keyboard activation of a focused control retains that control's meaning.

Reaching the target clamps the count, completes its ring/segment, and schedules exactly one advance after 600 ms. Details do not pause counting or this dwell. A visible accessible stage/counter remains active, and the pane follows the advancing item. Share, context menus, and app/window inactivity pause the session. Removing the final pause starts a fresh dwell for the same completed pending item. Navigation, Undo, exit, and disposal cancel stale advance work.

Undo last count is available in the counter context menu and registered localized command, including the completion dwell. It reverses the last repetition rather than resetting a chapter.

Each canonical item owns one read-only chapter segment, independent of repetition target. Complete is solid primary; unfinished retains proportional fill; skipped/unvisited is a quiet track. A separate marker identifies the current item. Segments are 4 logical pixels high and animate through `TweenAnimationBuilder` over 260 ms with `easeOutCubic`; reduced motion uses zero duration. A narrow header shows a local segment window with continuation markers. Item position remains visible and semantics summarize chapter progress.

All Previous/Next controls are icons with localized semantics. Directional glyphs mirror once for RTL through the existing icon behavior. Registered shortcut meanings remain Left/Down Next and Right/Up Previous. Horizontal stage navigation and vertical reading scrolling keep distinct meanings; focused tabs, text, and menus retain local keyboard behavior.

## Persistent side details

### Entry and fields

Available fields appear in stable order: Virtue, Source, Benefits, Explanation, Related hadith. `hasDistinctVirtue` omits duplicate virtue display while retaining raw fields. Source-only and virtue-only items expose their detail action; items without details expose Share only. Clicking a rail field opens it directly; clicking the active field closes; another field switches the existing pane. Browse opens an available field, preferring Virtue through the stable ordering.

The header identifies chapter/item, exposes Close, and in focus exposes Expand/Restore. Compact controls add icon Previous/Next. It shows no study-pause indicator because opening details does not pause. One field uses a heading. Multiple fields use `FTabs(scrollable: false)` distributed across width. Constrained labels ellipsize while semantic text remains complete.

Forui caches the persistent pane builder. The pane therefore contains its own `ValueListenableBuilder`: browse owns the selected-kind notifier per controller, while focus owns a sheet-revision notifier covering selection, item reconciliation, and extent. A tab change updates the visible selected body, not just its active styling; item changes update header and body together. Controller/notifier lifetimes end with their owning sheet/reader.

### Topology and geometry

Every focus and browse detail surface is a Forui persistent SIDE sheet hosted by `FSheets` and created by `showFPersistentSheet`. Logical end is left in Arabic and right in English. There is no bottom-sheet or `FResizable` presentation.

| Focus window width | Geometry |
| --- | --- |
| At least 720 logical pixels | Sheet width `min(420, windowWidth × 0.48)` is reserved at logical end; reader reflows into the remaining width. This includes an 800-wide compact window. |
| Below 720 | Full-window-width side reading surface with accessible header/Close; closing restores the focus reader. |

The `_compact` flag remains below 1040 or when scaled 18-pixel detail type exceeds 27. It chooses compact controls only and does not choose geometry. Enlarged text therefore preserves side-sheet topology. Reader padding animates to the reserved width over 240 ms with `easeOutCubic`, zero with reduced motion. Expand/Restore changes the real persistent-sheet presentation/controller between dock width and full width; it is not a separate resizable composition. The controller is hidden/disposed at closure and recreated as needed. Browse uses the same side host with width 480 clamped to its window.

Browse details cover the underlying browse composition with theme Forui `FModalBarrier` blur/dim; an outside pointer activation dismisses the pane. Barrier transition uses the persistent-sheet theme duration, zero with reduced motion. Focus deliberately remains nonmodal: no blocking/blurred backdrop is added, and its visible reading stage/counter remains countable with details open, preserving the confirmed interaction choice.

### Long content, reconciliation, and recovery

Header and tabs stay fixed over one selected, bounded scrolling body with scrollbar and selectable text. Commentary reuses `FortressCommentaryParser`/`FortressCommentaryText`, including source-defined numbered blocks, quotations, citations, and numeral handling. Ordinary details use 18 logical pixels, sources 16, line height 1.8. Do not invent headings, reinterpret source structure, truncate selected bodies, or replace them with summaries.

The shared session `PageStorageBucket` remembers scroll per `(contentId, detailKind)`. Automatic and deliberate item changes retain the selected field if present, otherwise select the first available field; with no fields or at chapter end the sheet closes. New item identity and body reconcile together, preventing stale commentary under another title.

Virtue/source use already loaded fields. Commentary uses repository-backed availability and loading. A sheet-local loader or error with Retry leaves the reader, header, and field choices intact. Missing promised content is a local failure rather than a successful empty section or a duplicated whole-item fallback.

Escape closes Share first, then details, then exits focus. Closing details restores stage focus. Focus counting shortcuts require primary stage focus, so reading or selecting pane content does not accidentally trigger a keyboard count; deliberate visible-stage pointer taps still count with the pane open.

## Browse integration

Expanded items are full reading cards rather than a longer clipped tile. `FCard` has 24 internal padding, incumbent `theme.radii.lg` top corners, and square bottom corners (0). Ordinal and repetition target flank full prose or structured Quran content. Supplied virtue occupies a tinted labelled section. Source is muted, limited to two visible lines, and opens the source pane for full reading. Available detail actions and Share are individual content-width chips (`mainAxisSize.min`) followed by Collapse. A short primary body tap also collapses through selectable content. `FortressReadingTapRegion` rejects movement beyond 6 logical pixels, taps of 500 ms or longer, selection drags, and long presses; nested source/detail/share controls use `FortressReadingTapControl` to exclude their activation. Repeated generic category icons are removed from chapter/browse chrome.

Collapsed preview metadata uses `none` rather than an arbitrary benefit-only badge. Its full distinct supplied virtue remains governed by the existing content renderer. Canonical selection, search-result entry, favorites, and return-to-chapter context retain their existing owners. Focus and browse reuse the same detail panel and source-safe text presentation.

## Chapter end

Reaching the last item shows a centred, scrollable content column capped at 680. It uses an 88 tonal check/book glyph, a 36 title, muted chapter, 360 progress summary, 208 primary action, and 176 outline/ghost secondary actions that wrap when constrained.

All targets completed produces factual Completed with Return to chapter, Read again, and Share chapter. An unfinished end says Reached the end, states the actual completed total, and offers Continue unfinished. Read again explicitly resets this transient session. Undo remains available when history permits. Merely reaching the last item never claims completion.

## Motion and feedback

The ring uses the existing fast duration (150 ms); press uses instant (100 ms) and scale 0.97. Chapter fill uses 260 ms `easeOutCubic`; sheet-reservation padding uses 240 ms `easeOutCubic`. Item content keeps the incumbent direction-aware switcher. Religious glyphs stay stationary during counting. Reduced motion zeroes custom fill/scale/layout movement. The 600 ms reading dwell remains a session rule. Existing supported haptics remain; no sound, confetti, continuous glow, or new motion system is added.

## Sharing through explicit inclusions

### Choices and entry

Item sharing defaults to This dhikr; chapter entry defaults to Entire chapter. The dialog shows scope, individual available inclusion tiles, a continuous text-size slider, Images/PDF, actual page count/preview navigation, and export actions. Scope changes reset to default inclusions. Defaults are repetition, supplied virtue, and app name; source, explanation, related hadith, and benefits are individually optional. There are no Reading/Study edition toggles or hidden select-all preset.

The established `ForuiDialogLayout`/`ShareCardDialogLayout` provides settings alongside preview, stacking when constrained. Preferred bounds are 1000 × 720, clamped to viewport. The Forui slider ranges continuously from 80–160%, defaults to 100%, and exposes percentage semantics plus 80%, 100%, and 160% marks. Its extra 24 horizontal track inset keeps endpoint labels inside the settings scroll viewport, including the saved-result state. Changes invalidate stale preparation and debounce re-preparation by 150 ms; drag end cancels that timer and prepares immediately. Available-field and text-size choices are retained through preparation, local failure, and retry; generation disables their controls. Export is disabled until the selected content produces a valid plan. Footer Save, Copy image, and Copy text use minimum-content-width icon buttons in a wrapping row; generation replaces them with compact icon Cancel.

### Full content and pagination

Preview, PNG, and PDF share one ordered measured `FortressBookletPlan` carrying item/section identity. Plan size is 540 × 675 with 36 margins; PNG renders at 1080 × 1350. At 100%, PNG type sizes are dhikr 44, supporting prose 36, virtue 33, source 30. `FortressBookletPlan.create` accepts `double textScale = 1`, clamped to 0.8–1.6; the former `bool largeText` contract is gone. Shared body styles apply this scale to both measurement and output, so changing size can create more pages without preview/export drift; pagination does not shrink text to force a count. Quran uses `UthmanicHafs`, prose `UthmanTN`, supporting/reference copy IBM Plex Sans Arabic.

Keep a fitting dhikr and selected virtue/source together. Oversized content splits at measured grapheme-safe boundaries, preferring whitespace, with continued item/section identity. All individually selected long supporting fields remain with their item in canonical order and can span as many pages as needed. No ellipsis, arbitrary field-block cutoff, or forced two-page limit is permitted. Preserve selected source-span coverage without dropped/duplicated bodies, excluding intentional repeated context labels.

Virtue has a distinct bold label, 12 plan-unit section gap, and muted 16.5 body. Optional source has canonical item number in brackets, short right-aligned 112 rule, and muted 15 body. Repetition is the supplied target, never session progress. App name is included only by its chosen tile.

### Output and recovery

Images are an ordered set with zero-padded filenames. Save all pages writes the set; Copy image copies the current preview page; native bundle/drag uses generated files. PDF writes one local visual booklet using the same rendered page images and aspect. Its pages have no selectable/searchable text; the UI explains that limitation. Complete Copy as text remains available.

The installed PDF writer is `pdf` 3.13.1. Canvas rendering stays on the UI isolate, one page at a time with yields and the bounded preview cache. `FortressPdfExport` owns a killable worker for heavy PNG decode, PDF assembly, compression, and file writing. Input messages contain PNG paths and destination path rather than page byte payloads; returned messages carry progress, readiness, or failure. Cancellation kills the worker, invalidates the job, and cleans its owned staging directory. The worker uses 432 × 540-point PDF pages.

PDF progress assigns 50% to page rendering and 40% to assembly; localized preparing-PDF copy remains visible through final serialization/write. Generation exposes compact Cancel. Unique staging directories prevent collisions; completed output appears only after the full job succeeds. Cancellation/capture/disk failure cleans this job's temporary output, retains choices, and permits retry. Successful save shows an 8-second `FToast` with `circleCheck`, chapter title, localized page-count/format summary, and Open folder action. Successful reveal dismisses that toast; failed reveal shows a localized failure toast.

Missing selected commentary identifies the item/field with localized Retry and blocks export. Individual inclusion tiles allow the user to remove that field. A superseded options job cannot update the current preview. A failed preview never masquerades as an empty chapter.

## Implementation ownership and fan-out

Flutter 3.47.5 is pinned by `.fvmrc`; Forui 0.27.3, forui_hooks 0.27.0, and PDF 3.13.1 are pinned in `pubspec.lock`. Use the resolved source APIs.

| Owner / consumer | Finished contract |
| --- | --- |
| Focus reader and `FortressFocusSession` | One transient owner for count/history, navigation, pause/dwell, completion; reader composes ring, segments, stage, real persistent controller, and end states. |
| Dua content and text spans | Source-safe prose/quoted-Quran typography, existing structured Quran path, full expanded content, local rendering Retry, selection-compatible counting. |
| Study host/panel | Persistent logical-end topology with reactive selected body/item, available fields, scroll memory, and local recovery; browse uses modal outside-dismiss, focus stays nonmodal/countable. |
| Browse category detail/sidebar/rows | Expanded reading cards with square bottom corners and selection-safe body collapse, preview metadata `none`, individual actions, chapter-share entry; preserve search, chapter context, and favorite data. |
| Share dialog/page plan/PDF worker | Explicit scope/inclusions, continuous measured text scale, full pagination, shared preview/output, PNG set/raster PDF/text, owned cancellable staging and worker, progress, actionable save feedback. |
| Localization and shortcuts | Arabic/English labels, Undo, completion/error copy, localized icon semantics, retained registered key meanings and focus scopes. |
| Core share/dialog, Quran/Hadith consumers | Reuse incumbent infrastructure; preserve neighboring share behaviors and architecture boundaries. |
| Settings, onboarding, prayer/calendar, recitation/audio | Intentionally unaffected; no new schema or persisted session history. |

`CONTEXT.md` retains established share-card, share-set, share-bundle, and chapter-booklet meanings. Repository caching remains the data owner. Field selection, scroll positions, sheet extent, and repetition session are transient presentation state. No duplicate commentary cache or durable count history is introduced. Import contracts remain enforced by `test/architecture/dependency_boundaries_test.dart`.

## Validation and native evidence

The validation contract includes targets, retained counts, skipped segments, exactly-once auto-advance, details-open counting/advance, Share/menu/inactivity pause, Undo, and truthful chapter end. Widget/source checks address bounded detail tabs, item/field reconciliation, local errors, browse expansion, full Quran rendering, literal quotation font boundaries, icon semantics, and share defaults without editions. Page-plan checks address canonical order, complete selected spans, continuation identity, grapheme-safe splits, repetition/source association, and consistent preview/export boundaries. Existing focused session, reader, share-dialog, and page-plan regression files were inspected in this pass; the implementation delivery records their execution results.

Native correction evidence is under `/home/moath/.local/state/tawaq-delivery/fortress-corrections/evidence/`:

| Evidence | Covered result |
| --- | --- |
| `desktop-focus.png`, `desktop-side-sheet.png` | Open stage, counter, chapter rhythm, distributed detail tabs, logical-end side composition. |
| `count-with-details.png`, `ayah-tap.png`, `mushaf-tap.png` | Native short pointer taps count with details visible and through real ayah/Mushaf children. |
| `quoted-ayah-prose.png` | Supplied quoted Quran font boundary within prose. |
| `expanded-reading-card.png`, `browse-persistent-sheet.png` | Full expanded item, labelled virtue/source, individual actions, shared browse side sheet. |
| `compact-side-sheet.png`, `large-text-focus.png` | Final 800-wide reader reflow with full stage/counter/detail rail, and enlarged focus type/control composition. |
| `desktop-completed.png`, `desktop-unfinished.png` | Truthful, centred end states and available actions. |
| `share-inclusions.png` | Scope, explicit inclusion tiles, default virtue/repetition/app name, image/PDF controls. |
| `count-motion.mp4` | Interpolated segment fills followed by automatic advance in canonical chapter 6. |

These are isolated native QA captures of production widgets with bundled sources. All 13 named screenshots were recaptured after the final geometry correction. `corrections-report.json` records no Flutter errors (`errors: []`) and the motion frames' actual timestamps. `/tmp/fortress-corrections-native-final.txt` records actual pointer count changes: with details 0→1 of 100; ayah 0→1 of 1; Mushaf 0→1 of 3. Final compact evidence visibly retains the complete two-column Arabic stage, entire counter, and full detail rail. Geometry regressions at 800/1200 pass in the implementation delivery. Reviewer decode verification found the full 1200 × 850, 1.36-second video readable, showing segment interpolation and automatic advance. The reviewed named visual elements match the correction direction.

The final compact capture supersedes its earlier pre-correction version. These earlier scoped captures remain valid for the named behavior; earlier focus/virtue evidence may establish its earlier booklet/failure states, but does not override current topology or share choices.

Interaction follow-up evidence is under `/home/moath/.local/state/tawaq-delivery/fortress-interactions-20261008/evidence/`:

| Evidence | Covered result |
| --- | --- |
| `expanded-card.png`, `collapsed-preview.png` | Incumbent top/square bottom card geometry, compact actions, body pointer collapse, preview without benefit-only metadata badge. |
| `browse-benefit-backdrop.png`, `browse-sharh-after-tab.png`, `browse-hadith-after-tab.png` | Theme blur/dim, outside pointer dismiss, production tab callbacks changing the actual selected body. |
| `compact-light-sheet.png` | 800 × 900 English-interface Manuscript light browse sheet and backdrop. |
| `focus-benefit-after-tab.png` | Nonmodal Arabic reader/counter beside the production pane after field selection. |
| `share-slider-actions.png`, `pdf-generating.png`, `export-ready-toast.png` | Continuous size control, complete endpoint marks, compact footer/Cancel, generation feedback, successful actionable toast. |

These ten final captures use isolated native compositions of production widgets, generally 1200 × 850 Arabic Manuscript dark; they do not show the full app shell. Body collapse and outside-dismiss used actual pointer actions; tab selection used production callbacks. `followup-report.json` records `errors: []`. The finish review accepted the requested scope except slider endpoint clipping; `/home/moath/.local/state/tawaq-delivery/fortress-interactions-20261008/review-verdict.md` scores that last fix resolved and records `disposition: ship` within the original isolated composition scope.

Comparable PDF assembly used the same 24 PNG pages. Main-isolate assembly recorded maximum heartbeat gap 2.52129 s and elapsed 3.423993 s; worker assembly recorded 36.81 ms and 3.470566 s. This establishes improved event-loop responsiveness for that measured assembly flow, not increased throughput, rendering speed, or full-app performance. PDF inspection confirms 24 pages at 432 × 540 points. Captures do not establish the entire locale/theme/input matrix, cross-platform behavior, or every export failure path.

The implementation delivery records 40 narrow regression tests and 10 updated goldens passing; after the final endpoint inset change, all 9 share-dialog tests pass. Full root testing records 1288 passes and one pre-existing Dorar release-harness fixture failure. The Dorar fixture patch independently fails `git apply --check` at `test/client/dorar_client_test.dart:1`, reproducing that failure. `git diff --check` passes. Final analysis reports 603 infos and no warnings/errors. `fvm flutter gen-l10n` ran and tracked text-size, preparing-PDF, and export-summary outputs are included. No local-package implementation changed. This documentation pass changes no app/generated files and runs no build. The final compact runtime capture and geometry regressions establish the corrected reservation behavior. Inspect the final diff and preserve unrelated changes.

## Record boundary and drift

`.impeccable/surfaces/fortress-focus.md` records this extension's observed design rules. This specification records the current contract, replacing obsolete bottom-sheet, study-pause, resizable-dock, and edition models throughout. Broader product/system files remain outside this pass. The absent global `DESIGN.md` is pre-existing drift and is not repaired by an ordinary surface extension.
