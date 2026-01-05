# mushaf_reader

A Flutter package for rendering Quran pages using QCF4 (Quran Complex Fonts v4) with pixel-perfect Medina Mushaf layout.

## What This Package Does

Renders Quran text exactly as it appears in the printed Medina Mushaf using 605 specialized fonts:
- **604 page fonts** (QCF4_001 to QCF4_604): Each page has its own font with pre-positioned glyphs
- **1 shared font** (QCF4_BSML): Contains Bismillah, Surah names, and Juz markers

The package includes a pre-populated SQLite database with all Quran data, page layouts, and glyph mappings.

## Requirements

- Flutter SDK ≥3.8.1
- Dart SDK ≥3.8.1
- The 605 QCF4 OTF font files in `assets/otf_fonts/`
- The pre-populated `quran.db` SQLite database in `assets/`

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
      onAyahTap: (info) => print('Tapped ${info.reference}'),
    );
  }
}
```

### 3. Display a Single Page

```dart
MushafPage(
  pageNumber: 1,  // 1-604
  width: 400,
  onAyahTap: (int ayahId) {
    print('Tapped ayah $ayahId');
  },
)
```

### 4. Fetch Individual Ayahs

```dart
final controller = MushafReaderController();

final ayah = await controller.getAyah(ayahId);
print('Surah ${ayah.surah}, Ayah ${ayah.numberInSurah}');
print('Text: ${ayah.text}');
```

## Architecture

```
lib/src/
├── core/
│   ├── fonts.dart          # MushafFonts - font family helpers
│   ├── extensions.dart     # Model conversions, Hindu-Arabic numerals
│   └── db_init*.dart       # Platform-specific DB initialization
├── data/
│   ├── database/           # Drift SQLite database
│   ├── models/             # Immutable data models (Freezed)
│   └── repository/         # Data access layer with LRU caching
├── logic/
│   └── mushaf_controller.dart  # Singleton API
└── presentation/
    ├── controllers/        # MushafPageController (selection state)
    ├── screens/            # MushafPage widget
    └── widgets/            # Ayah, Basmalah, Juz, SurahHeader, etc.
```

## Database Schema

The `quran.db` contains:

| Table | Description |
|-------|-------------|
| `surahs` | 114 rows: id, name, revelation type, ayah count |
| `ayahs` | 6236 rows: id, surah, number_in_surah, text, page, juz |
| `page_layouts` | Glyph positions: page, ayah_id, line_start, line_end |
| `juzs` | 30 rows: number, glyph (QCF4_BSML character) |
| `metadata` | Key-value pairs (db version, etc.) |

## Key Classes

### MushafController
Singleton entry point. Provides:
- `init()` - Initialize database (call once)
- `getPage(int)` - Returns `QuranPageModel` with all page data
- `getAyah(int)` - Returns `AyahModel` for a specific ayah

### QuranPageModel
Contains everything needed to render a page:
- `pageNumber`, `glyphText` (the full page glyph string)
- `surahBlocks` - List of Surahs on this page with their Ayah fragments
- `juz` - Juz info if a new Juz starts on this page
- `hasBasmalah` - Whether to show Bismillah

### MushafPage
The main rendering widget. Handles:
- Responsive scaling based on `width`
- Per-ayah tap detection
- Ayah highlighting
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
| Web | Drift WASM with IndexedDB storage |

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

### Selection State

Use `MushafPageController` with `ChangeNotifierProvider` for ayah selection:

```dart
ChangeNotifierProvider(
  create: (_) => MushafPageController(),
  child: Consumer<MushafPageController>(
    builder: (context, controller, _) {
      return MushafPage(
        page: 1,
        pageController: controller,
        onTapAyah: (ayahId) {
          // Handle tap
        },
      );
    },
  ),
)
```

## Dependencies

- `drift` + `sqlite3_flutter_libs` - SQLite database
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
