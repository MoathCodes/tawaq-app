# Agent Notes (Hasanat)

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

## Storage

- **Hivez** (`hivez_flutter`) for structured local data. Adapters are generated in `lib/hive/` and registered in `main.dart`.
- **Prf** for simple key-value preferences (see `SettingsRepo` for patterns like `Prf.enumerated`, `Prf.json`, `Prf.cast`).
- **SQLite** (`sqlite3` + bundled `.db` files in `assets/database/`) for read-only reference data (tafseer, translations).

## Theming & styling

- UI primitives come from **Forui** (`forui` package). Access theme via `FTheme.of(context)` or `context.theme`.
- Custom extensions on `FThemeData` in `lib/theme/theme_extensions.dart`:
  - `context.theme.radii` → `AppRadii` (xs, sm, md, lg, xl, full)
  - `context.theme.durations` → `AppDurations`
- Spacing uses `AppSpacing` constants with `flutter_screenutil_plus`:
  ```dart
  context.edgeInsets(all: AppSpacing.lg)
  context.verticalSpace(AppSpacing.md)
  ```
- Design size is `1908×987`. Responsive scaling is handled by `ScreenUtilPlusInit` in `main.dart`.

## Localization

- ARB files live in `lib/l10n/` (`app_en.arb`, `app_ar.arb`).
- Access strings via `context.l10n.someKey` (extension in `lib/core/locale/locale_extension.dart`).
- The app is RTL-aware; test both English and Arabic layouts.

## Local packages

The `packages/` folder contains in-repo packages:
- `mushaf_reader` – Quran rendering with QCF4 fonts, must call `MushafReaderLibrary.ensureInitialized()` before use.
- `adhan_dart` – Prayer time calculations with timezone support.
- `dorar_hadith` – Hadith search/browsing from Dorar API.
- `dyn_mouse_scroll` – Custom scroll physics.

These are referenced via `path:` in `pubspec.yaml`.

## Timezone handling

Prayer times depend on accurate timezone. The app uses `timezone` package:
- Initialized in `main.dart` via `tz.initializeTimeZones()`.
- `PrayerSettings` stores a `Location` object (from `timezone`).
- Always use `TZDateTime` instead of raw `DateTime` for prayer-related logic.

## Styling/UX gotchas

- Fixed-size widgets (especially `CustomPaint`) can overflow column constraints. Prefer `LayoutBuilder` to size custom visuals from available width.
- For charts, `fl_chart` integrates cleanly. Keep axes and grid minimal to match the dark UI.
- Hover effects: use `useHoverState()` hook (from `lib/core/hooks/`) with `MouseRegion`.
- Cards: prefer `HoverCard` from `lib/core/widgets/custom_cards.dart` for consistent hover animations.

## Dart language (v3.10)

- Dot-shorthand (`.value`) works on static members, factories, and enums.
- Dot-shorthand does **not** work on runtime variables (e.g., `color: .red` is invalid). Use `Colors.red` or qualified references.

## Linting

- Uses `very_good_analysis` with `riverpod_lint` plugin.
- Generated files and `packages/` are excluded from analysis.
- Run `flutter analyze` before committing.

## Testing

Unit tests live in `test/`. Run with:
```bash
flutter test
```

For Hive-dependent tests, a test database is set up in `test/hive_test_db/`.
