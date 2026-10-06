# Tawaq UI audit — Linear migration

[Linear parent TAW-94](https://linear.app/tawaq/issue/TAW-94/resolve-desktop-ui-findings-from-the-linux-audits) collects the migrated GitHub issues and new audit issues. All 31 findings have a destination.

## Migration coverage

Nine GitHub issues were migrated and fifteen additional issues were created under this tracker. Six existing Linear issues received missing findings and evidence. All 31 report findings are mapped below.

### GitHub migration

| Original | Linear |
| --- | --- |
| [#26](https://github.com/MoathCodes/tawaq-app/issues/26) | [TAW-95](https://linear.app/tawaq/issue/TAW-95/recitation-player-wraps-toggle-labels-into-vertical-letters-and) |
| [#27](https://github.com/MoathCodes/tawaq-app/issues/27) | [TAW-96](https://linear.app/tawaq/issue/TAW-96/save-while-listening-is-hidden-below-the-entire-downloaded-recitation) |
| [#28](https://github.com/MoathCodes/tawaq-app/issues/28) | [TAW-97](https://linear.app/tawaq/issue/TAW-97/prayer-calendar-jumps-and-resets-its-visible-dates-after-the-entrance) |
| [#29](https://github.com/MoathCodes/tawaq-app/issues/29) | [TAW-98](https://linear.app/tawaq/issue/TAW-98/quran-compact-layout-shrinks-the-reader-and-overflows-study-tabs-at) |
| [#30](https://github.com/MoathCodes/tawaq-app/issues/30) | [TAW-99](https://linear.app/tawaq/issue/TAW-99/hisn-al-muslim-chapter-list-is-clipped-to-a-sliver-at-the-minimum) |
| [#31](https://github.com/MoathCodes/tawaq-app/issues/31) | [TAW-100](https://linear.app/tawaq/issue/TAW-100/restored-paused-recitation-shows-a-000-total-beside-a-nonzero-saved) |
| [#33](https://github.com/MoathCodes/tawaq-app/issues/33) | [TAW-101](https://linear.app/tawaq/issue/TAW-101/hadith-search-fails-with-a-disposed-provider-error-and-exposes) |
| [#34](https://github.com/MoathCodes/tawaq-app/issues/34) | [TAW-102](https://linear.app/tawaq/issue/TAW-102/english-prayer-dashboard-says-player-analytics-and-1-days) |
| [#35](https://github.com/MoathCodes/tawaq-app/issues/35) | [TAW-103](https://linear.app/tawaq/issue/TAW-103/fortress-filter-says-no-favorites-even-when-bookmarked-chapters-exist) |

### UI/UX report coverage

| Finding | Problem | Linear | Handling |
| --- | --- | --- | --- |
| UI-01 | Quran study overflows and shrinks the reader at 800×600 | [TAW-98](https://linear.app/tawaq/issue/TAW-98/quran-compact-layout-shrinks-the-reader-and-overflows-study-tabs-at) | GitHub issue migrated |
| UI-02 | A collapsed study panel reappears in the stacked layout | [TAW-104](https://linear.app/tawaq/issue/TAW-104/keep-the-quran-study-panel-collapsed-in-the-stacked-layout) | New issue |
| UI-03 | Selecting an ayah resizes and repositions the reading page | [TAW-81](https://linear.app/tawaq/issue/TAW-81/polish-quran-study-labels-and-selected-ayah-actions) | Existing issue supplemented |
| UI-04 | An empty study panel claims space before an ayah is selected | [TAW-105](https://linear.app/tawaq/issue/TAW-105/make-the-unselected-quran-study-state-compact-and-actionable) | New issue |
| UI-05 | Recitation preference labels wrap one character per line | [TAW-95](https://linear.app/tawaq/issue/TAW-95/recitation-player-wraps-toggle-labels-into-vertical-letters-and) | GitHub issue migrated |
| UI-06 | The recitation drawer overflows the supported minimum window | [TAW-95](https://linear.app/tawaq/issue/TAW-95/recitation-player-wraps-toggle-labels-into-vertical-letters-and) | GitHub issue migrated |
| UI-07 | An unconfigured player does not explain how to start | [TAW-70](https://linear.app/tawaq/issue/TAW-70/require-explicit-reciter-and-range-selection-when-no-selection-exists) | Existing issue supplemented |
| UI-08 | Missing-location recovery restarts the entire onboarding flow | [TAW-106](https://linear.app/tawaq/issue/TAW-106/open-location-setup-directly-from-the-missing-location-recovery) | New issue |
| UI-09 | An Adhan modal interrupts incomplete onboarding | [TAW-107](https://linear.app/tawaq/issue/TAW-107/keep-adhan-alerts-from-interrupting-incomplete-onboarding) | New issue |
| UI-10 | Onboarding does not explain the length or shape of setup | [TAW-108](https://linear.app/tawaq/issue/TAW-108/make-onboarding-compact-and-explain-its-setup-stages) | New issue |
| UI-11 | Location setup exposes too many coordinate-level decisions at once | [TAW-109](https://linear.app/tawaq/issue/TAW-109/prioritize-city-selection-in-prayer-location-setup) | New issue |
| UI-12 | Appearance settings bury appearance below unrelated controls | [TAW-110](https://linear.app/tawaq/issue/TAW-110/put-appearance-controls-first-in-the-appearance-tab) | New issue |
| UI-13 | Light/dark controls use color-palette copy | [TAW-111](https://linear.app/tawaq/issue/TAW-111/distinguish-theme-mode-from-color-palette-in-settings-copy) | New issue |
| UI-14 | The five-prayer schedule is pushed below secondary content | [TAW-112](https://linear.app/tawaq/issue/TAW-112/keep-the-five-prayer-schedule-easy-to-scan-in-the-initial-view) | New issue |
| UI-15 | Prayer statistics are labelled “Player Analytics” in English | [TAW-102](https://linear.app/tawaq/issue/TAW-102/english-prayer-dashboard-says-player-analytics-and-1-days) | GitHub issue migrated |
| UI-16 | Fortress chapter browsing has almost no list height at 800×600 | [TAW-99](https://linear.app/tawaq/issue/TAW-99/hisn-al-muslim-chapter-list-is-clipped-to-a-sliver-at-the-minimum) | GitHub issue migrated |
| UI-17 | English Fortress interface chrome inherits RTL direction | [TAW-113](https://linear.app/tawaq/issue/TAW-113/use-locale-direction-for-english-fortress-controls-and-progress) | New issue |
| UI-18 | Fortress presents two search scopes without a clear relationship | [TAW-82](https://linear.app/tawaq/issue/TAW-82/polish-global-shell-affordances-and-informational-badges) | Existing issue supplemented |
| UI-19 | Hadith reserves an empty detail pane before there is a selection | [TAW-15](https://linear.app/tawaq/issue/TAW-15/modernize-the-hadith-screen-to-match-the-current-app-design-system) | Existing issue supplemented |
| UI-20 | Hadith filter help repeats specialist terms instead of explaining them | [TAW-15](https://linear.app/tawaq/issue/TAW-15/modernize-the-hadith-screen-to-match-the-current-app-design-system) | Existing issue supplemented |
| UI-21 | About exposes placeholder support and credit data | [TAW-14](https://linear.app/tawaq/issue/TAW-14/refresh-about-content-and-document-all-datacontent-sources) | Existing issue supplemented |
| UI-22 | About link arrows copy instead of opening the destination | [TAW-14](https://linear.app/tawaq/issue/TAW-14/refresh-about-content-and-document-all-datacontent-sources) | Existing issue supplemented |
| UI-23 | About spends most of its initial height on repeated brand information | [TAW-114](https://linear.app/tawaq/issue/TAW-114/make-about-version-and-support-easier-to-find) | New issue |
| UI-24 | The collapsed sidebar requires sighted users to recognize icons | [TAW-82](https://linear.app/tawaq/issue/TAW-82/polish-global-shell-affordances-and-informational-badges) | Existing issue supplemented |
| UI-25 | Follow-up: Hadith errors have technical copy and no local retry | [TAW-101](https://linear.app/tawaq/issue/TAW-101/hadith-search-fails-with-a-disposed-provider-error-and-exposes) | GitHub issue migrated; runtime follow-up pending |
| UI-26 | Follow-up: Recent-query removal depends on hover and announces “Clear all” | [TAW-115](https://linear.app/tawaq/issue/TAW-115/verify-and-repair-keyboard-access-and-scope-of-recent-query-deletion) | New issue; runtime follow-up pending |
| UI-27 | Follow-up: Reduced motion is not applied consistently | [TAW-86](https://linear.app/tawaq/issue/TAW-86/rethink-and-reimplement-app-animations-so-they-enhance-the-experience) | Existing issue supplemented; runtime follow-up pending |
| UI-28 | Follow-up: Reflection saving has no visible status | [TAW-116](https://linear.app/tawaq/issue/TAW-116/verify-and-expose-reflection-autosave-status-and-recovery) | New issue; runtime follow-up pending |
| UI-29 | Onboarding title bar stops short of both window edges | [TAW-117](https://linear.app/tawaq/issue/TAW-117/stretch-the-onboarding-title-bar-across-the-native-window) | New issue |
| UI-30 | Final onboarding schedule displays UTC instead of the configured timezone | [TAW-118](https://linear.app/tawaq/issue/TAW-118/display-configured-zone-prayer-times-in-the-onboarding-preview) | New issue |
| UI-31 | Onboarding's sparse two-column composition wastes its viewport | [TAW-108](https://linear.app/tawaq/issue/TAW-108/make-onboarding-compact-and-explain-its-setup-stages) | New issue |

### Reconciliation and evidence

- [Complete audit and evidence bundle](https://uploads.linear.app/3bc628fd-a63e-4e3a-84ee-6ccc848750d8/6f5d2a89-c117-4cf9-8439-873e9e1c95c3/daa04f2b-a5cf-4764-8d87-e7a5c4b16732): original Markdown report, 47 screenshots, two clips, and GitHub issue/comment snapshots.
- Thirty-six individual media files are attached to relevant issues and embedded where useful. Shared evidence is reused across related issues.
- The substantive GitHub #30 follow-up comment is preserved in TAW-99. Existing GitHub issues and their statuses were left unchanged.
- Existing Linear scope and statuses were preserved. Completed related work was linked without reopening it.
- UI-10 and UI-31 share TAW-108 because both concern onboarding composition and stage clarity.
- UI-25 through UI-28 retain their stated verification limits. Contextual screenshots do not establish their untested failure states.
- Both user-reported onboarding bugs are covered: TAW-117 for the inset title bar and TAW-118 for the configured-timezone preview mismatch. TAW-108 covers the sparse onboarding composition.
- This migration does not claim a fix, a performance improvement, or completion of the full profile audit in TAW-68.
