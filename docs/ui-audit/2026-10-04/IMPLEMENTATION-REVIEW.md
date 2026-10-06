# Launch UI review — implementation evidence

RC-16 is pending. This is an interim Impeccable audit and polish record, not final UI/UX sign-off. Tawaq’s existing desktop typography, palettes and interaction model remain the visual authority. Mobile conformance scores would not describe this desktop release; unavailable native input and platform evidence also prevent an overall health score.

The [surface inventory](surface-inventory.json) contains 76 source-backed page, sheet, dialog, drawer, menu and popover groups. Each row lists reachable states and reviewed cases. Partial composition review does not clear the remaining states, input modes or platform matrix.

## Confirmed findings and fixes

| Severity | Finding and user impact | Owner and change | Confirmation |
| --- | --- | --- | --- |
| P1 | Compact verse sharing opened a blank overlay, blocking preview and export | Shared `ShareCardDialogLayout` now bounds the preview height before scrolling; wide settings can scroll. Quran actions expand within finite width, allowing their labels to wrap | [Before](evidence/ayah-share-before.png), [English](evidence/manuscript-en-light-800-ayah-share.png), [Arabic dark](evidence/manuscript-ar-dark-800-ayah-share.png); desktop regression covers loading, errors, retry and loaded metadata |
| P1 | Sidebar collapse temporarily squeezed the outgoing footer button into overflowing widths | `ShellSidebar` keeps one width animation and switches its footer composition directly; labels and menus respect available width | Four English/Arabic normal/reduced-motion collapse/reversal regressions pass; no sidebar errors in the later native batches |
| P2 | Empty Study presented disabled controls in an oversized modal | `QuranScreen` / `StudyPanel` show a compact selection instruction and return action; selected loading/error states stay distinct | [Before](evidence/study-empty-before.png), [English](evidence/manuscript-en-light-800-study-empty.png), [Arabic dark](evidence/manuscript-ar-dark-800-study-empty.png), [Sage](evidence/sage-en-light-800-study-empty.png) |
| P2 | Search reported no matches before a usable Quran query was entered | `AyahSearchSelector` explains the two-character minimum, then distinguishes a completed empty search | [English](evidence/manuscript-en-light-800-quran-search.png); empty/short/no-match/clear regression passes |
| P2 | Hadith showed “No results” while a request was loading, and after failure | `HadithSearchColumn` now reports localized loading while busy and counts a completed successful response | Two English/Arabic regressions fail before and pass after; native XL loading composition inspected |
| P2 | Compact sharing left the first range control below the initial view | Shared preview height is capped at 240px in compact layouts, leaving room for the first control while options scroll and export actions stay fixed | Visibility regression fails at 320px and passes at 240px; [English XL](evidence/manuscript-en-light-800-xl-ayah-share.png), [Arabic dark XL](evidence/manuscript-ar-dark-800-xl-ayah-share.png) |
| P2 | Recent Hadith storage failures silently hid searches or escaped the handler | Localized load retry and write-failure feedback; failed removal/clear retain stored entries; desktop confirmation actions have finite width | Six English/Arabic Linux widget regressions pass at XL text, covering failed load/removal/clear and successful retry |
| P2 | Notes failures lacked clear recovery and deletion could expose raw diagnostics | `NotesBrowser` offers localized retry, retains the original note after failed deletion and reports deletion busy state separately from confirmation | Two failure/retry regressions pass; actual failure-state native input review remains pending |
| P1 | Custom parameters and advanced location collapsed after their opening animation, leaving fields unreachable | Both owners now use local lifted expansion state; Quran Study and Hadith detail already use lifted state and are compatible | Four English/Arabic Linux regressions fail before and pass after, including settled visibility, theme rebuild, collapse and reopen; [Native expanded confirmation](accordion-confirmation-metadata.json) covers English/Arabic light/dark at 800×600 and XL text; native input remains pending |
| P2 | Arabic custom-calculation reset label overflowed by 42px | `CustomParametersContent` wraps bounded labels while retaining icons and actions | Arabic/English Settings tap/swipe regressions pass |
| P1 | Bootstrap initialization failures exposed raw diagnostics without retry; failed settings hydration could leave startup gated indefinitely | `AppBootstrap` now uses localized, bounded recovery for bootstrap/settings/history; Retry invalidates the failed cached dependency and preserves the app gate while loading | Eight new English/Arabic and cached-initialization tests pass; existing history/accessibility contracts pass; [native fixture evidence](recovery-confirmation-metadata.json) |
| P2 | Prayer analytics exposed storage diagnostics without recovery | `AnalysisSection` reports a localized failure; notifier Retry restarts failed repair/store dependencies before recomputing | Four English/Arabic Linux XL failure/pending/recovery regressions pass; native fixture panels inspected |
| P2 | Scholar, book and narrator suggestion failures were reported as no results; short queries also looked like completed empty searches | `HadithLookupSection` uses Forui's error builder, an explicit same-query Retry and a two-character prompt. Its controlled search field retains query/selection; pending debounce work respects disposal | Six Linux XL cases fail against the previous source and pass after repair in both locales; native fixtures cover all three dimensions |
| P2 | Forui's search hint remained English in Arabic menus | Shared app localization list now registers `FLocalizations.delegate`; bootstrap recovery and main app use that owner | Three Arabic hint regressions fail before and pass after; [before](evidence/lookup-ar-search-hint-before.png), [after](evidence/manuscript-ar-dark-800-xl-lookup-books-prompt.png) |

Verse page loading now exposes a localized retry and disables export until a valid selected page exists. All three share consumers use the same friendly export-failure message. Source text and selected IDs are unchanged. Hadith and Fortress preview/options compositions were inspected with actual repository content: [Hadith](evidence/manuscript-en-light-800-hadith-share.png), [Fortress](evidence/manuscript-ar-dark-800-fortress-share.png).

## Runtime scope and checks

The normal-text native confirmation in `/tmp/tawaq-launch-share-action-confirmation` captured 134 images with an empty Flutter error log. It covers six compact routes, Quran Study/Notes/player/search/navigation/share, player dialogs, Settings tabs, actual Hadith results/share, Fortress selection/reading/insights/share, About modal and five onboarding stages. Manuscript uses Arabic/English and light/dark; onboarding was captured in the last selected dark mode. Captures verify the actual 800×600 Flutter view. The preceding 146-image inspection also covered 1200×860 and 1440×900 and revealed the share failure; its contact sheets were inspected. It does not certify every hidden control or scrolling state.

[Normal confirmation metadata](share-confirmation-metadata.json) records the dirty source, binary/kernel hashes, image hashes, environment and known limitations. Later badge, compact preview and recent-search recovery corrections are explicitly identified; the normal-text batch predates them and the accordion fixes. Earlier all-palette evidence retains its own [candidate identity](compact-capture-metadata.json).

An 11.77-second silent compositor-region clip was recorded at normal speed, fully decoded, and six representative frames inspected. It shows mounted programmatic dialog opening/closing and route changes. The encoder rounds the owned 801×600 region to 802×600. It establishes a visible flow, not keyboard/pointer handling, input latency, audibility or a comprehensive flicker verdict. Its path and hash are in the confirmation metadata.

The XL batch captured 134 images without Flutter errors. All contact sheets were inspected, with selected full-resolution share and Settings captures. [XL metadata](xl-confirmation-metadata.json) preserves that candidate. The later 124-image compact-control confirmation also has an empty Flutter error log; its 12 share compositions were inspected to confirm the first settings control is visible. [Share-control metadata](share-controls-metadata.json) records its narrower review scope. Both batches predate the new recent-search failure handling and accordion fixes; no recovery-state native proof is inferred from them.

The full root suite passes **1,184 tests**, including the existing recent-search/accordion regressions plus eight startup, four analytics and six lookup recovery tests. Flutter and actual Dart-plugin analysis report information-level lints only; final Flutter analysis reports 401 infos and actual Dart-plugin analysis 418 infos, with no errors or warnings. Two plugin-only warnings on blank fixture roots were corrected before the final plugin check. All local-package analyzers and tests pass through `tool/checks.sh packages`: Dorar 324, Dorar Flutter 1, Mushaf 138, Hisn 18, Adhan 51 (two upstream API tests explicitly skipped), desktop tray 3. Dorar’s two test-storage fixture changes are reproducible from its pinned checkout via a tracked, idempotently applied patch. Five release-validator tests pass. Localization and history provider generation were performed; the latest ARB changes were regenerated with `flutter gen-l10n`.

A saved reflection was also verified across a real forced process boundary: PID 1727361 acknowledged `flushAyah`, received SIGKILL without graceful disposal, and independent PID 1796577 hydrated the exact text from the same isolated Hive directory. The reopened Notes Browser capture was inspected. [Kill/reopen metadata](kill-reopen-metadata.json) records both source/binary identities, acknowledgement and signal. The capture has a 960×1044 Flutter buffer and does not prove complete native chrome visibility or unacknowledged draft persistence.

The October 5 [recovery batch](recovery-confirmation-metadata.json) contains 68 inspected source compositions with injected startup, analytics and Hadith lookup failures. Native exit was zero and its Flutter error log was empty. Actual mounted Retry callbacks reach pending and successful fixture outcomes; startup stays gated while pending. These standalone fixtures do not prove full route composition, real disk/network faults, or native input. The first analytics fixture used an incorrect Material host; that batch is excluded as analytics visual evidence. Shared Forui localization was confirmed on the final batch. Package-supplied Arabic strings include untranslated `selectNoResults` and text-field Clear semantics. App consumers now provide localized clear semantics and shared empty content; native screen-reader acceptance remains pending.

## Remaining final review

XL broad composition and compact sharing confirmation are complete within the recorded scope. A separate 124-image menu/selector batch completed without Flutter errors. Its compositions were inspected; [metadata](controls-confirmation-metadata.json) excludes background and clipped controls mistakenly targeted by the first harness traversal. It adds partial review of prayer menus, Quran division/zoom/source selectors, the reflection editor, Hadith filters/details/recents/favorites and Settings method/voice/timezone selectors. A final 50-image Settings/onboarding batch confirms the repaired custom-parameter and advanced-location panels, including visible Madhab/high-latitude menus. All contact sheets and selected full-resolution expanded panels were inspected; its [candidate metadata](accordion-confirmation-metadata.json) records image hashes and dimensions. Native exit was zero and the Flutter error log was empty. Reduced-motion runtime, every remaining selector/menu/recovery state, native pointer/keyboard and screen-reader behavior, audio/device handling, installer/login/tray acceptance, and Windows/macOS remain required. Native Cua authorization is unavailable in this host; mounted callbacks do not substitute for it. Wide Flutter view captures exceed the secondary monitor and do not establish complete native chrome visibility.

The earlier two sidebar overflows have an established owner and regression; the two share constraint failures were diagnosed and repaired, rather than inferred from a clean unrelated route. No unreviewed surface is marked passed. Performance evidence remains limited to a prior profile candidate: its roughly 323MiB RSS has not established a comparable reduction; the sub-200MiB optimization objective remains unmet, and the final candidate still requires profile/release measurements. Source/provenance and distribution policy fields remain unresolved where authority has not been verified. Early Mushaf preparation now belongs to a retryable provider behind `AppBootstrap`. Its failure/retry ordering and package/app Hive integration have regression coverage. File logging already handles its own failures. Actual fresh native startup measurements are recorded separately.

## October 5 final local corrections

The 164-image remaining-surface inspection found two reproducible native layout
failures. An invalid route left an outgoing sidebar reading an empty GoRouter
match list; sidebar and bottom navigation now use the route-information URI.
Desktop reflection deletion placed a flexible button inside an unbounded
actions row; the dialog now gives both actions bounded equal width.
Seven of eight focused cases failed before these changes; all eight pass after,
including Arabic/English sidebar route changes, Linux deletion recovery at XL
text and localized Quran selector empty states.

Early reader initialization and Hadith repository initialization now recover
through their actual cached owners. The reader package repairs missing core
boxes and preserves typed Hive registration during retries. One package test
and one app/package durable reflection round-trip verify these contracts.
The ayah action switcher and fade/scale honor reduced motion; six action tests
pass, including keyboard and reduced-motion coverage. Offline deletion icons
now have explicit localized semantics.

The first inspection batch exited with the two failures and is retained as
before evidence, not acceptance. A subsequent confirmation stopped after the
English captures because GTK reported 801 rather than 800 pixels at minimum
width; that incomplete harness run is excluded from full confirmation. The
harness now records one-pixel compositor rounding with actual image dimensions.
No native pointer, keyboard or screen-reader certification is inferred.

The [final profile record](final-profile-metadata.json) reports 1,079 frames
from twenty warm cycles through six routes after three warm-up cycles. P95
UI/raster work is 11.66/2.506 ms; p99 is 15.45/3.547 ms. The fraction with UI
or raster work above 16.667 ms is 0.37%; maximum UI work is 24.882 ms. All
245 warm memory samples report a visible test workspace and no hidden window.
Mean RSS for the first/last twenty warm samples is 316.49/316.91 MiB; the
maximum is 324.72 MiB. This demonstrates stable memory in this scheduled flow,
not a meaningful comparable reduction or a sub-200 MiB result. The actual
GTK buffer is 801×600 and was clipped by twelve pixels at the monitor edge;
this does not establish full native chrome visibility. A preceding background
workspace run is excluded. No input latency, audible playback, route completion
latency or cross-platform performance claim follows from frame work timings.

The [164-image confirmation](final-remaining-ui-metadata.json) completed with
exit zero and an empty Flutter error log. All seven contact sheets and selected
full-resolution Arabic/English deletion and route recovery images were
inspected. The repaired dialog has bounded equal-width actions in both
directions and themes. Fixture/mounted-callback scopes are recorded explicitly:
the alert is silent; the offline row is a non-audio fixture; delete confirmations
are canceled; city/GPS settings captures show inline controls only. These add
partial review to fourteen previously unreviewed source groups. The ayah play
menu was not opened. A separate wide hero review identified a fixed-duration
status animation; its reduced-motion regression fails before and passes after
for Arabic and English, with the status menu still usable.

The [eight-image focused edge confirmation](final-edge-metadata.json) also
exited zero with an empty Flutter error log. All images were inspected at full
resolution. It shows the wide hero status menu and actual About fallback in
both locales/themes, with reduced motion and an injected failed external
launcher. The earlier fixture mistakenly replaced viewport size, retained a
stale controller, and targeted a hidden player tile; those interrupted harness
runs are excluded. The final traversal scopes the About link to AboutView and
reacquires the mounted hero trigger after rebuilding. No browser or clipboard
action was invoked. Of 76 source groups, 75 now have partial composition review;
the OS tray remains wholly unreviewed. Every row still needs its remaining
state/input/platform checks. There is no final RC16 sign-off or health score.

Five [fresh native profile launches](final-startup-metadata.json) used the real
entry point and distinct isolated data directories. Each exited zero with no
logged Flutter errors. The first framework frame occurred 25–42 ms after binding
initialization; the ready app frame was observed 613–868 ms after that point.
External process lifetime was 1.293–1.789 seconds, including loader, measurement
write and exit. This supports fast startup on the named Linux machine, not
verified input responsiveness or five cold OS/cache launches. The original
pre-widget initialization concern is now covered by owner retry regressions
and actual fresh-process startup evidence.
