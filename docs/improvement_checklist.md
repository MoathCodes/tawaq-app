# Hasanat Improvement Checklist

Use this file as a living checklist while iterating on DX, performance, structure, and UI polish. Every item includes a short rationale plus a concrete code snippet or scaffold to jump-start the change.

---

## Project Foundation & Documentation

- [ ] **Standardize presentation folder naming (`screens/` vs `pages/`)**
  - **Why**: Consistent naming keeps imports predictable, avoids duplicate exports, and clarifies intent when onboarding new contributors.
  - **Try this**:
    ```none
    lib/
      feature/
        prayer/
          presentation/
            screens/
            widgets/
        settings/
          presentation/
            screens/
            widgets/
        quran/
          presentation/
            screens/
    ```
  - Update barrel files or exports after renaming to avoid stale paths.

- [ ] **Refresh `README.md` and add `docs/architecture.md`**
  - **Why**: Communicates project vision, highlights features, and documents architectural choices for future contributors.
  - **Starter snippet** (`README.md`):
    ```markdown
    # Hasanat

    ## ✨ Features
    - Accurate prayer times with streak tracking
    - Quran reader powered by `mushaf_reader`
    - Theming, localization, and analytics widgets

    ## 🧱 Architecture
    Clean architecture with Riverpod + Drift + feature-first folders.

    ## 🚀 Getting Started
    ```
  - Mirror the details in `docs/architecture.md` (layer diagrams, provider graph, localization flow).

- [ ] **Block generated artifacts from Git**
  - **Why**: Prevents merge noise and keeps PRs reviewable.
  - **Snippet** (`.gitignore`):
    ```gitignore
    # Generated code
    *.g.dart
    *.freezed.dart
    *.gr.dart
    .dart_tool/
    build/
    ```

---

## Tooling, Linting & Workflow

- [ ] **Tighten lint rules for consistent style**
  - **Why**: Catches regressions early (e.g., missing `const`, unawaited futures) and enforces a shared style.
  - **Snippet** (`analysis_options.yaml`):
    ```yaml
    linter:
      rules:
        prefer_final_locals: true
        prefer_final_in_for_each: true
        avoid_unnecessary_containers: true
        use_key_in_widget_constructors: true
        avoid_print: true
        sized_box_for_whitespace: true
        cascade_invocations: true
    ```

- [ ] **Introduce a pre-commit hook**
  - **Why**: Fail fast on formatting, tests, and analyzer warnings before code hits CI.
  - **Snippet** (`tool/pre-commit.sh`):
    ```bash
    #!/usr/bin/env bash
    set -euo pipefail

    flutter pub get
    dart format .
    flutter analyze
    flutter test
    ```
  - Wire it up locally: `chmod +x tool/pre-commit.sh` then `ln -s ../../tool/pre-commit.sh .git/hooks/pre-commit`.

- [ ] **Set up CI via GitHub Actions**
  - **Why**: Guarantees every PR passes format, analyze, and tests on a clean machine.
  - **Snippet** (`.github/workflows/ci.yaml`):
    ```yaml
    name: CI
    on: [push, pull_request]
    jobs:
      flutter:
        runs-on: ubuntu-latest
        steps:
          - uses: actions/checkout@v4
          - uses: subosito/flutter-action@v2
            with:
              flutter-version: "3.24.0"
          - run: flutter pub get
          - run: flutter analyze
          - run: flutter test
    ```

- [ ] **Expose build-time environment toggles**
  - **Why**: Simplifies feature gating (logging, debug menus) without code edits.
  - **Snippet** (`lib/config/env.dart`):
    ```dart
    abstract class Env {
      static const bool enableVerboseLogs = bool.fromEnvironment(
        'ENABLE_VERBOSE_LOGS',
        defaultValue: kDebugMode,
      );

      static const bool showDebugRoutes = bool.fromEnvironment(
        'SHOW_DEBUG_ROUTES',
        defaultValue: false,
      );
    }
    ```
  - Launch with `flutter run --dart-define=ENABLE_VERBOSE_LOGS=false`.

---

## State Management & Data Layer

- [ ] **Add `AsyncValue` convenience extensions**
  - **Why**: Reduces `value?.` noise and makes loading/error handling safer.
  - **Snippet** (`lib/core/utils/async_value_x.dart`):
    ```dart
    import 'package:flutter_riverpod/flutter_riverpod.dart';

    extension AsyncValueX<T> on AsyncValue<T> {
      T? get dataOrNull => when(
            data: (value) => value,
            loading: () => null,
            error: (_, __) => null,
          );

      R mapData<R>(R Function(T value) mapper, {R? fallback}) => when(
            data: (value) => mapper(value),
            loading: () => fallback ?? (throw StateError('loading')),
            error: (_, __) => fallback ?? (throw StateError('error')),
          );
    }
    ```

- [ ] **Use `.select` to avoid rebuilding entire completion maps**
  - **Why**: Minimizes widget rebuilds when only one prayer’s status changes.
  - **Snippet** (`current_prayer_card.dart`):
    ```dart
    final completion = ref.watch(
      prayerCompletionNotifierProvider.select(
        (map) => data.prayer != null ? map[data.prayer] : null,
      ),
    );
    ```

- [ ] **Convert `currentLocationTimeProvider` into a ticker stream**
  - **Why**: Current implementation returns a single snapshot; widgets never update as time passes.
  - **Snippet** (`prayer_data_providers.dart`):
    ```dart
    @riverpod
    Stream<DateTime> currentLocationTime(CurrentLocationTimeRef ref) async* {
      final location = ref.watch(
        prayerSettingsNotifierProvider.select(
          (settings) => settings.dataOrNull?.location,
        ),
      );

      yield DateTime.now().toLocation(location ?? PrayerSettings.defaultSettings().location);
      yield* Stream.periodic(
        const Duration(seconds: 30),
        (_) => DateTime.now().toLocation(
          location ?? PrayerSettings.defaultSettings().location,
        ),
      );
    }
    ```

- [ ] **Listen to time updates inside `PrayerTrackerWidget`**
  - **Why**: Using `ref.read` captures a stale `DateTime` and cards never refresh.
  - **Snippet** (`prayer_tracker_cards.dart`):
    ```dart
    final now = ref.watch(currentLocationTimeProvider).maybeWhen(
      data: (value) => value,
      orElse: () => DateTime.now(),
    );
    ```

- [ ] **Replace `while (true)` loop in `PrayerCard` provider with `Stream.periodic`**
  - **Why**: Avoids manual delays, respects cancelation, and keeps timers tied to provider lifecycle.
  - **Snippet** (`prayer_card_provider.dart`):
    ```dart
    @riverpod
    Stream<PrayerCardInfo> prayerCard(PrayerCardRef ref) async* {
      final ticker = Stream.periodic(const Duration(seconds: 1));
      await for (final _ in ticker) {
        if (ref.isDisposed) break;
        yield _buildCardSnapshot(ref);
      }
    }
    ```

- [ ] **Cache `_currentTime` during service calls**
  - **Why**: Multiple method calls within a tick shouldn’t compute different times.
  - **Snippet** (`prayer_service.dart`):
    ```dart
    class PrayerService {
      TZDateTime? _cachedNow;

      TZDateTime _now() => _cachedNow ??=
          TZDateTime.from(DateTime.now(), _settings.location);

      void resetClock() => _cachedNow = null;
    }
    ```

- [ ] **Return `Result` objects from database writes/reads**
  - **Why**: Connects Drift failures to UI states without stack traces in the console.
  - **Snippet** (`prayer_database.dart`):
    ```dart
    sealed class DbResult<T> {
      const DbResult();
    }
    class DbSuccess<T> extends DbResult<T> {
      final T value;
      const DbSuccess(this.value);
    }
    class DbFailure<T> extends DbResult<T> {
      final Object error;
      final StackTrace stack;
      const DbFailure(this.error, this.stack);
    }

    Future<DbResult<void>> deleteCompletion(int id) async {
      try {
        await (delete(prayerCompletions)..where((tbl) => tbl.id.equals(id))).go();
        return const DbSuccess(null);
      } catch (e, stack) {
        _log.handle(e, stack);
        return DbFailure(e, stack);
      }
    }
    ```

- [ ] **Short-circuit unchanged settings updates**
  - **Why**: Prevents redundant disk writes and provider churn.
  - **Snippet** (`settings_provider.dart`):
    ```dart
    void setCoordinates(Coordinates next) {
      final current = state.dataOrNull;
      if (current == null || current.coordinates == next) return;
      final updated = current.copyWith(coordinates: next);
      _persist(updated);
    }
    ```

---

## UI & UX Polish

- [ ] **Fix optional widget list syntax in `ShellAppBar` & lift the Hijri ticker into a provider**
  - **Why**: The current `[ ?widget ]` syntax is invalid Dart, and recreating `Stream.periodic` in `build` wastes resources.
  - **Snippet** (`shell_app_bar.dart` + provider):
    ```dart
    final nearWidgets = [
      if (locationChip != null) locationChip,
      const Spacer(),
      Text(ref.watch(hijriClockProvider)),
    ];
    ```
    ```dart
    @riverpod
    Stream<String> hijriClock(HijriClockRef ref) async* {
      final locale = ref.watch(localeNotifierProvider).dataOrNull;
      yield _formatHijri(locale);
      yield* Stream.periodic(
        const Duration(seconds: 1),
        (_) => _formatHijri(locale),
      );
    }
    ```

- [ ] **Use `ref.watch` (not `ref.read`) in `ShellSidebar` and remove no-op `setState`**
  - **Why**: Ensures navigation labels react to localization/theme changes and avoids unnecessary rebuilds.
  - **Snippet** (`shell_sidebar.dart`):
    ```dart
    final mainRoutes = ref.watch(mainRoutesProvider(context.l10n));

    onPress: () => context.go(e.path);
    ```

- [ ] **Same cleanup for `ShellBottomNavigationBar`**
  - **Snippet** (`shell_navigation_bar.dart`):
    ```dart
    onChange: (index) => context.go(routes[index].path);
    ```

- [ ] **Centralize spacing/animation tokens**
  - **Why**: Prevents hard-coded magic numbers and keeps themes consistent between pages.
  - **Snippet** (`lib/core/design/tokens.dart`):
    ```dart
    class Spacing {
      static const xs = 4.0;
      static const sm = 8.0;
      static const md = 12.0;
      static const lg = 16.0;
      static const xl = 24.0;
    }

    class MotionDurations {
      static const swift = Duration(milliseconds: 150);
      static const regular = Duration(milliseconds: 300);
      static const leisurely = Duration(milliseconds: 450);
    }
    ```

- [ ] **Upgrade `QuranScreen` beyond a placeholder**
  - **Why**: Route currently renders an empty column; this is confusing in production builds.
  - **Snippet** (`quran_screen.dart`):
    ```dart
    class QuranScreen extends StatelessWidget {
      const QuranScreen({super.key});

      @override
      Widget build(BuildContext context) {
        return FScaffold(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(FIcons.bookOpen, size: 64),
                SizedBox(height: Spacing.md),
                Text('Quran reader coming soon'),
              ],
            ),
          ),
        );
      }
  }
    ```

- [ ] **Derive hover/mouse effects from theme token helpers**
  - **Why**: Keeps hover elevation and colors in sync when themes change.
  - Consider a helper like `HoverStyle neumorphicHover(FThemeData theme)`.

---

## Logging & Observability

- [ ] **Wrap Talker logging with level-aware helpers**
  - **Why**: Current providers spam `info` logs even in release; make it conditional.
  - **Snippet** (`core/logging/app_logger.dart`):
    ```dart
    class AppLogger {
      AppLogger(this._talker);
      final Talker _talker;

      void debug(String message) {
        if (Env.enableVerboseLogs) _talker.debug(message);
      }

      void info(String message) {
        if (Env.enableVerboseLogs) _talker.info(message);
      }

      void error(Object error, StackTrace stack, [String? hint]) {
        _talker.handle(error, stack, hint);
      }
    }
    ```
  - Inject `AppLogger` via providers instead of `talkerNotifierProvider` directly.

- [ ] **Add structured error surfaces in `AsyncValue.when` branches**
  - **Why**: Show actionable retry buttons instead of raw `toString()` messages.
  - **Snippet** (`prayer_table.dart`):
    ```dart
    error: (error, _) => ErrorCard(
      message: context.l10n.prayerTableError,
      onRetry: () => ref.invalidate(prayerTableProvider(l10n)),
    ),
    ```

---

## Testing & Quality Gates

- [ ] **Organize tests into unit/widget/integration suites**
  - **Why**: Makes it easier to run fast suites locally and heavier flows in CI.
  - **Suggested layout**:
    ```none
    test/
      unit/
        domain/
          prayer_service_test.dart
      widget/
        presentation/
          prayer_page_test.dart
      integration/
        prayer_tracking_flow_test.dart
    ```

- [ ] **Add golden tests for critical cards (PrayerCard, PrayerTable)**
  - **Why**: Guard against layout regressions when tweaking themes.
  - **Snippet**:
    ```dart
    testGoldens('Prayer card dark mode', (tester) async {
      await tester.pumpWidget(buildPrayerCard(dark: true));
      await screenMatchesGolden(tester, 'prayer_card_dark');
    });
    ```

- [ ] **Smoke-test Drift migrations**
  - **Why**: Schema changes should be reproducible and reversible.
  - Use `drift_dev`'s `schema` tool or custom integration tests.

---

## Additional Nice-to-Haves

- [ ] **Bundle quick-start scripts (`make setup`, `make analyze`)**
  - Speeds up onboarding with reproducible commands.

- [ ] **Instrument critical flows (prayer completion, theme toggle) with analytics hooks**
  - Useful if you later plug in Firebase Analytics or Sentry breadcrumbs.

- [ ] **Set up localization linting**
  - Ensure every key in `AppLocalizations` has translations in both Arabic and English.

---

### How to Use This Document

1. Check off items as you implement them.
2. Feel free to extend the list with feature-specific improvements.
3. Re-run the "Additional Improvements" scan periodically; new insights appear as the codebase evolves.

---

## Routing & App Lifecycle

- [ ] Make `appRouter` reactive to locale/theme changes
  - Why: Route labels and transition styling won’t update after toggling language/theme because `appRouter` is built with `read()` once. Either keep route names stable and localize only in UI widgets, or watch locale/theme so the shell reflects changes.
  - Snippet (`lib/core/routing/route_provider.dart`):
    ```dart
    @riverpod
    GoRouter appRouter(Ref ref) {
      final _ = ref.watch(localeNotifierProvider); // re-create on locale change
      final theme = ref.watch(themeNotifierProvider).valueOrNull ?? defaultTheme;
      final routes = [
        ...ref.read(mainRoutesProvider(_.valueOrNull == null ? null : null)),
        ...ref.read(secondaryRoutesProvider(null)),
      ];
      return GoRouter(
        observers: [TalkerRouteObserver(ref.read(talkerNotifierProvider))],
        routes: _generateRoutes(routes, theme, ref.read(talkerNotifierProvider)),
        initialLocation: '/prayer',
      );
    }
    ```

- [ ] Adopt typed routes (optional)
  - Why: Avoid stringly-typed paths and ease refactors. Consider `go_router_builder` or a small `AppPath` enum/consts consumed by sidebar/bottom bar.

---

## Tooling, Linting & Workflow (additions)

- [ ] Strengthen lints for maintainability
  - Why: Catch subtle bugs and enforce consistency across the monorepo.
  - Snippet (`analysis_options.yaml`):
    ```yaml
    linter:
      rules:
        always_use_package_imports: true
        unawaited_futures: true
        cancel_subscriptions: true
        prefer_single_quotes: true
        exhaustive_switches: true
        avoid_positional_boolean_parameters: true
        avoid_dynamic_calls: true
    ```

- [ ] Run codegen in hooks and CI
  - Why: Prevent stale `.g.dart`/freezed/riverpod outputs and part-file mismatches.
  - Snippet (pre-commit addition):
    ```bash
    dart run build_runner build --delete-conflicting-outputs
    ```
  - Snippet (CI step):
    ```yaml
    - run: dart run build_runner build --delete-conflicting-outputs
    ```

- [ ] Automated dependency updates
  - Why: Keep SDK and packages fresh with minimal manual effort. Enable Renovate or Dependabot with a Flutter preset.

- [ ] Monorepo tooling with Melos
  - Why: You already have `packages/` (adhan_dart, dyn_mouse_scroll, mushaf_reader). Melos standardizes bootstrap, scripts, and versioning.
  - Starter (`melos.yaml`):
    ```yaml
    name: hasanat
    packages:
      - packages/**
    command:
      bootstrap:
        runPubGetInParallel: true
    scripts:
      analyze: melos exec -- flutter analyze
      test: melos exec --dir-exists=test -- flutter test
      gen: melos exec -- dart run build_runner build -d
    ```

---

## State Management & Data Layer (additions)

- [ ] Introduce a `Clock` abstraction and shared `TickerService`
  - Why: Decouple time from `DateTime.now()` for deterministic tests and provide a single shared ticker to avoid multiple timers across widgets/providers.
  - Snippet (`lib/core/time/clock.dart`):
    ```dart
    typedef Now = DateTime Function();
    final clockProvider = Provider<Now>((_) => DateTime.now);

    @riverpod
    Stream<DateTime> secondTicker(SecondTickerRef ref) async* {
      yield ref.read(clockProvider)();
      yield* Stream.periodic(const Duration(seconds: 1), (_) => ref.read(clockProvider)());
    }
    ```
  - Use in `PrayerService`/UI instead of calling `DateTime.now()` directly.

- [ ] Fix Riverpod part name mismatch
  - Why: `prayer_card_provider.dart` declares `part 'prayer_provider.g.dart';`, which breaks codegen.
  - Action: Rename to `part 'prayer_card_provider.g.dart';` and re-run build_runner.

- [ ] Centralize time tick sources
  - Why: `Stream.periodic` exists in multiple places (table, app bar, prayer card). Provide `secondTicker`/`minuteTicker` providers and consume via `ref.watch` to avoid drift and redundant timers.

---

## UI & UX Polish (additions)

- [ ] Precache and downscale prayer images
  - Why: Large images in `CurrentPrayerCard` can cause jank on first paint and waste memory.
  - Snippet (precache, e.g., in `PrayerPage` init or a bootstrap provider):
    ```dart
    for (final p in Prayer.values) {
      precacheImage(AssetImage(p.imagePath), context);
    }
    ```
  - Snippet (downscale in `DecorationImage`):
    ```dart
    image: ResizeImage(
      AssetImage(data.prayer.imagePath),
      cacheWidth: (MediaQuery.sizeOf(context).width * 0.6).toInt(),
    ),
    ```

- [ ] Guard desktop-only APIs
  - Why: `window_manager` isn’t available on web/mobile; guard initialization in `main()`.
  - Snippet (`lib/main.dart`):
    ```dart
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      await windowManager.ensureInitialized();
      // window options...
    }
    ```

- [ ] Accessibility pass
  - Why: Ensure minimum tap targets, semantics, and text scaling.
  - Add `Semantics` to badges/icons (completion status), verify contrast, and test with `MediaQuery.textScaleFactorOf(context) >= 1.5`.

---

## Logging & Observability (additions)

- [ ] Silence Riverpod state dumps in release
  - Why: `TalkerRiverpodObserver` with `printStateFullData: true` is noisy and can leak data in prod.
  - Action: Guard with build-time flag or `kReleaseMode` and set `printStateFullData: false` in release builds.

---

## Testing & Quality Gates (additions)

- [ ] Test time-dependent logic with `Clock`
  - Why: With a `clockProvider`, freeze time in tests to assert countdowns, next/current prayer, and streaks deterministically.
  - Snippet:
    ```dart
    final container = ProviderContainer(overrides: [
      clockProvider.overrideWithValue(() => DateTime(2025, 1, 1, 5, 0)),
    ]);
    ```

- [ ] CI: run build_runner and cache goldens
  - Why: Ensure generated files are current and golden tests validated on PRs.

---

## Database & Persistence

- [ ] Enable WAL and pragmatic PRAGMAs for SQLite
  - Why: Better concurrency and fewer fsyncs improve UI responsiveness.
  - Snippet (`prayer_database.dart`):
    ```dart
    final database = LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'prayer.db'));
      return NativeDatabase(file, setup: (rawDb) async {
        await rawDb.execute('PRAGMA journal_mode=WAL;');
        await rawDb.execute('PRAGMA synchronous=NORMAL;');
        await rawDb.execute('PRAGMA foreign_keys=ON;');
        await rawDb.execute('PRAGMA busy_timeout=5000;');
      });
    });
    ```

- [ ] Unique per-day completion constraint
  - Why: Prevent multiple rows for the same prayer on the same local day; simplifies upsert logic.
  - Approach: Add a `dayKey` integer column (e.g., `yyyyMMdd` in local tz) and unique index on `(dayKey, prayer)`.
  - Snippet (table sketch):
    ```dart
    IntColumn get dayKey => integer()();
    @override
    List<Set<Column>> get uniqueKeys => [{dayKey, prayer}];
    ```
  - Compute `dayKey` in repo/service when inserting, based on user location tz.

- [ ] Run Drift in background isolate (optional)
  - Why: Heavy counts/aggregations won’t block the UI thread.
  - Snippet:
    ```dart
    final db = NativeDatabase.createInBackground(file);
    ```

---

## Additional Nice-to-Haves (additions)

- [ ] Android build optimizations
  - Enable R8/shrinker and split-per-ABI in `android/app/build.gradle` to reduce APK size.

- [ ] Custom VS Code tasks
  - Add `.vscode/tasks.json` for `analyze`, `test`, `gen`, and `run` to streamline DX.
