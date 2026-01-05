# Mushaf Reader Example

This is a complete example of a Quran application built using the `mushaf_reader` package.

## Features Demonstrated

- **Mushaf Page Rendering**: Uses `MushafPage` to render Quran pages with correct fonts and layout.
- **Navigation**: `PageView` for smooth page turning.
- **State Management**: Uses `MushafController` for initialization and data fetching.
- **Performance**: Demonstrates `preloadPages` for smooth scrolling.
- **Interactivity**: Tap on Ayahs to see details (Surah, Ayah number, text).
- **Immersive Mode**: Tap the page to toggle UI controls.
- **Surah Index**: A bottom sheet to jump to specific Surahs.
- **RTL Support**: Correctly configured `Directionality` for Arabic text.

## Getting Started

1.  Ensure you have Flutter installed.
2.  Run `flutter pub get` in this directory.
3.  Run `flutter run`.

## Code Structure

- `main.dart`: Contains the entire example application, including the `MushafExampleApp` widget, `QuranReaderScreen`, and helper widgets like `SurahIndexSheet`.
