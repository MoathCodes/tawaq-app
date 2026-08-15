# Tawaq

Flutter desktop app for prayer times, Quran, Hadith, and Hisn al-Muslim.

## Clone

Only two packages are git submodules (`adhan_dart`, `dorar_hadith`). Everything else under `packages/` is vendored in this repo.

```bash
git clone <repo-url>
cd tawaq
git submodule update --init -- packages/adhan_dart packages/dorar_hadith
fvm install
fvm exec bash tool/codegen.sh
```

`git clone --recurse-submodules` also works now that `.gitmodules` only lists those two paths.

`tool/codegen.sh` runs `build_runner` in `packages/mushaf_reader` before the app — path-package generated sources are not available from a fresh clone otherwise (root `.gitignore` ignores `*.g.dart` / `*.freezed.dart`). Run it through `fvm exec` so its internal `flutter` and `dart` commands use the project SDK.

## Getting Started

Install [FVM](https://fvm.app/documentation/getting-started/installation), then run `fvm install` from the repository root. FVM reads the exact official stable Flutter version from the tracked `.fvmrc`; CI reads the same file.

Use FVM for daily Flutter and Dart commands:

```bash
fvm flutter run
fvm flutter analyze
fvm flutter test
fvm dart run build_runner build
```

FVM normally configures VS Code's `dart.flutterSdkPath` automatically. Because `.vscode/` and `.fvm/` are local and ignored here, reload the VS Code window if the selected SDK does not update immediately.

## Upgrading Flutter

Change the project and CI to a new exact Flutter release with one command:

```bash
fvm use <new-exact-version>
fvm exec bash tool/codegen.sh
fvm flutter analyze
fvm flutter test
```

`fvm use` downloads the SDK, updates `.fvmrc`, refreshes the local SDK link, and resolves dependencies. Review and commit `.fvmrc` together with any intentional `pubspec.lock` changes; the workflows automatically follow the new pin. Do not use `flutter upgrade` for this exact-version workflow.

To test another Flutter release without changing the project pin, run:

```bash
fvm spawn <version> flutter test
```

## Testing builds (macOS / Windows)

Desktop bundles are built by the [Build desktop](.github/workflows/build-desktop.yml) workflow. It runs on demand (Actions tab → Build desktop → Run workflow) and on every `v*` tag, which also publishes a GitHub Release with plain download links (workflow artifacts require a GitHub login; release assets do not).

The builds are unsigned, so the OS will warn on first launch:

- **macOS** (Apple Silicon): unzip, move `Tawaq.app` to Applications, then remove the quarantine flag:
  ```bash
  xattr -dr com.apple.quarantine /Applications/Tawaq.app
  ```
  (Right-click → Open twice also works.)
- **Windows**: unzip the whole folder and run `tawaq.exe` from inside it — the DLLs and `data/` folder must stay beside the exe. SmartScreen will say "unknown publisher" → **More info → Run anyway**.

## References

Attributions and sources (expand as more bundled content is documented):

### Adhan audio

- [Athan-MP3](https://github.com/abodehq/Athan-MP3) — source for bundled adhan recordings
