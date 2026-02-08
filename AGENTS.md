# Agent Notes (Tawaq)

## Code generation

This project relies heavily on code generation. After modifying models, providers, or Hive adapters, run:

```bash
dart run build_runner build
```

Generated files (`.g.dart`, `.freezed.dart`) are git-ignored. Always regenerate after pulling changes or modifying:
- **Riverpod providers** (`@riverpod`, `@Riverpod(keepAlive: true)`) → `.g.dart`
- **Freezed models** (`@freezed`) → `.freezed.dart` + `.g.dart` for JSON
- **Hive adapters** (`lib/hive/hive_adapters.dart`) → registers via `Hive.registerAdapters()`
- **Assets/fonts** (`flutter_gen_runner`) → `lib/gen/assets.gen.dart`, `fonts.gen.dart`
- **Localization** → `lib/l10n/app_localizations*.dart` (auto-generated from `lib/l10n/app_*.arb`)

## Architecture layers

### Feature structure
Each feature (`prayer`, `quran`, `settings`) follows clean architecture:
```
feature/
  prayer/
    data/           # Database, models, repository
      database/     # Raw Hive/DB operations
      models/       # Data classes (Freezed)
      repository/   # Wraps database, adds logging
    domain/         # Business logic
      models/       # Domain-specific models
      services/     # Pure business logic
      use_cases/    # Single-purpose operations
    presentation/   # UI layer
      provider/     # Riverpod providers (state)
      screens/      # Full-page widgets
      widgets/      # Reusable UI components
```

### Data flow pattern
`Database` → `Repository` (adds error handling/logging) → `Service` (business logic) → `Provider` (state) → `Widget`

When adding a new query, propagate through each layer.

## State management

- **Riverpod** with `riverpod_generator` for all async state. Use `@riverpod` for auto-dispose, `@Riverpod(keepAlive: true)` for singletons (databases, services).
- **flutter_hooks** / **hooks_riverpod** for local widget state. Prefer `HookConsumerWidget` when you need both hooks and providers.
- Widget hierarchy: `ConsumerWidget` (provider only) < `HookWidget` (hooks only) < `HookConsumerWidget` (both).

### Settings persistence pattern
Settings notifiers use `@JsonPersist()` (from `riverpod_annotation/experimental/json_persist.dart`) with a shared `SettingsStorage` (Hivez-backed). Key notifiers:
- `LocaleNotifier` — sync, stores language code (`"en"` / `"ar"`)
- `PrayerSettingsNotifier` — async, stores coordinates, timezone, iqamah offsets, 24h toggle
- `ThemeNotifier` — async, stores `AppPalette` + `ThemeMode`
- `StateSettingsNotifier` — async, stores sidebar state, Quran screen state, analytics period

Common internal pattern: `_update()` helper that guards against null state, applies a transform, and logs the changed field name. Async notifiers call `persist()` in `build()` after `await .future`.

## Storage

- **Hivez** (`hivez_flutter`) for structured local data. Adapters are generated in `lib/hive/` and registered in `main.dart`.
- **Prf** for simple key-value preferences (see `SettingsRepo` for patterns like `Prf.enumerated`, `Prf.json`, `Prf.cast`).
- **SQLite** (`sqlite3` + bundled `.db` files in `assets/database/`) for read-only reference data (tafseer, translations).

## Theming & styling

### Forui (primary UI library)
The entire UI is built with **forui** (`^0.17.0`). Access theme via:
- `context.theme` → `FThemeData` (from forui's `FThemeBuildContext` extension)
- `context.theme.colors` → `FColors`
- `context.theme.isDark` → `bool` (custom extension checking `colors.brightness`)
- `FTheme.of(context)` → alternative explicit lookup (same as `context.theme`)

### FColors — full property reference
These are the color slots available on every `FColors` instance:

| Property | Type | Purpose |
|---|---|---|
| `background` | `Color` | Page/scaffold background |
| `foreground` | `Color` | Primary text/icons on background |
| `primary` | `Color` | Key accent color (buttons, active states) |
| `primaryForeground` | `Color` | Text/icons on primary |
| `secondary` | `Color` | Subtle surface (cards, chips) |
| `secondaryForeground` | `Color` | Text/icons on secondary |
| `muted` | `Color` | Disabled/subtle backgrounds |
| `mutedForeground` | `Color` | De-emphasized text |
| `destructive` | `Color` | Dangerous action background |
| `destructiveForeground` | `Color` | Text/icons on destructive |
| `error` | `Color` | Error highlight |
| `errorForeground` | `Color` | Text/icons on error |
| `border` | `Color` | Default border/divider |
| `barrier` | `Color` | Modal overlay/scrim |

Utility methods: `hover(Color)` derives a hover variant, `disable(Color)` derives a disabled variant at `disabledOpacity`.

### Theme palette system
The app supports 10 palettes, each with light + dark variants:

| `AppPalette` | Source |
|---|---|
| `manuscript` | Custom `ManuscriptTheme` (warm gold/parchment, defined in `lib/theme/manuscript_theme.dart`) |
| `blue` | `FThemes.blue` |
| `orange` | `FThemes.orange` |
| `green` | `FThemes.green` |
| `red` | `FThemes.red` |
| `rose` | `FThemes.rose` |
| `slate` | `FThemes.slate` |
| `violet` | `FThemes.violet` |
| `yellow` | `FThemes.yellow` |
| `zinc` | `FThemes.zinc` **(default)** |

Resolution: `resolveColorScheme(AppPalette, ThemeMode)` → looks up `_palettesData` map → returns `FThemeData`. Then `_buildTheme()` injects `AppRadii` and `AppDurations` extensions (and swaps to `IBMPlexSansArabic` font for Arabic locale).

### Custom extensions on FThemeData
Defined in `lib/theme/theme_extensions.dart`:
- `context.theme.radii` → `AppRadii` (xs, sm, md, lg, xl, full)
- `context.theme.durations` → `AppDurations`

### Spacing & responsive scaling
- Spacing uses `AppSpacing` constants (from `lib/theme/spacing.dart`): `xs`, `sm`, `md`, `lg`, `xl`, etc.
- Responsive scaling via `flutter_screenutil_plus` with design size `1908×987`.
- Usage: `context.edgeInsets(all: AppSpacing.lg)`, `context.verticalSpace(AppSpacing.md)`, `16.sp` / `16.w` / `16.h`.

### Theme-adaptive color patterns
When colors need to represent a hierarchy (best→worst, active→inactive), use `Color.lerp` between theme colors instead of hardcoded hex values. Example from `CompletionStatus.getBadgeColor(FColors colors)`:
```dart
.jamaah => colors.primary,                                           // Full accent
.onTime => Color.lerp(colors.primary, colors.mutedForeground, 0.35)! // 35% muted
.late   => Color.lerp(colors.primary, colors.mutedForeground, 0.65)! // 65% muted
.missed => Color.lerp(colors.primary, colors.mutedForeground, 0.85)! // Near-neutral
```
This adapts automatically to every theme palette. **Never hardcode status/accent colors.**

## Reusable widgets & hooks

### Cards (`lib/core/widgets/custom_cards.dart`)
- `HoverCard` — animated border/shadow on hover, uses `colors.secondary` bg and `colors.primary` active border
- `StaticCard` — simple container with `colors.secondary` bg and border, no interactions

### Hooks (`lib/core/hooks/hooks.dart`)
- `useHoverState()` → returns `({bool isHovered, void Function({required bool value}) setHovered})`
- `useMapController` — for `free_map` widget

### Other common widgets (`lib/core/widgets/`)
- `MouseClick` — `MouseRegion` + `GestureDetector` wrapper with cursor, hover, exit, click
- `AnimationEntry` — staggered fade-in + slide-up using `flutter_animate`
- `AnimatedIconButton` — rotates between two icons with animation
- `FSkeletonizer` — forui-themed `Skeletonizer` wrapper (shimmer, pulse, fade effects)
- `IconBadge` — forui `FBadge` with icon + label
- `PageShell` / `ShellSidebar` / `ShellAppBar` — app shell layout widgets

### Barrel exports
- `import 'package:hasanat/theme/theme.dart'` → all theme tokens (`AppSpacing`, `AppRadii`, `AppDurations`, extensions, button/select styles)
- `import 'package:hasanat/core/hooks/hooks.dart'` → all custom hooks

## Localization

- ARB files live in `lib/l10n/` (`app_en.arb`, `app_ar.arb`).
- Access strings via `context.l10n.someKey` (extension in `lib/core/locale/locale_extension.dart`).
- The app is RTL-aware; test both English and Arabic layouts.

## Local packages

The `packages/` folder contains in-repo packages (referenced via `path:` in `pubspec.yaml`):
- `mushaf_reader` — Quran rendering with QCF4 fonts. Must call `MushafReaderLibrary.ensureInitialized()` before use.
- `adhan_dart` — Prayer time calculations with timezone support.
- `dorar_hadith` — Hadith search/browsing from Dorar API.
- `dyn_mouse_scroll` — Custom scroll physics.

## Timezone handling

Prayer times depend on accurate timezone. The app uses `timezone` package:
- Initialized in `main.dart` via `tz.initializeTimeZones()`.
- `PrayerSettings` stores a `Location` object (from `timezone`).
- Always use `TZDateTime` instead of raw `DateTime` for prayer-related logic.

## Key dependencies

| Category | Packages |
|---|---|
| **UI** | `forui` ^0.17.0, `forui_hooks`, `fl_chart`, `flutter_animate`, `skeletonizer`, `flutter_screenutil_plus` |
| **State** | `flutter_riverpod` ^3.0.3, `hooks_riverpod`, `flutter_hooks`, `riverpod_annotation` ^4.0.0 |
| **Storage** | `hivez_flutter`, `sqlite3`, `path_provider` |
| **Navigation** | `go_router` ^17.0.0 |
| **Models** | `freezed_annotation` ^3.0.0, `json_annotation` |
| **Domain** | `adhan_dart` (local), `mushaf_reader` (local), `dorar_hadith` (local), `timezone`, `hijri_date` |
| **Maps** | `free_map`, `geolocator`, `lat_lng_to_timezone` |
| **Platform** | `window_manager` (desktop window control) |
| **Codegen (dev)** | `build_runner`, `riverpod_generator`, `freezed`, `json_serializable`, `hive_ce_generator`, `flutter_gen_runner` |
| **Lint (dev)** | `very_good_analysis`, `riverpod_lint` |
| **Test (dev)** | `mocktail` |

## Linting & testing

- Uses `very_good_analysis` with `riverpod_lint`. Generated files and `packages/` are excluded.
- Run `flutter analyze` before committing.
- Unit tests live in `test/`. Run with `flutter test`.
- For Hive-dependent tests, a test database is set up in `test/hive_test_db/`.
