# Mushaf Reader Example

Runnable showcase for `mushaf_reader` widgets with English and Arabic UI (via [slang](https://pub.dev/packages/slang)).

## Demos

| Section | Screen | What it shows |
| ------- | ------ | ------------- |
| **Readers** | MushafReader | Full swipeable reader with ayah tap snackbars |
| | Two-page spread | `MushafReader(pagesPerViewport: 2)` |
| **Pages & excerpts** | MushafPage | Single page with page navigation and ayah taps |
| | MushafPageRange share card | Ayah range in a mock share card (page picker, header/basmalah toggles) |
| | Cross-page range | `MushafPageRange.contiguous` spanning multiple pages |
| **Building blocks** | Standalone widgets | `AyahWidget`, `BasmalahWidget`, `SurahHeaderWidget.fromSurahNumber`, etc. |

## Run

From this directory:

```bash
flutter pub get
dart run slang   # after editing lib/i18n/*.i18n.json
flutter run
```

## Localization

- Strings live in `lib/i18n/en.i18n.json` and `lib/i18n/ar.i18n.json`.
- Regenerate Dart bindings: `dart run slang`
- Use the language icon in any screen app bar to switch between English and Arabic.

## Project layout

```
lib/
  main.dart              # App entry + grouped catalog
  demo_catalog.dart      # Demo metadata
  demo_scaffold.dart     # Shared app bar + locale toggle
  demo_widgets.dart      # Page navigator, share card, loading helpers
  demos/                 # Individual demo screens
  i18n/                  # slang JSON + generated strings.g.dart
```
