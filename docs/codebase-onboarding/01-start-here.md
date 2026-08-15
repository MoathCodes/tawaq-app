# Start here

## What Tawaq is

Tawaq is a Flutter app for prayer times, Quran reading and study, Hadith search, and Hisn al-Muslim. Desktop is first-class, while the UI adapts to smaller screens.

| Feature | Entry area | Main responsibility |
| --- | --- | --- |
| Prayer | `feature/prayer` | live prayer times, completions, settings, analytics |
| Quran | `feature/quran` | mushaf, tafsir, translations, notes, recitation |
| Hadith | `feature/hadith` | Dorar search, results, favourites, recent searches |
| Muslim Fortress | `feature/muslim_fortress` | chapters, duas, commentary, bookmarks |
| Settings | `feature/settings` | settings UI and appearance controls |
| Onboarding | `feature/onboarding` + `app/onboarding` | first-run state and setup experience |

## Set up and run

Flutter is pinned through FVM. Use its commands from the repository root.

```bash
git submodule update --init -- packages/adhan_dart packages/dorar_hadith
fvm install
fvm exec bash tool/codegen.sh
fvm flutter run
```

Only `adhan_dart` and `dorar_hadith` are submodules; other local `packages/` dependencies are vendored.

## Repository map

`lib/main.dart` is the entry point. `lib/app` owns routing, shell, onboarding composition, and desktop orchestration. `lib/core` contains reusable feature-neutral infrastructure. `lib/feature` contains product features. `lib/theme`, `lib/hive`, `lib/l10n`, and `lib/gen` respectively contain theming, Hive adapters, localization, and generated asset/font accessors. `test` contains architecture, unit, widget, and feature tests; `tool` contains scripts such as code generation.

Root `*.g.dart` and `*.freezed.dart` are ignored generated outputs. Edit their annotated source and regenerate; never edit them directly.

## First rules to internalize

- Use `context.theme` and shared theme tokens; avoid hard-coded status/accent colors.
- Use generated Riverpod providers for async state.
- Keep `core` feature-neutral; feature domain code cannot import its data or presentation layers.
- Navigate through typed route classes, not literal route strings.
- Keep preferences in the owning feature/provider, and session state ephemeral.
- Use shared live providers for time and prayer computation.
- Treat Arabic search normalization and display normalization as separate operations.
