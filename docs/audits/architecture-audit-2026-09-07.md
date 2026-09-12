# Architecture audit, 7 September 2026

The most expensive recurring problem is incomplete separation of ownership. Several refactors establish a named owner but leave its callers responsible for readiness, ordering, or synchronization. That creates more places to edit without removing the original coordination problem.

This audit maps problems and impact. It does not propose an implementation sequence or change production code. Baseline is `4f741fd` plus the existing working-tree changes, including the new audio interruption and explicit recitation-selection work. Historical issue descriptions are evidence of past symptoms, not proof that every symptom remains today.

| Priority | Root decision | Present impact | Evidence |
| --- | --- | --- | --- |
| High | Quran reference data is obtained through a visual reader controller | Recitation initialization, labels, bounds, and recovery depend on page-related readiness | Current source, repeated fixes, failed-readiness probe |
| High | Recitation state ownership moved without fully moving coordination | Seek, load, interruption, and effect changes still span the session and Riverpod adapter | Current source and incomplete TAW-64 contract |
| High, content integrity | Database file length acts as content version | Same-size corrections do not reach existing installations | Production service probe |
| Medium, correctness | Calendar selection stores a date without explicit follow-today intent | Cold-start fallback can remain selected after the configured timezone becomes available | Production provider probe |
| High, maintenance | Tests duplicate rules or enforce implementation shape | Green checks can coexist with the lifecycle defects and make structural cleanup harder | Existing tests and all three probes |

**1. The Mushaf controller is both a view controller and the app's Quran catalog.**

The shared provider constructs a keep-alive `MushafReaderController`. Its constructor starts initialization immediately. Therefore the precise current diagnosis is not that opening the Quran screen is required to start initialization. Recitation itself obtains the controller and awaits it.

The structural problem survives that fix. `ensureReady()` loads repository readiness, basmalah, juz, hizb, Surah metadata, and current page information before completing. Recitation needs canonical names and valid range bounds, but its readiness is tied to that entire sequence. A page-data failure can therefore prevent otherwise usable reference data from being treated as ready.

Sources: [controller construction](/home/moath/Projects/tawaq-app/lib/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart:11), [package initialization](/home/moath/Projects/tawaq-app/packages/mushaf_reader/lib/src/logic/mushaf_reader_controller.dart:98), [recitation initialization](/home/moath/Projects/tawaq-app/lib/feature/quran/presentation/providers/recitation_provider.dart:1711).

There is also a confirmed recovery defect. The package caches `_initFuture` with `??=` and never clears it after failure. `retryInitialization()` awaits the same failed future on the same retained controller. The probe made repository readiness fail once, called readiness again, and observed the identical failed future and only one repository call. Reopening controls does not repair that package contract.

The fan-out includes title-bar transport, recitation drawer, range editor, offline-file labels, OS media metadata, Surah/juz/hizb selectors, ayah search, notes previews, sharing, and study selection. Several widgets read synchronous controller caches; provider identity does not itself notify them when those caches become ready. The recitation initialization state now repairs rendering for guarded consumers, but leaves them relying on another subsystem's mutable caches.

Navigation adds another version of the same dependency. The recitation adapter contains a 30-attempt post-frame loop waiting for a PageController to attach. Meanwhile the Quran screen separately projects playback into study selection and scrolling. Those are concrete maintenance costs of mixing app-wide playback with mounted reader behavior. The frame count is not a wall-clock timeout; actual navigation failures were not reproduced in this audit. See [attachment waiting](/home/moath/Projects/tawaq-app/lib/feature/quran/presentation/providers/recitation_provider.dart:1682) and [mounted follower](/home/moath/Projects/tawaq-app/lib/feature/quran/presentation/screens/quran_screen.dart:82).

History makes the recurrence visible. `83ef2a4` fixed localized names across 16 files. `614f5ec` added restoration/first-play readiness coordination. [TAW-16](https://linear.app/tawaq/issue/TAW-16) is Done, while [TAW-62](https://linear.app/tawaq/issue/TAW-62) documents the subsequent missing-name and fallback-bound problem and remains In Review. The current code includes the readiness fix; this audit does not claim that its original Taha cold-start reproduction still fails.

The boundary to discuss is canonical Quran data versus visual reader state. Owning `mushaf_reader` matters because this can be resolved at the source rather than forcing every Tawaq consumer to implement readiness around the controller. The package already exposes `IQuranRepository`, so the discussion can start with existing capabilities.

**2. Recitation has one state writer, but coordination still crosses a wide public seam.**

`a267f6b` introduced `RecitationSession`, and this was useful: native observations, timeline state, and logical writes have a clearer owner. However, the current adapter still owns `_effectsTail`, initialization generations, SeekPipeline lifecycle, sleep timers, load execution, and repeated stale-result/suspension checks. The session exposes events, effects, timeline operations, and intermediate operations such as `prepareSeek`, `beginLoad`, and `installTimeline`.

Sources: [adapter fields and wiring](/home/moath/Projects/tawaq-app/lib/feature/quran/presentation/providers/recitation_provider.dart:391), [seek and effect coordination](/home/moath/Projects/tawaq-app/lib/feature/quran/presentation/providers/recitation_provider.dart:1041), [session interface](/home/moath/Projects/tawaq-app/lib/feature/quran/domain/recitation/recitation_session.dart:60), [seek pipeline](/home/moath/Projects/tawaq-app/lib/feature/quran/domain/services/recitation_seek_pipeline.dart:39).

A seek change requires understanding optimistic session state, timeout reconciliation, adapter queue order, suspension guards, effect order, and native-service behavior. A field being assigned only inside the session does not mean the session owns the decision about when that assignment is safe. The adapter still makes part of that decision.

At this baseline the provider file has 1,806 lines, the transition machine 1,819, and the session 466. These counts locate the work; size alone is not the finding. The finding is that the old coordination seam remains publicly traversed after another layer was added.

[TAW-64](https://linear.app/tawaq/issue/TAW-64) is marked Done, but its stated completion contract includes private transition/seek/ordering internals, removing the old public event/effect seam and test-only timeline injection, and reducing the adapter to wiring. Current source still exposes those elements. This is a partial architectural migration, not evidence that the session abstraction should simply be deleted.

Relevant earlier commits include `356eb9b` for alert yielding and seek hardening, `95a7973` for seek/resume work, `8bef4f5` for load hardening, and `b4a6e68` for further seek hardening. These establish repeated attention to the same area, not a count of independently reproduced bugs.

Affected flows are UI playback, OS media commands, pending seeks, repeats, gapless playback, restore, prayer interruptions, and Mushaf following. Keep native audio ownership and lease checks: they protect real competing playback clients. The question is where recitation-specific ordering belongs.

**3. Content installation mistakes byte length for identity.**

[AssetDatabaseService](/home/moath/Projects/tawaq-app/lib/core/database/asset_database_service.dart:17) uses `size:<length>` as its entire bundled database version. Existing copies are replaced only when that version changes or the file is missing. Tafsir and translation repositories both consume this service.

The probe created two valid SQLite databases with different stored values but identical byte lengths. After installing the first, a fresh service loaded the second bundle and still returned the first value. This is a confirmed production-code behavior, not a hypothetical hash collision. SQLite content can change without changing its allocated file size.

Impact: existing users can retain old religious commentary or translation data after a correction ships, while fresh installations receive the correction. No specific released religious-text discrepancy was asserted or discovered here; the installation contract is what the probe demonstrates.

`89d6423` introduced this as a fix for stale copies. It added version files and replacement machinery, but the chosen identity cannot distinguish the change it is meant to detect. The existing test deliberately makes the replacement database larger, so it misses this case.

Fortress uses an upstream commit when available and only falls back to file sizes. It shares the weak fallback, not the exact unconditional defect. See [Fortress version resolution](/home/moath/Projects/tawaq-app/lib/feature/muslim_fortress/data/repository/fortress_repository.dart:67). That distinction matters before changing shared installation policy.

**4. Calendar state cannot distinguish following today from a provisional date.**

[ScheduleSelectedDate](/home/moath/Projects/tawaq-app/lib/feature/prayer/presentation/provider/prayer_schedule/schedule_selected_date_provider.dart:15) initializes from the prayer day, then the shared clock, then device time. Its day-key listener explicitly ignores a transition whose previous key was zero. Consequently the initial configured prayer day cannot repair a provisional fallback date.

The probe seeded the shared clock at `2026-09-06 22:00 UTC`, before a prayer-day snapshot existed. It then supplied the Riyadh day key `20260907`, representing the same instant at 01:00 in Riyadh. The selected date remained September 6. This exercises the actual provider with controlled time inputs.

The model also uses date equality to infer follow-today behavior on subsequent rollovers. That works for tested normal midnight changes, but it has no representation for a provisional selection or a user's explicit intent. A future edit to hydration, timezone changes, or historical navigation must preserve these implicit rules.

`31ef8b8` established the current selected-date provider, and `4f741fd` replaced a 1970 fallback with `DateTime.now()`. That removes the visible epoch symptom while leaving first-readiness reconciliation unresolved. [TAW-65](https://linear.app/tawaq/issue/TAW-65) tracks calendar rollover work. Existing tests seed a valid day key before mounting, excluding the cold-start transition.

There is a related dependency concern in prayer projections. `scheduleCurrentPrayer`, `sunnahTimeLabels`, and Fortress recommendations watch a minute signal while reading the full prayer snapshot non-reactively. Their dependency is a clock bucket, although their result also depends on the configured timeline. Same-minute settings changes deserve explicit coverage before changing this design. This is a source-level concern, not another runtime-confirmed defect. See [schedule projection](/home/moath/Projects/tawaq-app/lib/feature/prayer/presentation/provider/prayer_schedule/prayer_schedule_provider.dart:16) and [minute signal](/home/moath/Projects/tawaq-app/lib/feature/prayer/presentation/provider/prayer_day.dart:188).

The shared clock and prayer-day computation are sound foundations worth preserving. The ownership problem is selection intent and dependency declaration, not centralized time calculation.

**5. Some tests protect copied behavior instead of production behavior.**

Several Quran tests define their own implementations explicitly described as mirrors. Examples include [range preset helpers](/home/moath/Projects/tawaq-app/test/feature/quran/range_dialog_preset_test.dart:9), [completion guards](/home/moath/Projects/tawaq-app/test/feature/quran/recitation_idle_guard_test.dart:10), `resume_after_alert_ab_loop_test.dart`, and `notes_flush_on_dispose_test.dart`. A production change can break while the copied helper remains green. Some comments still refer to controller methods that the session refactor moved or replaced.

The [session boundary test](/home/moath/Projects/tawaq-app/test/architecture/recitation_session_boundary_test.dart:35) counts `state =` occurrences and requires one exact callback spelling. It proves that textual shape, but not that all commands and asynchronous results pass through one ordering authority. It can also reject a behavior-preserving rewrite for purely syntactic reasons.

The initialization test checks UI states and a controller subclass whose `build()` starts in an already-failed state. That is useful targeted coverage, but it does not execute real controller initialization followed by package-level failure/retry. The passing suite therefore does not establish the recovery contract described in TAW-62.

There is good production-path coverage elsewhere, and the uncommitted range-dialog work adds more. This finding concerns the remaining mirrored tests and overly narrow architectural assertions, not the whole test suite. It compounds the earlier findings by making an incomplete fix easier to accept and structural changes harder to trust.

**What I would preserve.**

The shared audio lease model, the separation of persisted checkpoints from runtime selection, the single prayer clock and computation owner, bounded tafsir caches, and serialized note/recent-search writes all perform concrete work. The tafsir data-source interface also maps genuinely different database schemas. I found no basis to classify these as needless abstractions merely because they add types or files. The current working tree's removal of silent reciter fallbacks addresses an actual selection-ownership issue and should not be reported as an unfixed baseline bug.

**Verification and limits.**

Reviewed current owners and representative consumers across Quran/recitation, shared audio, prayer/calendar, persistence/bootstrap, Hadith, Fortress, and content installation, with local package source and relevant history. Linear's issue list was reviewed; TAW-62 and TAW-64 were read in full. This was an architectural audit with selective depth, not a line-by-line certification of every feature or platform.

Ran architecture checks, recitation initialization tests, session tests, and range preset tests: 30 passed. Ran three isolated probes against the actual controller/service/provider: all passed, with assertions confirming the problematic behaviors. The probes are retained in [2026-09-07-probes.dart](/home/moath/Projects/tawaq-app/docs/audits/2026-09-07-probes.dart) and can be run with `fvm flutter test docs/audits/2026-09-07-probes.dart`. They are diagnostic evidence, not desired-behavior regression tests to preserve after fixes.

No production files, generated outputs, dependencies, or Linear issues were changed. No full analysis/full-suite run or native desktop reproduction was performed. No performance improvement or RAM diagnosis is claimed; those require measurements of the affected runtime flow. Existing user changes were preserved.
