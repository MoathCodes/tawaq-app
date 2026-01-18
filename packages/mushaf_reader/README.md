# mushaf_reader

A Flutter package for rendering Quran pages using QCF4 (Quran Complex Fonts v4) with pixel-perfect Medina Mushaf layout.

## What This Package Does

Renders Quran text exactly as it appears in the printed Medina Mushaf using 605 specialized fonts:
- **604 page fonts** (QCF4_001 to QCF4_604): Each page has its own font with pre-positioned glyphs
- **1 shared font** (QCF4_BSML): Contains Bismillah, Surah names, and Juz markers

The package includes pre-populated Hive boxes with all Quran data, page layouts, and glyph mappings.

## Requirements

- Flutter SDK ≥3.8.1
- Dart SDK ≥3.8.1
- The 605 QCF4 OTF font files in `assets/otf_fonts/`
- The pre-populated Hive boxes in `assets/hive/`

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  mushaf_reader:
    path: packages/mushaf_reader  # or your path
```

## Setup

### 1. Initialize the Library

Call once at app startup in `main()` before `runApp`:

```dart
import 'package:flutter/material.dart';
import 'package:mushaf_reader/mushaf_reader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MushafReaderLibrary.ensureInitialized();
  runApp(MyApp());
}
```

### 2. Use the Reader Widget

```dart
class QuranScreen extends StatefulWidget {
  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  late final MushafReaderController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MushafReaderController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MushafReader(
      controller: _controller,
      onAyahTap: (ayah) => print('Tapped ${ayah.reference}'),
    );
  }
}
```

### 3. Display a Single Page

```dart
MushafPage(
  page: 1,  // 1-604
  onTapAyah: (int ayahId) {
    print('Tapped ayah $ayahId');
  },
)
```

### 4. Fetch Individual Ayahs

```dart
final controller = MushafReaderController();

final ayah = await controller.getAyah(ayahId);
print('Surah ${ayah.surahNumber}, Ayah ${ayah.numberInSurah}');
print('Text: ${ayah.text}');
```

## Architecture

```
lib/src/
├── core/
│   ├── fonts.dart          # MushafFonts - font family helpers
│   ├── extensions.dart     # Model conversions, Hindu-Arabic numerals
├── data/
│   ├── hive/               # Hive storage implementation
│   ├── models/             # Immutable data models (Freezed)
│   └── repository/         # Data access layer with LRU caching
├── logic/
│   └── mushaf_reader_controller.dart  # Unified controller
└── presentation/
    ├── screens/            # MushafPage, MushafReader widgets
    └── widgets/            # Ayah, Basmalah, Juz, SurahHeader, etc.
```

## Database Schema

The Hive boxes contain:

- `surahs`: 114 entries (id, name, glyph, etc.)
- `ayahs`: 6236 entries (id, surah, number, text, page, juz)
- `juzs`: 30 entries (number, glyph)
- `pageLayouts`: Glyph positioning data per page
- `metadata`: Key-value pairs

## Key Classes

### MushafReaderController
Unified controller for navigation, state, and data access. Provides:
- `jumpToPage(int)`, `nextPage()`, `previousPage()`
- `jumpToSurah(int)`, `jumpToJuz(int)`
- `selectAyah(int)` - Highlight specific ayah
- `getPageInfo(int)` - Returns `MushafPageInfo`

### QuranPage
Contains everything needed to render a page:
- `pageNumber`, `glyphText` (the full page glyph string)
- `surahs` - List of Surah blocks on this page
- `lines` - Line layout information
- `juzNumber` - Juz info

### MushafPage
The main rendering widget. Handles:
- Responsive scaling
- Per-ayah tap detection and highlighting
- Surah headers, Juz markers, Basmalah

### MushafFonts
Font helpers:
```dart
MushafFonts.forPage(15)       // Returns 'QCF4_015'
MushafFonts.pageStyle(family) // TextStyle for page content
MushafFonts.basmalahStyle     // TextStyle for headers
```

## Platform Support

| Platform | Database Loading |
|----------|------------------|
| iOS, Android, macOS, Windows, Linux | Copies from assets to documents directory |
| Web | Supported via Hive |

## Customization

### Responsive Scaling

The Mushaf automatically scales to fit the available space. Use `MushafScale` to control scaling behavior:

```dart
MushafPage(
  page: 1,
  style: MushafStyle(
    // Auto-scale with constraints
    scale: MushafScale(
      minScale: 0.6,  // Don't shrink below 60%
      maxScale: 1.5,  // Don't grow above 150%
    ),
  ),
)
```

#### Fixed Scale Factor

Disable auto-scaling with a fixed multiplier:

```dart
MushafScale(factor: 1.2)  // Always 20% larger than default
```

#### Fixed Font Sizes

For precise control, specify exact font sizes:

```dart
MushafScale(
  ayahFontSize: 24,        // Ayah text
  basmalahFontSize: 18,    // Basmalah, Surah names, Juz labels
  pageNumberFontSize: 16,  // Page numbers
)
```

### Custom Styling

```dart
MushafPage(
  page: 1,
  style: MushafStyle(
    highlightColor: Colors.amber.withOpacity(0.3),
    backgroundColor: Color(0xFFFFFBF0),  // Cream background
    activeAyahStyle: TextStyle(
      color: Colors.brown,
      backgroundColor: Colors.amber.withOpacity(0.3),
    ),
  ),
)
```

## Dependencies

- `hive_ce` + `hive_ce_flutter` - Data storage
- `freezed_annotation` - Immutable models
- `flutter_svg` - Surah header banners
- `path_provider` - Native file paths

## Font Files

The package expects 605 OTF files in `assets/otf_fonts/`:
- `QCF4_001.otf` through `QCF4_604.otf`
- `QCF4_BSML.otf`

These must be declared in your app's `pubspec.yaml` or bundled with the package.

## Why Page-Specific Fonts?

Standard Unicode text rendering cannot replicate the precise glyph positioning of the Medina Mushaf. Each page font contains glyphs positioned exactly as they appear in the printed edition. The "text" stored in the database is actually a sequence of glyph codes that map to specific positions in each page's font.
