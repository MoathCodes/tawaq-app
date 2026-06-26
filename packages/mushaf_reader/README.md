

# mushaf_reader

A **minimal Flutter building block** for rendering the Madinah Mushaf using [QCF4](https://qurancomplex.gov.sa/) page fonts. Compose your own reader UI, navigation, settings, and app shell on top.

## What it is

- Authentic Medina Mushaf layout via 604 page-specific QCF4 fonts plus shared header glyphs
- Bundled Quran data (ayahs, surahs, juzs, page layouts) — no network required
- Composable widgets: full-page reader, single page, standalone ayah, decorative pieces
- Optional `[MushafReaderController](https://pub.dev/documentation/mushaf_reader/latest/mushaf_reader/MushafReaderController-class.html)` for page navigation, ayah selection, and data access
- `[MushafStyle.modify()](https://pub.dev/documentation/mushaf_reader/latest/mushaf_reader/MushafStyle/MushafStyle.modify.html)` for colors, text styles, and responsive scaling — not a design system

## What it is not

This package intentionally does **not** include:

- A complete Quran app (no app bar, tabs, bookmarks, or onboarding)
- Audio recitation, tafsir, translations, or search UI
- Opinionated theming beyond basic Mushaf styling
- Global state management — bring Riverpod, Bloc, or your own patterns
- Loading spinners — pass your own `loadingWidget` if you want one

If you need a full app experience, use this package as the rendering layer and build everything else yourself.

## Features


| Area                 | Included                                                                       |
| -------------------- | ------------------------------------------------------------------------------ |
| Page rendering       | `MushafPage`, `MushafPageRange`, `MushafReader` (`pagesPerViewport: 1` or `2`) |
| Ayah tap / highlight | Per-ayah selection with customizable highlight styles                          |
| Page chrome          | Surah headers, Basmalah, juz marker, page number                               |
| Data models          | `Ayah`, `Surah`, `Juz`, `Hizb`, `QuranPage`, `MushafPageInfo`                  |
| Navigation API       | `jumpToPage`, `jumpToSurah`, `jumpToJuz`, `jumpToHizb`, `jumpToAyah`, `searchAyahs` |
| Division bounds      | `juzAyahBounds`, `hizbAyahBounds` — global ayah id ranges per juz/hizb         |
| Constants & helpers  | `MushafConstants`, `Ayah.globalIdFor()`, `Ayah.hizb`, `AyahIdResolver`       |
| Granular rebuilds    | `MushafSelectionListenable`, `MushafPageListenable` — listen to part of the controller |
| Recitation helpers   | `SurahTiming`, `AyahTiming` — per-ayah ms offsets for your own audio layer     |
| Repository lifecycle | `HiveQuranRepository.acquire()` / `dispose()` — pair for owned instances; `instance` for read-only access |
| Callback typedefs    | `AyahTapCallback`, `AyahIdTapCallback`, `SurahTapCallback`, …                  |
| Fonts & scaling      | `MushafFonts`, `MushafScale`, `MushafTextStyleMerger`                          |


## Installation

From your Flutter project root:

```bash
flutter pub add mushaf_reader
```

This adds the latest compatible version to `pubspec.yaml` and resolves dependencies. QCF4 fonts, SVG chrome, and Hive Quran data are bundled in the package — no manual asset wiring.

## Initialization

Call once before `runApp`:

```dart
import 'package:flutter/material.dart';
import 'package:mushaf_reader/mushaf_reader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MushafReaderLibrary.ensureInitialized();
  runApp(const MyApp());
}
```

Optional: isolate Hive data under a subdirectory of the app documents folder:

```dart
await MushafReaderLibrary.ensureInitialized(subDirectory: 'my_app');
```

After updating `mushaf_reader`, run a **full rebuild** (not hot restart) so new Hive assets such as `search_index.hive` are bundled. Hot restart does not pick up new package assets.

```bash
flutter clean && flutter pub get && flutter run
```

## Minimal usage

Drop in a swipeable reader with ayah tap handling:

```dart
class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

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
      onAyahTap: (ayah) => debugPrint(ayah.reference),
    );
  }
}
```

Render a single page inside your own layout:

```dart
MushafPage(
  page: 1,
  onAyahIdTap: (ayahId) => debugPrint('ayah $ayahId'),
)
```

## Ayah range

Render a subset of ayahs on one page or across pages — without manually
filtering fragments or wiring basmalah rules. Wrap with your own card chrome,
footers, or image capture as needed.

```dart
// Single-page range
MushafPageRange.onPage(
  page: 1,
  startAyahId: 1,
  endAyahId: 3,
  style: MushafStyle.modify(
    ayah: (s) => s.copyWith(color: const Color(0xFF1B4332)),
  ),
  showSurahHeader: true,
  showBasmalah: true,
)

// Cross-page contiguous range
MushafPageRange.contiguous(
  startAyahId: 5,
  endAyahId: 12,
  controller: controller,
)
```

Use `[MushafPageRangeLayout](https://pub.dev/documentation/mushaf_reader/latest/mushaf_reader/MushafPageRangeLayout-class.html)` to check whether basmalah or surah headers *could* appear for a selection before enabling host toggles.

## Callbacks

Reader widgets and `MushafPage` use different callback shapes on purpose:


| Widget         | Callback      | Receives                                         |
| -------------- | ------------- | ------------------------------------------------ |
| `MushafReader` | `onAyahTap`   | Full `Ayah` model                                |
| `MushafPage`   | `onAyahIdTap` | Global ayah id (`1`–`MushafConstants.ayahCount`) |


Resolve an id to a model via the controller or repository:

```dart
MushafPage(
  page: 1,
  onAyahIdTap: (ayahId) async {
    final ayah = await controller.getAyah(ayahId);
    debugPrint(ayah.reference);
  },
)
```

## Two-page spread

```dart
MushafReader(
  pagesPerViewport: 2,
  onAyahTap: (ayah) => debugPrint(ayah.reference),
  onSpreadChanged: (info) => debugPrint(info.$1.pageNumber),
)
```

## Constants & ayah ids

Use `[MushafConstants](https://pub.dev/documentation/mushaf_reader/latest/mushaf_reader/MushafConstants-class.html)` instead of magic numbers:

```dart
PageView.builder(
  itemCount: MushafConstants.pageCount,
  itemBuilder: (_, index) => MushafPage(page: index + 1),
);
```

Convert surah + verse to a global id without I/O:

```dart
final id = Ayah.globalIdFor(surah: 2, ayahInSurah: 255); // 262
```

When you already have surah metadata from storage, `[AyahIdResolver](https://pub.dev/documentation/mushaf_reader/latest/mushaf_reader/AyahIdResolver-class.html)` offers the same mapping with custom start tables.

## Key widgets & controller


| API                                         | Role                                                                                                                       |
| ------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| `MushafReader`                              | Swipeable reader; `pagesPerViewport: 1` (default) or `2` for spreads                                                       |
| `MushafPage`                                | One Mushaf page — use in custom layouts                                                                                    |
| `MushafPageRange`                           | Ayah range on one or more pages — excerpts without manual fragment logic                                                   |
| `MushafReaderController`                    | Navigation (`jumpToJuz`, `jumpToHizb`, …), selection, async data (`getAyah`, `getHizb`, `getPageInfo`, `searchAyahs`, …); `juzAyahBounds` / `hizbAyahBounds`; exposes `repository` for direct `IQuranRepository` access |
| `AyahWidget`                                | Standalone ayah by global id or surah:ayah                                                                                 |
| `BasmalahWidget`, `SurahHeaderWidget`, etc. | Low-level pieces for custom UIs                                                                                            |


### Ayah search

`searchAyahs` reads from a pre-built `search_index.hive` asset. The search box opens on first use (~842 KB RAM); readers that never search pay zero extra memory. Call `warmUpSearchIndex()` when opening search UI to hide open latency on the first query:

```dart
await controller.warmUpSearchIndex();
final results = await controller.searchAyahs('الله');
```

Same method exists on `IQuranRepository` if you use the repository directly.

### Narrow listenables

`MushafReaderController` still implements `Listenable` for legacy `addListener` use, but prefer `controller.selection` or `controller.page` with `ListenableBuilder` so chrome rebuilds only when selection or page metadata changes:

```dart
ListenableBuilder(
  listenable: controller.page,
  builder: (context, _) => Text('Page ${controller.currentPage}'),
);
```

`MushafPage` already listens to `controller.selection` internally for ayah highlights.

### Recitation timing models

`SurahTiming` and `AyahTiming` are JSON-serializable helpers for host apps that fetch per-surah MP3 timing data themselves. They are **not** wired to a player — use `ayahAt(positionMs)` to drive ayah highlighting during playback.

### Repository reference counting

`HiveQuranRepository` is a process-wide singleton. Calling `HiveQuranRepository()` or `HiveQuranRepository.instance` returns the shared instance **without** changing the internal reference count — safe for widgets that only read cached metadata.

Owned lifetimes (e.g. `MushafReaderController`) call `HiveQuranRepository.acquire()` once and `dispose()` on teardown. Do **not** call `HiveQuranRepository()` from `build()`; pass `controller.repository` or an injected `IQuranRepository` instead.

`MushafReader` enables a sliding keep-alive window (current page ±1) inside its `PageView`. Standalone `MushafPage` widgets default to `keepAlive: false`.

## Customization hooks

**Styling** — modifier-only setup with `[MushafStyle.modify()](https://pub.dev/documentation/mushaf_reader/latest/mushaf_reader/MushafStyle/MushafStyle.modify.html)`:

```dart
MushafReader(
  style: MushafStyle.modify(
    ayah: (s) => s.copyWith(color: const Color(0xFF1B4332)),
    activeAyah: (s) => s.copyWith(
      backgroundColor: const Color(0xFF2D6A4F),
      color: Colors.white,
    ),
    scale: MushafScale(readingBoost: 1.08, minScale: 0.6, maxScale: 1.5),
  ),
)
```

Chain more tweaks with `.modify(...)`:

```dart
final style = MushafStyle.modify(
  ayah: (s) => s.copyWith(color: Colors.brown),
).modify(
  activeAyah: (s) => s.copyWith(backgroundColor: Colors.amber),
  scale: MushafScale(readingBoost: 1.08),
);
```

Use the `MushafStyle(...)` constructor when you need explicit `TextStyle` bases. Legacy `*StyleModifier` constructor params remain supported.

**Surah header banners** — light and dark precompiled SVGs (`.svg.vec`) are bundled. Override per theme:

```dart
MushafStyle(
  surahHeaderImage: 'assets/images/my_light_header.svg.vec',
  surahHeaderImageDark: 'assets/images/my_dark_header.svg.vec',
  headerSurahNameStyleModifier: (s) => s.copyWith(color: Colors.white),
)
```

When `isDark` is not set on `SurahHeaderWidget` / `MushafPageRange`, the banner follows `Theme.of(context).brightness`. Style the surah name on the banner with `headerSurahName` (or `surahName`) so ink contrasts with your banner asset.

Custom banner overrides support precompiled `.svg.vec` (recommended), raw `.svg` (runtime parse), or raster (`.png`, etc.). To precompile SVGs offline (same workflow as this package):

```bash
dart run vector_graphics_compiler -i my_banner.svg -o assets/my_banner.svg.vec \
  --no-optimize-masks --no-optimize-clips --no-optimize-overdraw
```

Sources for the default banners live in `tool/svg/`; regenerate shipped assets with `tool/compile_surah_headers.sh`.

Raster overrides use `Image.asset` with decode-size hints.

**Loading** — the package defaults to no spinner (`MushafLoading.none`). Pass your own:

```dart
MushafReader(
  loadingWidget: const CircularProgressIndicator(),
  pageLoadingWidget: const CircularProgressIndicator(),
)
```

**Read-only mushaf** — disable ayah interaction:

```dart
MushafPage(page: 1, enableAyahHighlight: false)
```

**RTL** — `MushafReader` defaults to `TextDirection.rtl`. Wrap your app or override `textDirection` as needed.

## Example app

See `[example/](example/)` for a demo catalog (`MushafReader`, two-page spread, `MushafPage`, `MushafPageRange`, standalone widgets). From the package root:

```bash
cd example && flutter pub get && flutter run
```

## API documentation

- [pub.dev API reference](https://pub.dev/documentation/mushaf_reader/latest/)
- Generate locally: `dart doc .`

## Bundled assets

Shipped with the package (declared in `pubspec.yaml`):


| Asset               | Purpose                                                  |
| ------------------- | -------------------------------------------------------- |
| `assets/otf_fonts/` | 604 page-specific QCF4 fonts plus shared header glyphs   |
| `assets/hive/`      | Offline Quran text, surah/juz/hizb metadata, and page layouts |
| `assets/images/`    | Surah header and banner SVGs                             |


Runtime data comes from Hive boxes copied on first launch — not from JSON at runtime. Source JSON under `assets/jsons/` is kept in the repo for maintainers only and is excluded from pub publishes.

The package is large (~600 font files). Plan for app size accordingly.

## Acknowledgments

Incredible resources that informed the design and implementation of this library:

- [Wahy](https://main.wahy.net/en/)
- [quran_library](https://pub.dev/packages/quran_library)

## Third-party assets

- **QCF4 fonts** — proprietary freeware from the [King Fahd Complex for the Printing of the Holy Quran](https://qurancomplex.gov.sa/). Free to use in applications; **not** covered by the MIT license. Redistribution and modification of the font files are subject to the Complex's terms.

## License

- **Package source code** — [MIT License](LICENSE)
- **QCF4 font files** — proprietary freeware; see [Third-party assets](#third-party-assets) and the notice at the end of [LICENSE](LICENSE)
