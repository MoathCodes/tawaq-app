# Agent Notes (Tawaq)

**Dependency versions:** Do not rely on version numbers in this file — they go stale. Read `pubspec.yaml` (and `pubspec.lock` if you need resolved versions) for the current constraints.

**Flutter SDK:** The exact SDK is pinned in `.fvmrc`. Use `fvm flutter ...`, `fvm dart ...`, or `fvm exec ...` for project commands.

## Code generation

This project relies heavily on code generation. From a fresh clone, after changing generated models in `packages/mushaf_reader`, or when doing a full regeneration, run:

```bash
fvm exec bash tool/codegen.sh
```

The script runs `build_runner` in `packages/mushaf_reader` first and then at the repository root. For app-only changes, `fvm dart run build_runner build` is sufficient.

Root `*.g.dart` and `*.freezed.dart` files are git-ignored. FlutterGen outputs under `lib/gen/`, localization outputs under `lib/l10n/`, and Hive's `lib/hive/hive_adapters.g.yaml` metadata are tracked. Regenerate after modifying:

- **Riverpod providers** (`@riverpod`, `@Riverpod(keepAlive: true)`) → `.g.dart`
- **Freezed models** (`@freezed`) → `.freezed.dart` + `.g.dart` for JSON
- **Hive adapters** (`lib/hive/hive_adapters.dart`) → `hive_adapters.g.dart`, `hive_registrar.g.dart`, and `hive_adapters.g.yaml`; adapters are registered in `lib/core/bootstrap/app_init_providers.dart`
- **Typed routes** (`@TypedGoRoute` in `lib/app/routing/route_provider.dart`) → `route_provider.g.dart` via `go_router_builder`
- **Assets/fonts** (`flutter_gen_runner`) → `lib/gen/assets.gen.dart`, `fonts.gen.dart`
- **Localization** (`fvm flutter gen-l10n`) → `lib/l10n/app_localizations*.dart` from `lib/l10n/app_*.arb`

## Architecture layers

### Feature structure

Seven top-level features live under `lib/feature/`. Most use a pragmatic subset of `data/`, `domain/`, and `presentation/`; do not add an empty layer merely for symmetry.


| Feature           | Route                  | Notes                                                                                          |
| ----------------- | ---------------------- | ---------------------------------------------------------------------------------------------- |
| `about`           | `/about`               | Sidebar activation opens a dialog; the route remains as a direct-navigation fallback          |
| `prayer`          | `/prayer`              | Hive completions + adhan_dart                                                                  |
| `quran`           | `/quran`               | mushaf_reader + SQLite tafsir/translations; uses `data/sources/` and `presentation/providers/` |
| `settings`        | `/settings`            | Persisted prefs                                                                                |
| `onboarding`      | `/onboarding`          | First-run state is feature-owned; the standalone screen is composed under `lib/app/onboarding/` |
| `hadith`          | `/hadith`              | Dorar API + local Hive favorites/recents                                                       |
| `muslim_fortress` | `/muslim_fortress`     | hisn_elmoslem package + SQLite assets                                                          |


```
lib/
  app/              # app composition: routing, shell, desktop lifecycle, onboarding screen
  core/             # feature-neutral infrastructure and reusable UI
  feature/<name>/
    data/           # persistence, remote/local sources, repositories when useful
    domain/         # models and pure business logic
    presentation/   # Riverpod state and widgets
```

The enforced direction is `app` → `feature`/`core`; `core` must not import app or feature code; feature domain code must not import its data or presentation layers. Cross-feature imports are forbidden except for settings-presentation reads of prayer state and the shrinking legacy allow-list in `test/architecture/dependency_boundaries_test.dart`. Remove an allow-list entry whenever its violation is repaired.

### Data flow pattern

There is no mandatory fixed chain. Use only layers that add behavior:

- Prayer completions flow from `PrayerDatabase` into Riverpod stores/actions; prayer-time business logic is in domain functions/services and `prayer_day.dart`.
- Quran uses `AssetDatabaseService` + sources/repositories + providers.
- Hadith and Muslim Fortress use repositories that coordinate their package clients, persistence/copying, mapping, caching, or error handling.
- Settings generally flow from persisted providers directly to widgets.

When adding a query, propagate it only through the layers that map, cache, validate, log, or orchestrate it. Do not add pass-through repository/service/provider methods.

## State management

- **Riverpod** with `riverpod_generator` for all async state. Use `@riverpod` for auto-dispose, `@Riverpod(keepAlive: true)` for singletons (databases, services).
- **flutter_hooks** / **hooks_riverpod** for local widget state. Prefer `HookConsumerWidget` when you need both hooks and providers.
- Widget hierarchy: `ConsumerWidget` (provider only) < `HookWidget` (hooks only) < `HookConsumerWidget` (both). `ConsumerStatefulWidget` appears in a few places (shortcut scopes, sliders).
- Generated names: class notifiers expose `*Provider` (e.g. `themeProvider`, `localeProvider`).

### Settings persistence pattern

Settings notifiers use `@JsonPersist()` (from `riverpod_annotation/experimental/json_persist.dart`) with a shared `SettingsStorage` (Hivez-backed, box `riverpod_persist`). Key notifiers:

- `LocaleNotifier` — async-hydrated, stores language code (`"en"` / `"ar"`) — lives in `lib/core/locale/locale_provider.dart`
- `PrayerSettingsNotifier` — async, coordinates, timezone, iqamah offsets, 24h toggle
- `AdhanSettingsNotifier` — async, adhan/iqamah sound and alert preferences
- `ThemeNotifier` — async, stores `AppPalette` + `ThemeMode` + `AppTextScale`
- `DesktopSettingsNotifier` — async, tray/window/startup preferences
- `OnboardingStateNotifier` — async, first-run/setup state
- **UI state** — screen/session prefs live in each feature (not a shared settings junk drawer):
  - `SidebarSettingsNotifier` — `lib/core/widgets/page_shell/sidebar_settings_provider.dart`
  - `PrayerAnalyticsSettingsNotifier` — `lib/feature/prayer/presentation/provider/prayer_analytics_settings_provider.dart`
  - `QuranScreenSettingsNotifier` + `RecitationSettingsNotifier` — `lib/feature/quran/presentation/providers/quran_screen_settings_provider.dart`
  - `HadithScreenSettingsNotifier` — `lib/feature/hadith/presentation/provider/hadith_screen_settings_provider.dart`
  - `FortressScreenSettingsNotifier` — `lib/feature/muslim_fortress/presentation/provider/fortress_screen_settings_provider.dart`
  - `SettingsScreenSettingsNotifier` — active settings tab key string (`settings_screen_settings_provider.dart`)
- `PrayerAnalyticsPrefs` — lives under `lib/feature/prayer/data/models/` (owned by prayer analytics)

Common internal pattern: a `_commit()` helper guards against unhydrated state, applies a transform, avoids no-op writes, and logs the changed field. Persisted notifiers await `persist(...).future` in `build()` and use `kSettingsPersistForever` or the equivalent `StorageOptions(cacheTime: StorageCacheTime.unsafe_forever)`. Use `flushPersistedValue`/notifier `flush()` at kill boundaries where the durable write must complete before proceeding.

Import concrete settings providers directly (`prayer_settings_provider.dart`, `theme_settings_provider.dart`, `locale_provider.dart`, etc.). Feature screen settings import from their feature (`quran_screen_settings_provider.dart`, etc.). Cross-feature prayer time reads import `prayer_day.dart` directly (`effectivePrayerSettingsProvider` / `prayerDayProvider`).

## Routing

Typed **go_router** setup in `lib/app/routing/route_provider.dart`:

- `@TypedGoRoute` / `@TypedShellRoute` codegen → `route_provider.g.dart`
- `appRouterProvider` — root `GoRouter`, initial `/prayer`
- `AppShellRoute` wraps nested navigator in `PageShell`
- `kMainRoutes` (prayer, quran, hadith, muslim_fortress) + `kSecondaryRoutes` (settings, about)
- `OnboardingRoute` at `/onboarding` (standalone, outside shell)
- `QuranRoute(page: ...)` and `SettingsRoute(tab: ...)` keep live page/tab state in the URL while persisted values act as restore checkpoints
- Navigation: typed `.go(context)` / `.replace(context)` on route classes; sidebar and bottom navigation consume the route constants

## Storage

- **Hivez** (`hivez_flutter`) for structured local data. Adapters live in `lib/hive/hive_adapters.dart`. Main boxes: `prayer_completions`, `prayer_completions_meta`, `hadith_favorites`, `hadith_recent_searches`, `quran_ayah_notes`, and `riverpod_persist`.
- **SQLite** (`sqlite3` + bundled `.db` files) for read-only reference data. `AssetDatabaseService` version-copies Quran databases from `assets/database/` into app documents and caches open connections. `FortressRepository` separately version-copies the databases from `packages/hisn_elmoslem/assets/database/` before opening `HisnClient`.

## Theming & styling

### Forui (primary UI library)

Forui is the primary UI system (with Material bridges where needed; see `pubspec.yaml`). Access theme via:

- `context.theme` → `FThemeData` (from forui's `FThemeBuildContext` extension)
- `context.theme.colors` → `FColors`
- `context.theme.isDark` → `bool` (custom extension checking `colors.brightness`)
- `FTheme.of(context)` → alternative explicit lookup (same as `context.theme`)
- `selectStyle()` — custom select styles in `lib/theme/select_style.dart`; button styling uses `context.theme.buttonStyles` plus `windowControlButtonStyle()` / `closeButtonStyle()` in `lib/theme/button_styles.dart` where needed

### FColors — key property reference

Core slots: `background`, `foreground`, `primary`, `primaryForeground`, `secondary`, `secondaryForeground`, `muted`, `mutedForeground`, `destructive`, `destructiveForeground`, `error`, `errorForeground`, `border`, `barrier`, `card`.

Utility methods: `hover(Color)` derives a hover variant, `disable(Color)` derives a disabled variant at `disabledOpacity`.

### Theme palette system

The app supports 2 palettes, each with light + dark variants:


| `AppPalette` | Source                                                                   |
| ------------ | ------------------------------------------------------------------------ |
| `manuscript` | Custom `ManuscriptTheme` in `lib/theme/custom_themes.dart` (default) |
| `neutral`    | `FTheme.neutral` (Forui built-in)                                        |


Legacy persisted palette names (blue, zinc, …) map to `manuscript` via `appPaletteFromJson`.

Resolution: `resolveColorScheme(AppPalette, ThemeMode, {touch})` → `_palettesData` map → `FThemeData`. Then `buildAppTheme()` in `lib/theme/app_theme_builder.dart` injects `AppRadii`, `AppDurations`, `AppTabsStyles`, scaled typography, and `IBMPlexSansArabic` as the app-wide font. Touch vs desktop density is chosen by `_isTouchThemePlatform()` in the same file. `appThemeDataProvider` supplies the Material bridge/appearance theme, while `appThemeWithTextScaleProvider` supplies the scaled `FTheme` wrapper.

### Custom extensions on FThemeData

Defined in `lib/theme/theme_extensions.dart`:

- `context.theme.radii` → `AppRadii` (xs, sm, md, lg, xl, full)
- `context.theme.durations` → `AppDurations` (instant, fast, normal, slow, slower)
- `context.theme.tabs` → `AppTabsStyles` (standard, compact, primary)

### Tabs

Feature tab UI uses Forui `FTabs`. Three themed variants live in `lib/theme/tabs_styles.dart` (generated with `dart run forui style create tabs`, then split into variants):

| Variant | Look | Use for |
| ------- | ---- | ------- |
| `standard` | Muted track, raised `background` indicator. Installed as `FThemeData.tabsStyle`, so a bare `FTabs` gets it | Page/card-level tabs (hadith side panel, hadith filter form, prayer trend analysis, fortress browse sidebar, settings) |
| `primary` | Recessed `background` track, indicator tinted `primary` @18% with a `primary` @55% border | Tabs on a `secondary` surface, where the default track would sit within one lightness step of the card (Quran study panel) |
| `compact` | `primary`'s exact colours at a smaller scale — `body.xs`, 28px min height, 2px padding, `spacing: 0` | Tab bars acting as controls, where the content renders elsewhere and labels may be icon-only (Quran header mushaf layout, fortress dua insights, range repeat dialog) |

`compact` and `primary` share one decoration pair, so a colour change to one applies to both; only density differs. All variants round the track and indicator with `radii.md`.

Opt into a non-default variant by passing the style directly — `FTabsStyle` is itself an `FTabsStyleDelta`:

```dart
FTabs(style: context.theme.tabs.primary, children: [...]);
```

**Never hand-roll a segmented control** from `FButton` rows. If the bar controls state rendered elsewhere, give each `FTabEntry` a `SizedBox.shrink()` child; `compact` sets `spacing: 0` so no gap is left behind. When such a bar sits in a `Row` (unbounded width), wrap it in `IntrinsicWidth` — the tabs then size to twice their widest label, giving equal-width segments.

`SettingsScreen` still drives a Material `TabBar`/`TabBarView` pair directly, because `CenteredViewportShell` needs the bar and the content in separate slots. It reads `context.theme.tabsStyle`, so it tracks `standard` automatically.

### Spacing & responsive layout

- Spacing uses `AppSpacing` constants (from `lib/theme/spacing.dart`): `xs` (4), `sm` (8), `md` (12), `lg` (16), `xl` (24), `xxl` (32), `xxxl` (48). Fixed logical pixels — no screen-based font scaling.
- **Viewport breakpoints** — Forui `context.theme.breakpoints` (`FBreakpoints`: sm 640, md 768, lg 1024, xl 1280, **xl2 1536**). Helpers in `lib/core/layout/responsive.dart`: `isAtLeast`, `isLessThan`, `responsiveValue`, `contentWidth`, `responsiveColumnCount`.
- **Container breakpoints** — when layout depends on allocated width (split panes, sidebars, dialogs), use `LayoutBuilder` and compare `constraints.maxWidth` to breakpoints.
- **Rule of thumb:** viewport breakpoints for page-level mode switches; container breakpoints for split panes, dialogs, and dense forms.

#### Layout helpers (`lib/core/layout/`)


| File                               | API                                                                                                             | Used by                       |
| ---------------------------------- | --------------------------------------------------------------------------------------------------------------- | ----------------------------- |
| `responsive.dart`                  | Viewport helpers (`isAtLeast`, `isLessThan`), container helpers (`isContainerAtLeast`, `responsiveValueForWidth`), `responsiveValue`, `contentWidth`, `responsiveColumnCount`, `FBreakpoint` enum | All features                  |
| `split_pane_constraints.dart`      | `kStudyPanelMinExtent` (320), `kMainPaneMinExtent` (480), `kMushafPaneMinExtent` (400), split gating, extent resolution, and `FResizable` normalization | Hadith, Quran study, Fortress |
| `persisted_horizontal_split_pane.dart` | `PersistedHorizontalSplitPane` — `FResizableRegion.flex` split that persists a **ratio**; stable regions across rebuilds | Hadith, Quran study, Fortress |
| `collapsible_horizontal_split_pane.dart` | `CollapsibleHorizontalSplitPane` (+ `.feature(...)` factory) — animates between the persisted split and a collapsed edge peek tab | Hadith, Quran study, Fortress |
| `responsive_horizontal_split.dart`   | `ResponsiveHorizontalSplitGate` — shared `canUseHorizontalSplit` gating; the feature supplies both branches | Hadith, Quran study, Fortress |
| `viewport_dialog_constraints.dart` | `dialogConstraints()`, `selectPopoverPortalConstraints()`                                                       | Dialogs, Quran selectors      |
| `responsive_field_row.dart`        | `ResponsiveFieldRow` — column below 640px, row above                                                            | Settings forms, wizard        |
| `lazy_tab_content.dart`            | `LazyPanelContent.tab` / `LazyPanelContent.indexed` — defer tab/panel build until first selected | Settings, Hadith panels    |
| `side_panel_ui_state.dart`         | Default persisted side-panel ratios/collapse state shared by feature models | Hadith, Quran study, Fortress |


**FResizable split-pane convention:** prefer `ResponsiveHorizontalSplitGate` → `CollapsibleHorizontalSplitPane.feature(...)` over hand-rolled `FResizable`. Pattern: gate checks `canUseHorizontalSplit` → feature factory wires `resolveFeatureSplitExtents()` → `FResizableRegion.flex` regions inside a `Directionality(textDirection: TextDirection.ltr)` (consistent resize handles in RTL); restore user `Directionality` inside each region. Side size is persisted as a **ratio** (0..1, not pixels) via the feature screen-settings notifier on `onResizeEnd`, so panels keep their share across monitor sizes. Collapsed state is a separate persisted bool per screen.

**Split gating:** use `ResponsiveHorizontalSplitGate` (or inline `canUseHorizontalSplit` + `LayoutBuilder`) before rendering a horizontal split. Its builder receives `useSplit`; each feature owns the narrow fallback. Quran and Fortress stack both panes, while Hadith folds search/filter controls into its single main column.

### Text scaling

Two independent scales — do not use `.sp` or screen-based scaling:

- `AppTextScale` — four app-UI steps (0.9–1.2×), applied via `buildAppTheme` and persisted in `ThemeNotifier`
- `mushafZoom` — continuous Quran reading boost (0.85–1.15×), applied via `buildQuranMushafStyle` and persisted in `QuranScreenSettingsNotifier`. The mushaf subtree uses `TextScaler.noScaling` so the two scales remain independent. The JSON key remains `quranTextScale` for migration compatibility.

### Theme-adaptive color patterns

When colors need to represent a hierarchy (best→worst, active→inactive), use `Color.lerp` between theme colors instead of hardcoded hex values. Example from `CompletionStatusUi.getBadgeColor`:

```dart
.jamaah => colors.primary,
.onTime => Color.lerp(colors.primary, colors.mutedForeground, 0.35)!,
.late   => Color.lerp(colors.primary, colors.mutedForeground, 0.65)!,
.missed => Color.lerp(colors.primary, colors.mutedForeground, 0.85)!,
```

This adapts automatically to every theme palette. **Never hardcode status/accent colors.** Exception: `PrayerHeroHeader` uses fixed per-prayer gradient pairs for visual identity; sunnah times use theme-adaptive `Color.lerp` instead.

## Scroll behavior

Defined in `lib/core/widgets/tawaq_scroll_behavior.dart`:

- `TawaqAppScrollBehavior` — app-wide via `MaterialApp.scrollBehavior` in `main.dart`. Thin auto-hiding thumb only when `isMeaningfulScroll()` (min 512px overflow, 8% of viewport, and a useful thumb/track ratio).
- `tawaqScrollbarTheme()` — thin thumb, no track (`main.dart`). Theme sets `thumbVisibility: false` so the thumb fades out shortly after scrolling stops; `_MeaningfulScrollbar` wraps eligible scrollables with `RawScrollbar` using `kScrollbarTimeToFade` / `kScrollbarFadeDuration`.

## App shell & desktop

### PageShell (`lib/app/shell/`)

- **Sidebar** ≥ sm (640px); **bottom nav** < sm (640px)
- Sidebar collapse persists via `sidebarSettingsProvider` in `lib/core/widgets/page_shell/sidebar_settings_provider.dart`; while hydration is pending it falls back to collapsed below lg (1024px), and resizing from desktop width into that range auto-collapses it
- **Custom title bar:** 52px drag strip with `WindowControls` + `window_manager.startDragging()`
- `ShellShortcutScope` — global keyboard shortcuts (desktop only)
- `NonSelectable` on chrome (sidebar, app bar, window controls)
- `ShellBottomNavigationBar`, `ShellAppBar`, `ShellA11y` labels

Desktop lifecycle, tray, window control, and prayer-alert composition lives under `lib/app/desktop/`; feature-neutral desktop utilities remain under `lib/core/desktop/`.

### Desktop selection (`lib/core/widgets/desktop_selection.dart`)

- `DesktopSelectionArea` — `SelectionArea` on desktop only
- `ScopedSelectableText` / `ScopedSelectableRichText` — selectable on desktop, plain elsewhere
- `NonSelectable` — `SelectionContainer.disabled` for chrome/buttons

### Keyboard shortcuts (`lib/core/shortcuts/`)

Flat `ShortcutDef` catalog in `app_shortcut.dart` → `ShellShortcutScope` in `lib/app/shell/` (`invokeGlobalShortcut` in `lib/app/shortcuts/`) + `AppShortcutScope` for route/contextual handler maps. `useRegisterAppSearchFocus` registers the active Ctrl/Cmd+K target. UI helpers live in `lib/core/widgets/shortcuts/`.

### Accessibility

- `MergedActionSemantics` — single semantics node for icon-only shell/shared controls (not page body content)
- `ShellA11y` — localized labels for shell nav, window controls, theme toggle
- Shared wrappers are exported from `lib/core/a11y/a11y.dart`; feature/shell label modules are `shell_a11y.dart`, `prayer_semantics.dart`, `quran_semantics.dart`, `hadith_accessibility.dart` (not `hadith_semantics.dart`), `fortress_a11y.dart`, and `settings_semantics.dart`
- **Tooltip rule:** any size-constrained widget (no room for a label, or the label alone can't fully explain the widget — e.g. an icon-only button) **must** be wrapped in `FTooltip` with a descriptive tooltip string. This applies even when a short label is present if that label alone is ambiguous without context.

## Core infrastructure


| Module      | Location                                    | Purpose                                            |
| ----------- | ------------------------------------------- | -------------------------------------------------- |
| App composition | `app/`                                  | Routing, shell, desktop lifecycle/alerts/tray, onboarding screen |
| Locale      | `core/locale/locale_provider.dart`          | Persisted language code                            |
| Logging     | `core/logging/logger_provider.dart`         | `loggerProvider` → shared `Logger`                 |
| Asset DB    | `core/database/asset_database_service.dart` | SQLite copy-from-assets                            |
| Commentary  | `core/commentary/`, `core/text/`            | Shared Arabic normalization + rich text rendering  |
| Platform    | `core/utils/platform.dart`                  | `isDesktopPlatform` (Linux/Windows/macOS, not web) |
| App clock   | `core/utils/app_clock_provider.dart`        | Shared 1 Hz wall clock; override this in time-based tests |
| Hijri       | `core/utils/hijri_format.dart`, `feature/prayer/presentation/provider/hijri_provider.dart` | Formatting plus day/locale-scoped prayer UI provider |
| Audio       | `core/audio/`                               | Shared player, lease arbitration, tracks, and playback state |
| Bootstrap   | `core/bootstrap/app_init_providers.dart`    | `appBootstrapReadyProvider` (Hive + desktop); Dorar lazy on Hadith open |


### Arabic text normalization (`lib/core/text/`)

Two normalizers — do not mix them:

| Function | File | Use for |
| -------- | ---- | ------- |
| `normalizeArabicForSearch` | `arabic_search_normalize.dart` | **Search / filter matching** — fold alef variants (أ إ آ ٱ → ا), ta marbuta, alef maksura, strip diacritics and tatweel. Apply to **both** query and candidate text. Helpers: `arabicSearchContains`, `arabicSearchStartsWith`. |
| `ArabicTextNormalizer.normalize` | `arabic_text_normalizer.dart` | **Display typography** for parsed commentary/tafsir segments (punctuation, honorifics, brackets) — not for search. |

**Rule:** any app-side Arabic search or filter (surah/juz/hizb selectors, tafsir source picker, future in-app filters) must use `normalizeArabicForSearch` on both sides before `contains` / `startsWith`. Package-internal search (`mushaf_reader` ayah index, `dorar_hadith` API queries, `hisn_elmoslem` DB `search` columns) keeps its own pre-normalized data or aligned copies — update those when changing the folding rules here.

## Reusable widgets & hooks

### Cards (`lib/core/widgets/custom_cards.dart`)

- `HoverCard` — animated border/shadow on hover, uses `colors.secondary` bg and `colors.primary` active border
- `StaticCard` — simple container with `colors.secondary` bg and border, no interactions

### Hooks (`lib/core/hooks/hooks.dart`)

- `useHoverState()` → returns `({bool isHovered, void Function({required bool value}) setHovered})`
- `useMapController` — for `free_map` widget
- `useMushafController` — creates and disposes a `MushafReaderController`; the Quran screen itself uses `quranMushafControllerProvider`
- `useDebouncedCallback` — returns a callable `DebouncedCallback` with `cancel` (default 400ms)
- `useRegisterAppSearchFocus` — in `core/shortcuts/shortcuts.dart` (registers Ctrl+K search handler)

### Other common widgets (`lib/core/widgets/`)

- `MouseClick` — `FTappable.static` + `FFocusedOutline` wrapper with cursor, hover, click
- `AnimationEntry` — staggered fade-in + slide-up + scale using `flutter_animate`
- `AnimatedIconButton` — rotates between two icons with animation
- `FSkeletonizer` — forui-themed `Skeletonizer` wrapper (shimmer, pulse, fade effects)
- `ScaleStepPicker` — discrete text-scale UI
- `MergedActionSemantics` — single semantics node for icon-only shell controls
- `TawaqDialogShell`, `PlayerDialogHeader`, `ForuiDialogLayout` — shared modal chrome/layouts (`lib/core/widgets/dialog_shell.dart`)
- `ReadingSwipeViewport`, `DirectionalContentSwitcher` — reading pane navigation

### Barrel exports

- `import 'package:tawaq/theme/theme.dart'` → all theme tokens (`AppSpacing`, `AppRadii`, `AppDurations`, `AppTabsStyles`, extensions, button/select styles)
- `import 'package:tawaq/core/hooks/hooks.dart'` → all custom hooks

## Feature highlights

### Hadith

Dorar API search + local Hive (favorites, recents). State: persisted `hadithScreenSettingsProvider` + session `hadithSessionControllerProvider` (search, filters, results, selection). UI: `hadith_screen.dart`, `hadith_search_column.dart`, `hadith_results_column.dart` (+ filter/detail widgets). Sharh parsing pipeline lives in `domain/services/` (parallel to Quran tafsir). Split layout is container-gated by `kStudyPanelMinExtent + kMainPaneMinExtent`; the narrow branch keeps search and results in one main column.

### Muslim Fortress

Powered by `hisn_elmoslem`. `FortressRepository` installs/version-checks the bundled databases, maps package rows, and caches chapters/duas/commentary. The feature supports chapters, global search, commentary, bookmarks, and focus reading. Its split is container-gated; the narrow branch stacks browse and main panes. `fortressRecommendedCategoriesProvider` uses `prayerDayProvider` for prayer-window-aware suggestions and falls back to `appClockProvider` before prayer data is ready.

### Prayer

**Single source of truth for prayer times:** `prayerDayProvider` (live 1 Hz `PrayerDaySnapshot`) in `prayer_day.dart`; historical bundles come from `prayerDayBundleForDateProvider`. Computation goes through `computePrayerDayBundle()` plus `effectivePrayerSettingsProvider` / `prayerTimeInputsProvider` (import `prayer_day.dart` for cross-feature reads). Slot logic (current prayer, card decision, schedule highlight, sunnah windows) lives in `prayer_slots.dart`; alert-target resolution lives in `domain/services/prayer_alert_resolver.dart`. Completions read via `completionStatusProvider(prayer, dayKey)`. Never recompute prayer times ad hoc in widgets.

`PrayerDay` (`@Riverpod(keepAlive: true)`) projects the shared `appClockProvider` into the configured timezone and emits once per second. Live prayer UI should watch it (or its minute/day projections), not create local timers. Derived providers such as `currentMinuteBucketProvider`, `scheduleCurrentPrayerProvider`, `prayerCardStaticProvider`, `prayerCardCountdownProvider`, and `prayerCalendarDayKeyProvider` minimize rebuilds.

### Quran

Mushaf via `mushaf_reader`. Study mode uses `StudyModeLayout` with `ResponsiveHorizontalSplitGate` + collapsible split. Tafsir: `tafsirForAyahProvider` → `TafsirTextParser` pipeline → `TafsirStudySection` in `tafsir_text.dart`; parsed rows are bounded by LRU caches. Shared commentary rendering lives in `lib/core/commentary/`. Recitation behavior spans pure policies/state transitions in `domain/services/recitation_*.dart` and orchestration in `recitation_provider.dart`. The typed Quran route owns the live page; `lastPageNumber` is only a restore checkpoint. Ayah selection is session-only (`quranSelectedAyahIdProvider`) and `useQuranAyahSelectionSync` aligns it with the shared `quranMushafControllerProvider`.

## Localization

- ARB files live in `lib/l10n/` (`app_en.arb`, `app_ar.arb`).
- Access strings via `context.l10n.someKey` (extension in `lib/core/locale/locale_extension.dart`).
- The app is RTL-aware; test both English and Arabic layouts.
- Feature locale extensions currently include `hadith_locale_extensions.dart` and `adhan_locale_extensions.dart`.

## Local packages

The `packages/` folder contains in-repo packages (referenced via `path:` in `pubspec.yaml`):

- `adhan_dart` — **git submodule**. Prayer time calculations with timezone support.
- `dorar_hadith` — **git submodule**. Hadith search/browsing from Dorar API.
- `dorar_hadith_flutter` — Flutter init wrapper (inside `dorar_hadith`); lazy via `dorarInitProvider` (not `main`).
- `mushaf_reader` — vendored in this repo. Quran rendering with QCF4 fonts. Initialized in `main` via `MushafReaderLibrary.ensureInitialized(subDirectory: 'tawaq')`; run its codegen through `tool/codegen.sh` after a fresh clone or generated-model changes.
- `hisn_elmoslem` — vendored in this repo. Hisn al-Muslim content (chapters, dhikr, commentary). DB in `packages/hisn_elmoslem/assets/database/`.
- `desktop_tray` — vendored fork with a Linux live-menu update patch; review the note beside its path dependency before upgrading it.

After clone: `git submodule update --init -- packages/adhan_dart packages/dorar_hadith`

## Timezone handling

Prayer times depend on accurate timezone. The app uses `timezone` + `flutter_timezone` packages:

- Initialized in `main.dart` via `tz.initializeTimeZones()`.
- `PrayerSettings` stores a `Location` object (from `timezone`).
- `FlutterTimezone.getLocalTimezone()` used for device TZ detection in settings.
- Use `TZDateTime` for prayer instants and comparisons in the configured location. Calendar-day APIs intentionally use `DateTime` wall components/day keys; normalize them through `prayer_calendar.dart` rather than calling `DateTime.now()` or doing ad-hoc UTC/local conversion.

## Key dependencies

Package names and roles only — versions live in `pubspec.yaml`.


| Category          | Packages                                                                                                                             |
| ----------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| **UI**            | `forui`, `forui_hooks`, `fl_chart`, `flutter_animate`, `skeletonizer`                                                                |
| **State**         | `flutter_riverpod`, `hooks_riverpod`, `flutter_hooks`, `riverpod_annotation`                                                         |
| **Storage**       | `hivez_flutter`, `sqlite3`, `path`, `path_provider`                                                                                  |
| **Navigation**    | `go_router`                                                                                                                          |
| **Models**        | `freezed_annotation`, `json_annotation`                                                                                              |
| **Domain**        | `adhan_dart`, `mushaf_reader`, `dorar_hadith`, `hisn_elmoslem` (local), `timezone`, `flutter_timezone`, `hijri_date`                 |
| **Maps**          | `free_map`, `geolocator`, `lat_lng_to_timezone`                                                                                      |
| **Networking**    | `http`                                                                                                                               |
| **Platform**      | `window_manager`, `screen_retriever`, `flutter_alone`, `desktop_tray`, `local_notifier`, `launch_at_startup`, `mpv_audio_kit`       |
| **Codegen (dev)** | `build_runner`, `riverpod_generator`, `freezed`, `json_serializable`, `hive_ce_generator`, `flutter_gen_runner`, `go_router_builder` |
| **Lint (dev)**    | `very_good_analysis`, `riverpod_lint`                                                                                                |
| **Test (dev)**    | `mocktail`, `fake_async`                                                                                                             |


## Desktop platform dependencies (Linux)

Tray and adhan notifications require system libraries at build and runtime:

```bash
# Ubuntu / Debian
sudo apt install libayatana-appindicator3-dev libnotify-dev

# Fedora
sudo dnf install libayatana-appindicator-gtk3-devel libnotify-devel
```

`mpv_audio_kit` targets Ubuntu 24.04+ on Linux. Desktop adhan is driven by the running app process, so it must remain open (visible or hidden to the tray); there are no OS alarm APIs in v1.

## Linting & testing

- Uses `very_good_analysis` with `riverpod_lint`. `analysis_options.yaml` excludes `**/*.g.dart`, `packages/`, build outputs, and platform runner directories.
- Run `fvm flutter analyze` before committing.
- Tests live in `test/`. Run with `fvm flutter test`.
- For Hive-dependent tests, a test database is set up in `test/hive_test_db/`.
- Layout tests live in `test/core/layout/` (responsive behavior, split gating/constraints, dialog constraints, responsive fields, and dialog-shell behavior).

## Complexity budget (keep code editable by hand)

These rules exist because the codebase drifted into over-fragmentation (many single-use files + deep indirection). Follow them for all new and changed code:

1. **One screen, few files.** A widget used by exactly one parent belongs as a `private _Widget` in that parent's file. Extract to its own file only when (a) it is reused in 2+ places, or (b) the host file exceeds ~400-500 lines. Do not create an `InheritedWidget`/scope just to pass one value down a single subtree.
2. **No pass-through layers.** A Repository/Service/Provider must add behavior (mapping, caching, error handling, orchestration). If a method only forwards a call to a dependency, delete it and call the dependency directly.
3. **One provider per concept, not per field.** Never create a derived provider whose only job is to re-expose a field of another provider. Use `ref.watch(other.select((s) => s.field))` at the call site instead.
4. **Co-locate small models.** Group small enums/DTOs of one domain into a single `<domain>_models.dart`. Do not create a separate file for each 2-field type or one-line enum.
5. **Abstraction must earn its keep.** Prefer flat data + plain functions over sealed catalogs and event/effect state machines unless the variety/scale genuinely demands it.
6. **Ownership boundaries.** A feature's screen/session/settings state lives in that feature's folder, never in a shared cross-feature file.
7. **Delete dead code on sight.** Unused barrels, deprecated forwards, and unreferenced helpers should be removed, not left behind.

Rule of thumb: a change to "how X looks/behaves" should require opening 1-2 files, not 8-20. If you find yourself adding an under-50-line file that has a single caller, inline it instead.
