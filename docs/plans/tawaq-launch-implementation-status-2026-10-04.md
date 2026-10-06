# Launch implementation status

The implementation is in this worktree. Launch acceptance is incomplete. This record separates changes and automated checks from the native release proof still required by the [specification](tawaq-launch-readiness-2026-10-04.md).

The user approved continuing the remaining plan and enabling its legacy-missed history cleanup on October 4. That approval is recorded in [the migration policy](../migrations/legacy-missed-history.md). No additional data approval is pending.

| Work | Implemented and checked | Remaining acceptance |
| --- | --- | --- |
| W00 | FVM verification pipeline, provider lifetime repairs, retryable early Mushaf preparation, localized startup/settings hydration recovery, app/package checks, reproducible pinned Dorar test-fixture patch, failure propagation tests | Frozen clean candidate and final clean-checkout release checks |
| W01 | Directional shell/layout fixes, shared Forui localization delegate, actionable semantics, labels, bounded controls, reduced-motion owners, sidebar collapse/reversal regression | Native keyboard/focus/screen-reader and full viewport/theme matrix |
| W02 | Shared configured-zone prayer day, midnight/calendar behavior, atomic coordinates/zone application independent of name lookup, five-prayer overview, completion metrics | Native clock/permission/location scenarios on all platforms |
| W03 | Five named setup stages, durable finish ordering, editable configured-zone preview, alert readiness | Real interrupted setup and desktop permission/lifecycle paths |
| W04 | Stable Quran controller/layout, compact Study, header Notes browser, canonical drafts/save status/retry and flush boundaries, source search behavior | Remaining scrolling/error/input states and transition recordings |
| W05 | Bounded drawer, explicit missing choices, unknown restored duration, untimed continuous seek, stale-valid catalog, streaming before optional saving, owned cancellation and partial-file cleanup | Native audio/device/media-key/interruption, offline file management and matched performance proof |
| W06 | Search generation/debounce/pagination lifetime repairs, localized recovery, visible individual recent-query removal, clear confirmation, honest loading badge, storage failure/retry feedback, same-query scholar/book/narrator lookup recovery, cached initialization retry for lookup/detail/favorites/recents | Remaining comparison/pagination recovery and native keyboard checks |
| W07 | Compact browse/read flow, locale chrome direction, Arabic source preservation, meaningful favorites/filter states | Remaining native search/favorites/counter/return interaction paths |
| W08 | Appearance ordering, mode/palette copy, typography wrapping, real package metadata, truthful About link actions, font licenses and content inventory | Verified authority/redistribution terms for the 14 bundled SQLite editions; remaining recovery states |
| W09 | Settings tab settlement and publication, retained Quran reader ownership, reduced-motion repairs; named Linux profile comparison retained | Broader per-flow profile/release and input-latency proof, comparable RSS reduction, complete native motion review |
| W10 | XDG autostart identity/escaping/capability handling, native chrome policies, guarded exact-SDK artifact/release pipeline | Real login/install/tray/permission sessions, Windows/macOS hardware acceptance, distribution/signing decisions and all artifacts |
| W11 | Atomic verified bundled content generations; approved startup history barrier with backup/digest/journal, idempotence and retry; durable writes | Full existing-data upgrade and kill-boundary scenario matrix; acknowledged reflection kill/reopen now has independent native-process evidence |
| W12 | RC-01–RC-16 validator, source-derived surface inventory, Impeccable findings/fixes and candidate-specific evidence | Complete final all-surface, state, input and three-platform sign-off |

## Verification

- Full app suite: **1,184 tests pass**, including early initialization, cached Hadith recovery, typed reader/app adapter integration, invalid-route sidebar, desktop reflection deletion and localized selector regressions.
- App analysis: no errors or warnings; information-level lints remain. Latest exact counts and logs are in the [UI review](../ui-audit/2026-10-04/IMPLEMENTATION-REVIEW.md).
- Package checks pass: Dorar 324, Dorar Flutter 1, Mushaf 138, Hisn 18, Adhan 51 with two explicit upstream API skips, desktop tray 3. Changed package analyzers also pass.
- Five release-validator tests pass. Localization and root provider generation were performed. Final diff whitespace check passes.
- Native Linux captures and an inspected, decoded normal-speed clip establish the recorded compositions and mounted callback flows. An acknowledged reflection survives SIGKILL and independent process hydration. These do not establish native input or audio acceptance.

The [Impeccable report](../ui-audit/2026-10-04/IMPLEMENTATION-REVIEW.md), [surface inventory](../ui-audit/2026-10-04/surface-inventory.json), and candidate metadata contain the precise review scopes. Untested cases remain pending. The Cua connector cannot see the Wayland app window in this host, and Windows/macOS runtimes are unavailable. Those limitations do not turn source inspection or callback captures into platform passes.

## October 5 completion pass

Early reader preparation now belongs to the retryable bootstrap gate. Package
initialization propagates asset-copy failures in release builds, observes shared
failure futures, permits a retry without duplicate adapter registration, and
restores a missing bundled box even when its cached manifest entry matches.
Typed registration preserves app reflection persistence; a real package/app
round-trip regression verifies it.

The final Impeccable inspection found and repaired the invalid-route sidebar
crash and desktop reflection-delete layout failure. The route error owns its
background and bounded localized recovery action. Quran ayah actions respect
reduced motion; search clear semantics and empty selector results are localized.
Sidebar and bottom navigation both read the safe route-information URI. No
religious source bytes, adapter IDs or serialized fields changed in this pass.

The owner supplied IslamHouse as a content-source lead and confirmed that no
Windows/macOS test machines are available. Specific item/download/permission
records remain unresolved in the content inventory. These are external release
requirements, not additional data approval requests. No release or PR was
published.

The latest Linux confirmations contain 164 remaining-surface compositions and
eight focused hero/About compositions, with empty Flutter error logs. All
contact sheets and the eight edge images were inspected. The source inventory
has partial composition evidence for 75 of 76 groups; only the OS tray remains
wholly unreviewed. Remaining state/input/platform cases are not marked passed.
The final named warm profile measurement is recorded in the UI review; RSS
remains above the sub-200 MiB optimization objective.

Five fresh profile processes now exercise the real entry point. The ready app
frame was observed in 0.61–0.87 seconds after binding initialization; external
process lifetimes were 1.29–1.79 seconds. Timing scope and candidate identities
are retained in the UI review. Input responsiveness is not inferred.

Release acceptance still requires native input/accessibility/audio/device and
installer/lifecycle checks, the complete state matrix, Windows/macOS runners,
verified content permissions, a clean frozen candidate and coordinated artifact
review. Comparable RSS reduction and the sub-200 MiB objective remain unproven.
No public release, push or PR was performed.

## October 5 Quran interaction follow-up

The Quran header now uses a grouped Forui search popover for Surah, Juz, Hizb
and Ayah destinations, with bilingual intent/reference parsing and source-text
results. Study opens with a selection instruction, remains available while
choosing an ayah, and toggles closed from the same control. One collapse state
owns split-pane visibility and padding. Display tabs update while their popover
is open; loaded commentary and zoom hints respect reduced motion.

The [Quran follow-up](../ui-audit/2026-10-04/QURAN-FOLLOWUP.md) records regression,
composition, motion and comparable search-profile evidence. Search latency
improved in the measured Linux flow. RSS reduction and the sub-200 MiB objective
remain unproven. Native OS input/accessibility and unavailable platform checks
remain pending; the follow-up does not certify full release acceptance.

## October 6 Quran refinement

The [Quran refinement](../ui-audit/2026-10-04/QURAN-REFINEMENT-2026-10-06.md)
supersedes the prior empty Study opening rule. Study now selects the first
visible ayah when opened without a selection; selection/deselection restores
the pane's automatic visibility while honoring explicit collapse. Search rows
have one shared pointer/keyboard active result, inset spacing, readable Arabic
previews and sourced Surah/Juz/Hizb context. Verification and precise native
review scope are retained alongside the report; external release acceptance
requirements remain pending.

## October 6 Fortress refinement

The [Fortress refinement](../ui-audit/2026-10-04/FORTRESS-REFINEMENT-2026-10-06.md)
repairs Arabic sidebar placement and overlapping collapse chrome, removes the
duplicate header bookmark, and puts chapter/content search behind one visible
sidebar field. Compact typing, result opening, favorites and Ctrl+K have
regression coverage. Arabic title matching preserves the old catalog filter.
The latest app suite has 1,213 passing tests; focused tests, analysis, root
generation and the regular Linux build pass. The report retains the precise
128-capture runtime scope and remaining external release requirements.

## October 6 Hadith refinement

The [Hadith refinement](../ui-audit/2026-10-04/HADITH-REFINEMENT-2026-10-06.md)
replaces redundant result menus with Share, keeps explicit negative source
rulings in destructive styling, and requires those rulings in shared images.
Copied text includes the full ruling. Missing narrator placeholders and their
options are omitted; share cards use compact attribution beneath the source
text. Optional commentary failures name the failed section and support Retry
or deselection before image export.

Current upstream Node source returns textual rulings and exposes degree IDs
only through the search catalog. The Dart port does not drop a per-result typed
degree. The report records the pinned source comparison, regression results and
88-capture Linux review scope. The current app suite has **1,223 passing tests**;
17 focused Hadith tests, analysis without errors or warnings, localization
generation and the ordinary Linux debug build also pass. Native OS
input/accessibility and unavailable platform release requirements remain pending.

## October 6 Hadith card cleanup

The [card cleanup](../ui-audit/2026-10-04/HADITH-CARD-CLEANUP-2026-10-06.md)
removes hover glow, the thick selected-card edge, visible result-number headings,
and repeated source headings. Selection uses a uniform one-pixel border and flat
neutral fill; keyboard focus and result accessibility labels remain available.
Results, embedded cards, wide details, compact details and the preview agree.
The current app suite passes **1,224 tests**, including **101 Hadith tests**.
Analysis has no errors or warnings. Native confirmation and build details are
recorded with the report, with the existing platform/input limitations retained.

## October 6 Fortress and Hadith follow-up

The [UI follow-up](../ui-audit/2026-10-04/FORTRESS-HADITH-FOLLOWUP-2026-10-06.md)
adds the missing resize gap and labeled compact Fortress tabs. Expanded thikr
previews show complete text and sourced benefits, with independent sharing;
the share card has compact attribution and recoverable optional details.
Hadith Share, Copy and bookmarks sit inside the result footer. Alternate Hadith
selection now resolves the opened record and retains the original search snapshot.

Impeccable inspection caught and repaired inherited one-line clipping in expanded
thikr text. Exact virtue/source duplicates are suppressed only in browse/share
display; bundled religious fields remain intact. The follow-up records 168 final
Linux compositions, refreshed Fortress goldens and the precise native proof scope.
All **1,234 app tests** and **126 focused tests** pass. Analysis has zero errors
and warnings; localization generation and both Linux debug builds pass.
The normal entry point is restored. Existing native input/platform and wider
release acceptance requirements remain pending.

## October 6 final reported fixes and PR preparation

The [final fixes review](../ui-audit/2026-10-04/FINAL-FIXES-2026-10-06.md)
covers player-to-Quran routing, compact ayah actions, route-owned reader keys,
always-visible sourced فضل, share typography and repetition options, manual
location recovery, prayer-row height, time wording, and About link consistency.

All **1,249 app tests** pass. Full app analysis has zero errors and warnings.
Generation, local package checks, six release-validation tests and the ordinary
Linux debug build pass. The [verification record](../ui-audit/2026-10-04/final-fixes-verification.json)
retains counts, commands, source hashes and limitations. Impeccable confirmation
passed in both languages at normal wide dark and extra-large compact light;
eight final confirmation captures have no Flutter errors. Seven stepped native
keyboard observations prove the scoped page/selection controls. Complete native
Tab traversal and screen-reader certification remain outside that proof.

The accumulated implementation is ready for PR submission and CI verification.
The Dorar 0.6 adoption document remains a future migration plan. Unavailable
Windows/macOS machines, the broader native release checks, verified bundled
database redistribution terms and the unproven RSS objective remain release
gates. These fixes do not certify the full launch acceptance plan.
