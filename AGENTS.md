# reeAgent Notes (Tawaq)

**Dependency versions:** Do not rely on version numbers in this file — they go stale. Read `pubspec.yaml` (and `pubspec.lock` if you need resolved versions) for the current constraints.

## Code generation

This project relies heavily on code generation. After modifying models, providers, or Hive adapters, run:

```bash
dart run build_runner build
```

Generated files (`.g.dart`, `.freezed.dart`) are git-ignored. Always regenerate after pulling changes or modifying:

- **Riverpod providers** (`@riverpod`, `@Riverpod(keepAlive: true)`) → `.g.dart`
- **Freezed models** (`@freezed`) → `.freezed.dart` + `.g.dart` for JSON
- **Hive adapters** (`lib/hive/hive_adapters.dart`) → `lib/hive/hive_registrar.g.dart`, registered via `Hive.registerAdapters()` in `main.dart`
- **Typed routes** (`@TypedGoRoute` in `lib/core/routing/route_provider.dart`) → `route_provider.g.dart` via `go_router_builder`
- **Assets/fonts** (`flutter_gen_runner`) → `lib/gen/assets.gen.dart`, `fonts.gen.dart`
- **Localization** → `lib/l10n/app_localizations*.dart` (auto-generated from `lib/l10n/app_*.arb`)

## Architecture layers

### Feature structure

Five features follow clean architecture (`data/` → `domain/` → `presentation/`):


| Feature           | Route                  | Notes                                                                                          |
| ----------------- | ---------------------- | ---------------------------------------------------------------------------------------------- |
| `prayer`          | `/prayer`              | Hive completions + adhan_dart                                                                  |
| `quran`           | `/quran`               | mushaf_reader + SQLite tafsir/translations; uses `data/sources/` and `presentation/providers/` |
| `settings`        | `/settings`            | Persisted prefs                                                                                |
| `onboarding`      | `/onboarding`          | First-run locale + setup flow (standalone, outside shell)                                      |
| `hadith`          | `/hadith`              | Dorar API + local Hive favorites/recents                                                       |
| `muslim_fortress` | `/muslim_fortress`     | hisn_elmoslem package + SQLite assets                                                          |


```
feature/
  <name>/
    data/           # database/ or sources/, models/, repository/
    domain/         # models/, services/, use_cases/ (sparse)
    presentation/   # provider/ or providers/, screens/, widgets/
```

Variations: quran uses `data/sources/` instead of `data/database/`; hadith/muslim_fortress have no `use_cases/`; muslim_fortress has domain-only models. Shared infra lives in `lib/core/` (locale, routing, database, layout, commentary).

### Data flow pattern

`Database` → `Repository` (adds error handling/logging) → `Service` (business logic) → `Provider` (state) → `Widget`

When adding a new query, propagate through each layer. Not every feature has a single `Database` class — hadith combines Dorar API + Hive; quran uses `AssetDatabaseService` + sources. Settings flow Provider → Widget directly (no service layer).

## State management

- **Riverpod** with `riverpod_generator` for all async state. Use `@riverpod` for auto-dispose, `@Riverpod(keepAlive: true)` for singletons (databases, services).
- **flutter_hooks** / **hooks_riverpod** for local widget state. Prefer `HookConsumerWidget` when you need both hooks and providers.
- Widget hierarchy: `ConsumerWidget` (provider only) < `HookWidget` (hooks only) < `HookConsumerWidget` (both). `ConsumerStatefulWidget` appears in a few places (shortcut scopes, sliders).
- Generated names: class notifiers expose `*Provider` (e.g. `themeProvider`, `localeProvider`).

### Settings persistence pattern

Settings notifiers use `@JsonPersist()` (from `riverpod_annotation/experimental/json_persist.dart`) with a shared `SettingsStorage` (Hivez-backed, box `riverpod_persist`). Key notifiers:

- `LocaleNotifier` — sync, stores language code (`"en"` / `"ar"`) — lives in `lib/core/locale/locale_provider.dart`
- `PrayerSettingsNotifier` — async, coordinates, timezone, iqamah offsets, 24h toggle
- `ThemeNotifier` — async, stores `AppPalette` + `ThemeMode` + `**AppTextScale`**
- **UI state** — screen/session prefs live in each feature (not a shared settings junk drawer):
  - `SidebarSettingsNotifier` — `lib/core/widgets/page_shell/sidebar_settings_provider.dart`
  - `PrayerAnalyticsSettingsNotifier` — `lib/feature/prayer/presentation/provider/prayer_analytics_settings_provider.dart`
  - `QuranScreenSettingsNotifier` + `RecitationSettingsNotifier` — `lib/feature/quran/presentation/providers/quran_screen_settings_provider.dart`
  - `HadithScreenSettingsNotifier` — `lib/feature/hadith/presentation/provider/hadith_screen_settings_provider.dart`
  - `FortressScreenSettingsNotifier` — `lib/feature/muslim_fortress/presentation/provider/fortress_screen_settings_provider.dart`
  - `SettingsScreenSettingsNotifier` — active settings tab key string (`settings_screen_settings_provider.dart`)
- `FirstPrayerRecordedDate` — ISO date of first recorded prayer (analytics)
- `PrayerAnalyticsPrefs` — lives under `lib/feature/prayer/data/models/` (owned by prayer analytics)

Common internal pattern: `_commit()` helper that guards against null state, applies a transform, and logs the changed field name. Async notifiers call `persist()` in `build()` after `await .future`. All use `StorageOptions(cacheTime: unsafe_forever)`.

Import concrete settings providers directly (`prayer_settings_provider.dart`, `theme_settings_provider.dart`, `locale_provider.dart`, etc.). Feature screen settings import from their feature (`quran_screen_settings_provider.dart`, etc.). Cross-feature prayer time reads import `prayer_day.dart` directly (`effectivePrayerSettingsProvider` / `prayerDayProvider`).

## Routing

Typed **go_router** setup in `lib/core/routing/route_provider.dart`:

- `@TypedGoRoute` / `@TypedShellRoute` codegen → `route_provider.g.dart`
- `appRouterProvider` — root `GoRouter`, initial `/prayer`
- `AppShellRoute` wraps nested navigator in `PageShell`
- `mainRoutesProvider` (prayer, quran, hadith, muslim_fortress) + `secondaryRoutesProvider` (settings, about)
- `OnboardingRoute` at `/onboarding` (standalone, outside shell)
- Navigation: typed `.go(context)` on route classes; sidebar/bottom nav consume route providers

## Storage

- **Hivez** (`hivez_flutter`) for structured local data. Adapters in `lib/hive/hive_adapters.dart` (`PrayerCompletion`, `HadithFavorite`, etc.). Boxes: `prayer_completions`, `hadith_favorites`, `hadith_recent_searches`, `quran_notes`, `riverpod_persist`.
- **SQLite** (`sqlite3` + bundled `.db` files) for read-only reference data. `AssetDatabaseService` copies assets → documents on first open. App assets in `assets/database/` (translations, tafsir). Muslim Fortress DB lives in `packages/hisn_elmoslem/assets/database/`.

## Theming & styling

### Forui (primary UI library)

The entire UI is built with **forui** (see `pubspec.yaml`). Access theme via:

- `context.theme` → `FThemeData` (from forui's `FThemeBuildContext` extension)
- `context.theme.colors` → `FColors`
- `context.theme.isDark` → `bool` (custom extension checking `colors.brightness`)
- `FTheme.of(context)` → alternative explicit lookup (same as `context.theme`)
- `selectStyle()` — custom select styles in `lib/theme/select_style.dart`; per-control button styling uses Forui defaults (`base.buttonStyles`) plus `windowControlButtonStyle()` / `closeButtonStyle()` / `layoutSegmentButtonStyle()` in `lib/theme/button_styles.dart`

### FColors — key property reference

Core slots: `background`, `foreground`, `primary`, `primaryForeground`, `secondary`, `secondaryForeground`, `muted`, `mutedForeground`, `destructive`, `destructiveForeground`, `error`, `errorForeground`, `border`, `barrier`, `**card`**.

Utility methods: `hover(Color)` derives a hover variant, `disable(Color)` derives a disabled variant at `disabledOpacity`.

### Theme palette system

The app supports 2 palettes, each with light + dark variants:


| `AppPalette` | Source                                                                   |
| ------------ | ------------------------------------------------------------------------ |
| `manuscript` | Custom `ManuscriptTheme` in `lib/theme/custom_themes.dart` **(default)** |
| `neutral`    | `FTheme.neutral` (Forui built-in)                                        |


Legacy persisted palette names (blue, zinc, …) map to `manuscript` via `appPaletteFromJson`.

Resolution: `resolveColorScheme(AppPalette, ThemeMode, {touch})` → `_palettesData` map → `FThemeData`. Then `**buildAppTheme()`** in `lib/theme/app_theme_builder.dart` injects `AppRadii`, `AppDurations`, `AppTextScale`, and `IBMPlexSansArabic` as the app-wide font. Touch vs desktop density chosen via `_isTouchThemePlatform` in `main.dart`. Dual theme tree: `MaterialApp.theme` (scrollbars/Material bridge) + `FTheme` wrapper in builder.

### Custom extensions on FThemeData

Defined in `lib/theme/theme_extensions.dart`:

- `context.theme.radii` → `AppRadii` (xs, sm, md, lg, xl, full)
- `context.theme.durations` → `AppDurations` (instant, fast, normal, slow, slower)

### Spacing & responsive layout

- Spacing uses `AppSpacing` constants (from `lib/theme/spacing.dart`): `xs` (4), `sm` (8), `md` (12), `lg` (16), `xl` (24), `xxl` (32), `xxxl` (48). Fixed logical pixels — no screen-based font scaling.
- **Viewport breakpoints** — Forui `context.theme.breakpoints` (`FBreakpoints`: sm 640, md 768, lg 1024, xl 1280, **xl2 1536**). Helpers in `lib/core/layout/responsive.dart`: `isAtLeast`, `isLessThan`, `responsiveValue`, `contentWidth`, `responsiveColumnCount`.
- **Container breakpoints** — when layout depends on allocated width (split panes, sidebars, dialogs), use `LayoutBuilder` and compare `constraints.maxWidth` to breakpoints.
- **Rule of thumb:** viewport breakpoints for page-level mode switches; container breakpoints for split panes, dialogs, and dense forms.

#### Layout helpers (`lib/core/layout/`)


| File                               | API                                                                                                             | Used by                       |
| ---------------------------------- | --------------------------------------------------------------------------------------------------------------- | ----------------------------- |
| `responsive.dart`                  | Viewport helpers (`isAtLeast`, `isLessThan`), `isContainerAtLeast` for `LayoutBuilder` widths, `FBreakpoint` enum | All features                  |
| `split_pane_constraints.dart`      | `kStudyPanelMinExtent` (320), `kMainPaneMinExtent` (480), `kMushafPaneMinExtent` (400), `resolveSplitExtents()`, `migrateSidePanelWidthToRatio()`, `minSplitContainerWidth()`, `canUseHorizontalSplit()` | Hadith, Quran study, Fortress |
| `persisted_horizontal_split_pane.dart` | `PersistedHorizontalSplitPane` — `FResizableRegion.flex` split that persists a **ratio**; stable regions across rebuilds | Hadith, Quran study, Fortress |
| `collapsible_horizontal_split_pane.dart` | `CollapsibleHorizontalSplitPane` (+ `.feature(...)` factory) — wraps persisted split; collapses the side pane via `FCollapsible(axis: horizontal)` with a divider-edge handle + rail | Hadith, Quran study, Fortress |
| `responsive_horizontal_split.dart`   | `ResponsiveHorizontalSplitGate` — shared `canUseHorizontalSplit` gating + stacked fallback | Hadith, Quran study, Fortress |
| `viewport_dialog_constraints.dart` | `dialogConstraints()`, `selectPopoverPortalConstraints()`                                                       | Dialogs, Quran selectors      |
| `responsive_field_row.dart`        | `ResponsiveFieldRow` — column below 640px, row above                                                            | Settings forms, wizard        |
| `lazy_tab_content.dart`            | `LazyPanelContent.tab` / `LazyPanelContent.indexed` — defer tab/panel build until first selected | Settings, Hadith filters    |


**FResizable split-pane convention:** prefer `ResponsiveHorizontalSplitGate` → `CollapsibleHorizontalSplitPane.feature(...)` over hand-rolled `FResizable`. Pattern: gate checks `canUseHorizontalSplit` → feature factory wires `resolveFeatureSplitExtents()` → `FResizableRegion.flex` regions inside a `Directionality(textDirection: TextDirection.ltr)` (consistent resize handles in RTL); restore user `Directionality` inside each region. Side size is persisted as a **ratio** (0..1, not pixels) via the feature screen-settings notifier on `onResizeEnd`, so panels keep their share across monitor sizes; legacy pixel state upgrades through `migrateSidePanelWidthToRatio()`. Collapsed state is a separate persisted bool per screen.

**Split gating:** use `ResponsiveHorizontalSplitGate` (or inline `canUseHorizontalSplit` + `LayoutBuilder`) before rendering a horizontal split. When false, fall back to a stacked layout showing `mainPane` only.

### Text scaling

Two independent scales — do not use `.sp` or screen-based scaling:

- `**AppTextScale`** — app UI via `buildAppTheme` (0.9–1.2×), persisted in `ThemeNotifier`
- `**QuranTextScale**` — mushaf rendering via `buildQuranMushafStyle`, persisted in `QuranScreenSettingsNotifier`. Study layout uses `TextScaler.noScaling` on mushaf subtree.

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

- `**TawaqAppScrollBehavior**` — app-wide via `MaterialApp.scrollBehavior` in `main.dart`. Thin auto-hiding thumb only when `isMeaningfulScroll()` (min 512px overflow, 8% of viewport).
- `**tawaqScrollbarTheme()**` — thin thumb, no track (`main.dart`). Theme sets `thumbVisibility: false` so the thumb fades out shortly after scrolling stops; `_MeaningfulScrollbar` wraps eligible scrollables with `RawScrollbar` using `kScrollbarTimeToFade` / `kScrollbarFadeDuration`.

## App shell & desktop

### PageShell (`lib/core/widgets/page_shell/`)

- **Sidebar** ≥ sm (640px); **bottom nav** < sm (640px)
- Sidebar auto-collapse default on tablet < lg (1024px) via `shellSidebarCollapsedProvider`
- **Custom title bar:** 52px drag strip with `WindowControls` + `window_manager.startDragging()`
- `**ShellShortcutScope`** — global keyboard shortcuts (desktop only)
- `**NonSelectable**` on chrome (sidebar, app bar, window controls)
- `**ShellBottomNavigationBar**`, `**ShellAppBar**`, `**ShellA11y**` labels

### Desktop selection (`lib/core/widgets/desktop_selection.dart`)

- `**DesktopSelectionArea**` — `SelectionArea` on desktop only
- `**ScopedSelectableText` / `ScopedSelectableRichText**` — selectable on desktop, plain elsewhere
- `**NonSelectable**` — `SelectionContainer.disabled` for chrome/buttons

### Keyboard shortcuts (`lib/core/shortcuts/`)

Sealed catalog: flat `ShortcutDef` list in `app_shortcut.dart` → `ShellShortcutScope` (`invokeGlobalShortcut`) + `AppShortcutScope` (route/contextual handler maps). `useRegisterAppSearchFocus` hook for Ctrl+K search focus. UI helpers in `lib/core/widgets/shortcuts/`.

### Accessibility

- `**MergedActionSemantics**` — single semantics node for icon-only shell controls (chrome only, not page body)
- `**ShellA11y**` — localized labels for shell nav, window controls, theme toggle
- Feature mirrors (6 modules): `shell_a11y.dart`, `prayer_semantics.dart`, `quran_semantics.dart`, `hadith_accessibility.dart` (not `hadith_semantics.dart`), `fortress_a11y.dart`, `settings_semantics.dart`
- **Tooltip rule:** any size-constrained widget (no room for a label, or the label alone can't fully explain the widget — e.g. an icon-only button) **must** be wrapped in `FTooltip` with a descriptive tooltip string. This applies even when a short label is present if that label alone is ambiguous without context.

## Core infrastructure


| Module      | Location                                    | Purpose                                            |
| ----------- | ------------------------------------------- | -------------------------------------------------- |
| Locale      | `core/locale/locale_provider.dart`          | Persisted language code                            |
| Logging     | `core/logging/logger_provider.dart`         | `loggerProvider` → shared `Logger`                 |
| Asset DB    | `core/database/asset_database_service.dart` | SQLite copy-from-assets                            |
| Commentary  | `core/commentary/`, `core/text/`            | Shared Arabic normalization + rich text rendering  |
| Platform    | `core/utils/platform.dart`                  | `isDesktopPlatform` (Linux/Windows/macOS, not web) |
| Hijri clock | `core/utils/hijri_provider.dart`            | Live Hijri date for prayer hero header and schedule UI         |
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
- `useMushafController` — mushaf page controller sync with persisted ayah selection (exported from `hooks.dart`)
- `useDebouncedCallback` — debounced `VoidCallback` for search/filter UI (default 400ms)
- `useRegisterAppSearchFocus` — in `core/shortcuts/shortcuts.dart` (registers Ctrl+K search handler)

### Other common widgets (`lib/core/widgets/`)

- `MouseClick` — `FTappable.static` + `FFocusedOutline` wrapper with cursor, hover, click
- `AnimationEntry` — staggered fade-in + slide-up + scale using `flutter_animate`
- `AnimatedIconButton` — rotates between two icons with animation
- `FSkeletonizer` — forui-themed `Skeletonizer` wrapper (shimmer, pulse, fade effects)
- `ScaleStepPicker` — discrete text-scale UI
- `MergedActionSemantics` — single semantics node for icon-only shell controls
- `PlayerDialogShell` — shared modal chrome for Quran recitation dialogs (`lib/core/widgets/dialog_shell.dart`)
- `ReadingSwipeViewport`, `DirectionalContentSwitcher` — reading pane navigation

### Barrel exports

- `import 'package:tawaq/theme/theme.dart'` → all theme tokens (`AppSpacing`, `AppRadii`, `AppDurations`, extensions, button/select styles)
- `import 'package:tawaq/core/hooks/hooks.dart'` → all custom hooks

## Feature highlights

### Hadith

Dorar API search + local Hive (favorites, recents). State: persisted `hadithScreenSettingsProvider` + session `hadithSessionControllerProvider` (search, filters, results, selection). UI: `hadith_screen.dart`, `hadith_search_column.dart`, `hadith_results_column.dart` (+ shared filter/detail widgets). Sharh parsing pipeline in `domain/services/` (parallel to Quran tafsir). Split layout via `ResponsiveHorizontalSplitGate` at viewport `lg`.

### Muslim Fortress

Powered by `hisn_elmoslem` package. Chapters, duas, search, commentary, focus reading. Split layout at viewport `md`. `FortressTimeRecommendations` uses `prayerDayProvider` for prayer-window-aware suggestions.

### Prayer

**Single source of truth for prayer times:** `prayerDayProvider` (live 1 Hz `PrayerDaySnapshot`) in `prayer_day.dart`; historical bundles via `prayerDayBundleForDateProvider`. All computation goes through `PrayerDayComputer` + `effectivePrayerSettingsProvider` / `prayerTimeInputsProvider` (import `prayer_day.dart` for cross-feature reads). Slot logic (current prayer, card decision, schedule highlight) lives in `prayer_slots.dart`. Completions read via `completionStatusProvider(prayer, day)`. Never compute times via ad-hoc `PrayerService` calls.

`PrayerDay` (`@Riverpod(keepAlive: true)`) emits snapshot every 1s — **all live time UI** should watch this, not local timers. Derived providers (`scheduleCurrentPrayerProvider`, `prayerCardProvider`, `prayerCalendarDayKeyProvider`) minimize rebuilds.

### Quran

Mushaf via `mushaf_reader`. Study mode uses `StudyModeLayout` with `ResponsiveHorizontalSplitGate` + collapsible split. Tafsir: `tafsirForAyahProvider` → `TafsirTextParser` pipeline → `TafsirStudySection` in `tafsir_text.dart`. Shared commentary rendering in `lib/core/commentary/`. Recitation state machine in `recitation_state_machine.dart` + `recitation_provider.dart` (not yet collapsed). `useMushafController` + ayah selection sync keep controller aligned with persisted `selectedAyah`.

## Localization

- ARB files live in `lib/l10n/` (`app_en.arb`, `app_ar.arb`).
- Access strings via `context.l10n.someKey` (extension in `lib/core/locale/locale_extension.dart`).
- The app is RTL-aware; test both English and Arabic layouts.
- Feature locale extensions: `hadith_locale_extensions.dart`, `fortress_locale_extensions.dart`.

## Local packages

The `packages/` folder contains in-repo packages (referenced via `path:` in `pubspec.yaml`):

- `adhan_dart` — **git submodule**. Prayer time calculations with timezone support.
- `dorar_hadith` — **git submodule**. Hadith search/browsing from Dorar API.
- `dorar_hadith_flutter` — Flutter init wrapper (inside `dorar_hadith`); lazy via `dorarInitProvider` (not `main`).
- `mushaf_reader` — vendored in this repo. Quran rendering with QCF4 fonts. Initialized in `main` via `MushafReaderLibrary.ensureInitialized(subDirectory: 'tawaq')`.
- `hisn_elmoslem` — vendored in this repo. Hisn al-Muslim content (chapters, dhikr, commentary). DB in `packages/hisn_elmoslem/assets/database/`.
- `desktop_tray` — vendored in this repo.

After clone: `git submodule update --init -- packages/adhan_dart packages/dorar_hadith`

## Timezone handling

Prayer times depend on accurate timezone. The app uses `timezone` + `flutter_timezone` packages:

- Initialized in `main.dart` via `tz.initializeTimeZones()`.
- `PrayerSettings` stores a `Location` object (from `timezone`).
- `FlutterTimezone.getLocalTimezone()` used for device TZ detection in settings.
- Always use `TZDateTime` instead of raw `DateTime` for prayer-related logic.

## Key dependencies

Package names and roles only — versions live in `pubspec.yaml`.


| Category          | Packages                                                                                                                             |
| ----------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| **UI**            | `forui`, `forui_hooks`, `fl_chart`, `flutter_animate`, `skeletonizer`                                                                |
| **State**         | `flutter_riverpod`, `hooks_riverpod`, `flutter_hooks`, `riverpod_annotation`                                                         |
| **Storage**       | `hivez_flutter`, `sqlite3`, `path_provider`                                                                                          |
| **Navigation**    | `go_router`                                                                                                                          |
| **Models**        | `freezed_annotation`, `json_annotation`                                                                                              |
| **Domain**        | `adhan_dart`, `mushaf_reader`, `dorar_hadith`, `hisn_elmoslem` (local), `timezone`, `flutter_timezone`, `hijri_date`                 |
| **Maps**          | `free_map`, `geolocator`, `lat_lng_to_timezone`                                                                                      |
| **Platform**      | `window_manager`, `desktop_tray`, `local_notifier`, `mpv_audio_kit` (desktop tray, adhan, audio)                                   |
| **Codegen (dev)** | `build_runner`, `riverpod_generator`, `freezed`, `json_serializable`, `hive_ce_generator`, `flutter_gen_runner`, `go_router_builder` |
| **Lint (dev)**    | `very_good_analysis`, `riverpod_lint`                                                                                                |
| **Test (dev)**    | `mocktail`                                                                                                                           |


## Desktop platform dependencies (Linux)

Tray and adhan notifications require system libraries at build and runtime:

```bash
# Ubuntu / Debian
sudo apt install libayatana-appindicator3-dev libnotify-dev

# Fedora
sudo dnf install libayatana-appindicator-gtk3-devel libnotify-devel
```

`mpv_audio_kit` targets Ubuntu 24.04+ on Linux. The app must stay running in the system tray for desktop adhan to fire (no OS alarm APIs in v1).

## Linting & testing

- Uses `very_good_analysis` with `riverpod_lint`. Generated files and `packages/` are excluded.
- Run `flutter analyze` before committing.
- Unit tests live in `test/`. Run with `flutter test`.
- For Hive-dependent tests, a test database is set up in `test/hive_test_db/`.
- Layout tests: `test/core/layout/` (responsive, split_pane_constraints, viewport_dialog_constraints, responsive_field_row).

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
