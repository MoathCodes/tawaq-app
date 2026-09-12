Tawaq code-health audit — 9 September 2026

**Verdict: the concern is partly validated. There are harmful abstractions, unfinished scaffolding, obsolete code, and synchronization bugs. The evidence does not justify calling the entire project slop or rewriting it wholesale.** Source alone cannot reliably identify AI authorship; this audit judges observable behavior and maintenance cost.

The clearest example of the concern is accessibility: a simple control passes through feature helpers, a generic helper with multiple modes, and another wrapper. Along that path, the wrappers discard the control's accessibility actions. The extra structure is actively harmful, not merely verbose.

This is an audit of the current working tree, including pre-existing uncommitted work. Production source, existing tests, settings, and generated outputs were not changed. The new files in this directory are the report, executable reproductions, and captured results.

**Confirmed findings, in priority order:**

1. **High: the shared action wrapper removes accessible activation.**

   [MergedActionSemantics](/home/moath/Projects/tawaq-app/lib/core/widgets/merged_action_semantics.dart:38) sets `excludeSemantics: true`, supplies a button role, and supplies no `onTap`. The child's action disappears. A widget test wrapping a working TextButton verifies that the resulting node has no `SemanticsAction.tap`.

   Fan-out includes shell sidebar actions, desktop window controls, the theme-mode button, and settings controls using `SettingsSemantics.iconAction`. The latter traverses `SettingsSemantics.iconAction → SemanticsWrappers.labeledControl → MergedActionSemantics → Semantics`. The feature helper passes the same widget as both `child` and `iconAction`; the generic helper selects a different implementation based on which optional argument is present. None of this preserves the required activation contract.

   Simplification: preserve the existing button's semantics wherever possible. Where an explicit replacement node is necessary, make its action part of a small, explicit component contract. Remove the redundant forwarding layers during that repair. Test activation, not merely whether the label exists.

2. **High: Quran field wrappers erase editable-field semantics.**

   [AyahSearchSelector](/home/moath/Projects/tawaq-app/lib/feature/quran/presentation/widgets/selectors/ayah_search_selector.dart:74) wraps its autocomplete with `excludeChild: true`. Both layouts of `AyahInSurahSelect` use the same pattern. [The shared helper](/home/moath/Projects/tawaq-app/lib/core/a11y/semantics_wrappers.dart:51) excludes the child and does not replace text editing actions or the field role. The Quran helper cannot even accept an activation callback.

   The reproduction uses the actual Quran helper around a TextField and confirms that `SemanticsAction.setText` is lost. This establishes the wrapper defect; a native screen-reader session was not run. The production autocomplete and ayah-entry call sites have the same exclusion behavior. Review the other Quran selector call sites individually: not every use of the helper excludes its child.

   Simplification: let editable controls own their semantics; add labels without suppressing their actions. Do not use one boolean-heavy helper to represent buttons, editable inputs, and read-only text.

3. **Medium: minute throttling leaves current-prayer state stale after a timeline change.**

   [scheduleCurrentPrayer](/home/moath/Projects/tawaq-app/lib/feature/prayer/presentation/provider/prayer_schedule/prayer_schedule_provider.dart:16) watches the minute bucket but only reads `prayerDayProvider`. [The bucket](/home/moath/Projects/tawaq-app/lib/feature/prayer/presentation/provider/prayer_day.dart:183) contains only epoch minutes. A new prayer timeline within the same minute is therefore invisible to this derived provider.

   Reproduction: calculate Jeddah's schedule in `Asia/Riyadh` for 2026-09-09, observe it one minute after Dhuhr, then publish a recalculation with Dhuhr adjusted by 30 minutes at the same instant. The domain function correctly returns the pre-Dhuhr slot (`Prayer.sunrise`); the provider still returns Dhuhr. The current-prayer consumer is `PrayerScheduleList`.

   This is a synchronization defect introduced by an optimization layer. Preserve throttling of clock ticks while also observing changes to the underlying bundle/timezone. `sunnahTimeLabels`, Fortress recommendations, and the hero-card projections use related watch/read patterns and must be considered in the repair. Only the schedule case was reproduced; do not assume identical behavior for consumers that also watch settings.

4. **Medium: keyboard navigation skips the first or last Hadith when no result is selected.**

   [selectAdjacentResult](/home/moath/Projects/tawaq-app/lib/feature/hadith/presentation/provider/hadith_provider.dart:362) first chooses the correct boundary index for a null selection, then applies `delta` anyway. With three results, both next and previous select the middle item. Both directions were reproduced through the controller after an actual mocked search, without directly assigning controller state.

   `HadithPage` wires its next/previous shortcuts to this method. Fix the absent-selection branch so it selects the boundary without incrementing it. This is a local logic bug; it does not require a new navigation abstraction.

5. **Medium: immediate searches leave an earlier debounce timer alive.**

   [setFilters](/home/moath/Projects/tawaq-app/lib/feature/hadith/presentation/provider/hadith_provider.dart:133) cancels the timer only when scheduling another delayed search. The immediate branch calls `search()` without cancellation, and `search()` does not cancel it either.

   Reproduction: perform a search, change a filter, then immediately reset filters. Two repository searches occur instead of one. The delayed second request also re-enters hard loading and discards the current result list. Filter reset and query submission paths can both intersect pending filter work. Make immediate search execution consume/cancel pending scheduled work, and retain a regression test covering the transition.

6. **Low: there are definite leftovers, including tests of disconnected production logic.**

   - [searchAyahNumbers](/home/moath/Projects/tawaq-app/lib/feature/quran/domain/services/ayah_number_search.dart:2) has no production caller. Its only external references are in `quran_division_ux_test.dart`. The current ayah picker uses numeric text entry, and Quran text search uses the Mushaf controller. These tests preserve an unused ranking implementation rather than verify the current picker.
   - [ShortcutIndicatorGroup](/home/moath/Projects/tawaq-app/lib/core/widgets/shortcuts/shortcut_indicator.dart:90) has no caller in the repository source/tests searched. The rest of that file is used; remove the class, not the file.
   - [Translation.withSourceMetadata](/home/moath/Projects/tawaq-app/lib/feature/quran/data/models/translation.dart:25) has no caller. The repository constructs the decorated Translation directly.

   Remove these specific leftovers and the obsolete ranking tests, replacing coverage with current picker behavior where needed. Public declarations can escape unused-private-member diagnostics, so a clean analyzer would not disprove this finding.

7. **Medium before release: the About feature still presents template content.**

   [about_info.dart](/home/moath/Projects/tawaq-app/lib/feature/about/data/about_info.dart:14) is used by the real About UI. It contains `Your Name`, `https://example.com`, `github.com/example/tawaq`, and `hello@example.com`. The website description says `tawaq.app` while its actual stored URL is `example.com`. Tapping a link copies that URL through `_openAboutLink`; it does not navigate to it. Version text is separately hardcoded in the header and facts list, apart from the package version.

   This is concrete unfinished scaffolding. The feature also maintains a separate `AboutText`/`AboutStrings` localization mechanism and several row models for one static page. Consolidating localization/version ownership is worthwhile; replacing every row model is lower priority than removing visible placeholders. Use verified project details or omit unavailable entries.

8. **Medium: Riverpod analysis has conflicting configuration and a reproduced plugin startup failure.**

   [analysis_options.yaml](/home/moath/Projects/tawaq-app/analysis_options.yaml:19) contains both the older analyzer plugin list and a top-level plugin entry pinned to `riverpod_lint: 3.1.0`. `pubspec.yaml` requests `riverpod_lint: ^3.1.8`. During `fvm dart analyze docs/audits/code-health-2026-09-09/repro_test.dart`, the plugin manager failed to resolve its environment: the pinned Riverpod plugin requires `analyzer_plugin ^0.13.10`, incompatible with the plugin manager's `analysis_server_plugin ^0.3.8` dependency chain.

   This is an actual tooling failure, not a suggestion to upgrade indiscriminately. Reconcile the plugin configuration with the pinned SDK and resolved dependency versions, then verify that Riverpod diagnostics execute. The standalone run still emitted ordinary Dart lint diagnostics; that does not establish that the Riverpod checks ran.

**What the evidence does not support:**

- Line count is not a quality verdict. Under a stated, reproducible scope, the current app `lib/` contains 383 non-generated Dart files and 56,573 nonblank lines; root `test/` contains 137 files and 21,628 nonblank lines. These counts include comments and exclude `.g.dart`, `.freezed.dart`, `.gen.dart`, and `app_localizations*`. Local packages have their own code, data, and comments. This is a different scope from the supplied 84,695 figure, not a correction of it.
- A basic import/export/part reachability scan from `lib/main.dart` found only the ayah-number-search file unreachable among handwritten app Dart files. Reachable does not mean every declaration or branch is used, but there is no evidence here of a large abandoned app implementation.
- Of 30 root-app declarations matching `abstract class` or `abstract interface class`, 27 are Freezed model inputs. The remaining three are the navigation base, prayer alert channel, and tafsir data-source contract. Static `abstract final` namespaces are a separate category. This is not a repository-wide epidemic of interface/implementation pairs.
- `ITafsirDataSource` supports two real SQL schemas. `TafsirRepository` owns source reuse and database access. These layers do useful work.
- The persisted split-pane wrapper addresses actual behavior in the resolved Forui 0.25.0 source: `FResizable.didUpdateWidget` marks changed region children dirty and the next layout resets them. Its region caching is justified by that dependency behavior. This audit does not claim a measured speed improvement.
- Saved settings versus unsaved text drafts are legitimately different state. Likewise, native audio facts and logical recitation state serve different contracts. `RecitationSession` commits logical state and the Riverpod adapter projects it. Removing those distinctions merely because several classes exist would risk replacing clear ownership with synchronization scattered through widgets.

There are concentrated maintenance hotspots: the recitation state machine is 1,819 physical lines, the recitation provider 1,806, and the seek bar 1,376 in this checkout. They deserve behavior-focused review, but size alone is not a confirmed defect, and splitting them into more files would not necessarily reduce complexity.

**Verification and limits:**

- `fvm flutter test`: all **975 tests passed** before adding the audit reproductions.
- `fvm flutter analyze --no-fatal-infos`: **2 errors, 3 warnings, 175 infos**. The errors and warnings are in pre-existing untracked audit/probe files under `docs/audits/`, not production `lib/`. Analysis therefore failed; the result is not a clean bill of health. See `analysis.log`.
- A subsequent targeted `fvm dart analyze` emitted a Riverpod plugin initialization failure, as detailed in finding 8. Do not interpret the baseline diagnostics as proof of complete plugin coverage.
- `fvm flutter test docs/audits/code-health-2026-09-09/repro_test.dart`: **six assertion failures reproduce five behavioral defects**, including both directions of the Hadith navigation bug. See `repro.log`. These intentionally failing tests are outside the default `test/` suite. They assert intended behavior and can become regression tests during repairs.
- Broad structural scans covered handwritten app Dart and selected local-package surfaces. Detailed reading covered shared semantics/layout, Hadith search/state/repository flows, prayer projections, settings/drafts/storage, Quran selection/tafsir/translation, recitation ownership, and About. This is not an exhaustive branch-by-branch certification. Package test suites, native accessibility, religious corpus accuracy, and native audio runtime behavior were not independently validated. No performance improvement is claimed.
- Existing application edits were preserved. No code generation was necessary or performed.

The cleanup policy I recommend is concrete: **reject forwarding layers without an actual invariant or behavior; reject two writable owners of the same fact without an explicit synchronization contract; delete superseded implementations with their obsolete tests; and require tests of the reachable interaction that an abstraction promises to preserve.** Do not prohibit classes indiscriminately. Prohibit structure whose maintenance cost exceeds the behavior it owns.

Repair accessibility first, then prayer invalidation and Hadith transitions. Delete verified leftovers and finish About. Review the large recitation components separately against their existing ownership contracts before proposing any redesign.
