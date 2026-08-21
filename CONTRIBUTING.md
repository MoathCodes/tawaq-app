# Contributing to Tawaq

Thanks for helping improve Tawaq. Please open an issue before starting substantial work so we can agree on the problem, scope, and user-facing result.

## Set up the project

Tawaq pins its Flutter SDK in `.fvmrc`. Install [FVM](https://fvm.app/documentation/getting-started/installation), then initialise the two git submodules and generate the project sources:

```bash
git submodule update --init -- packages/adhan_dart packages/dorar_hadith
fvm install
fvm exec bash tool/codegen.sh
```

Use FVM for every Flutter and Dart command in this repository:

```bash
fvm flutter run
fvm flutter analyze
fvm flutter test
```

## Before opening a pull request

- Keep changes focused on the agreed issue.
- Run `fvm flutter analyze` and `fvm flutter test`.
- Run `fvm dart run build_runner build` after app-level Riverpod, Freezed, route, Hive, or asset changes. Use `fvm exec bash tool/codegen.sh` when changing generated models in `packages/mushaf_reader` or after a fresh clone.
- Test Arabic and English layouts when changing visible UI.
- Add or update tests for behavioural changes.

The [codebase onboarding guide](docs/codebase-onboarding/README.md) explains the project structure, state management, theming, and feature boundaries.

## Pull requests

Explain the user-visible change, note any follow-up work, and include screenshots for visual changes. Do not include unrelated formatting or generated artifacts unless the change requires them.
