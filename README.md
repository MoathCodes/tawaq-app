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

## References

Attributions and sources (expand as more bundled content is documented):

### Adhan audio

- [Athan-MP3](https://github.com/abodehq/Athan-MP3) — source for bundled adhan recordings
