# Tawaq

Flutter desktop app for prayer times, Quran, Hadith, and Hisn al-Muslim.

## Clone

Only two packages are git submodules (`adhan_dart`, `dorar_hadith`). Everything else under `packages/` is vendored in this repo.

```bash
git clone <repo-url>
cd tawaq
git submodule update --init -- packages/adhan_dart packages/dorar_hadith
flutter pub get
```

`git clone --recurse-submodules` also works now that `.gitmodules` only lists those two paths.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

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
