# State and storage

## Riverpod

Riverpod is the app-state system, and `riverpod_generator` produces the provider boilerplate. `@riverpod` is normally auto-disposed; `@Riverpod(keepAlive: true)` is for long-lived services or singleton-like state. Async providers expose `AsyncValue`, so callers must model hydration/loading/error instead of assuming values exist immediately.

Use `ConsumerWidget` for provider-only widgets, `HookWidget` for local hooks, and `HookConsumerWidget` for both. Edit annotated provider sources, never their generated `*.g.dart` files.

## Persisted settings

Durable settings are usually Riverpod notifiers with `@JsonPersist()`, stored through shared `SettingsStorage` in the Hive `riverpod_persist` box.

| Provider owner | Durable concern |
| --- | --- |
| Core locale | selected language |
| Prayer | location, calculation options, adhan and iqamah preferences |
| Settings/theme | palette, light/dark mode, global UI text scale |
| Desktop | tray, window, and startup preferences |
| Feature screen settings | panel ratios, restore checkpoints, display preferences |

Follow the existing `_commit()` convention: guard unhydrated state, transform the current value, skip no-op writes, persist, and log. Keep transient selections/search sessions in normal providers rather than persistence.

## Hive and SQLite

Hive/Hivez stores mutable user data: prayer completions, favourites, recent searches, notes, and persisted preferences. Adapter declarations are in [`lib/hive/hive_adapters.dart`](../../lib/hive/hive_adapters.dart), generated, and registered during bootstrap.

SQLite asset databases provide read-only reference content. [`AssetDatabaseService`](../../lib/core/database/asset_database_service.dart) version-copies an asset database into app storage and caches open connections; Quran sources use it. Muslim Fortress performs an analogous repository-owned copy/version process for its packaged databases.

## Time is a shared source of truth

[`appClockProvider`](../../lib/core/utils/app_clock_provider.dart) is the shared one-Hz wall clock. Time-based UI should derive from it, and tests should override it; do not introduce widget timers or `DateTime.now()` loops.

Prayer is more specific: [`prayerDayProvider`](../../lib/feature/prayer/presentation/provider/prayer_day.dart) is the live, timezone-aware source of truth. It is computed from effective prayer settings and emits a `PrayerDaySnapshot` every second. Use its derived providers for current prayer, countdown, schedule highlight, card state, and calendar day. Widgets must not recalculate prayer times.

## Arabic normalization

`normalizeArabicForSearch` is for matching: normalize both the query and candidate. `ArabicTextNormalizer.normalize` is for commentary/tafsir display typography, not search. They solve different problems and are not interchangeable.
