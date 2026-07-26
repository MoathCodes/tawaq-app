## 0.3.3

* Kept Fontello QCF4 page OTFs (`assets/otf_fonts/QCF4_NNN.otf`) and the
  existing V1-style PUA glyphs (no QCF V2 / per-line stretch migration).
* Patched `QCF4_379.otf` glyph `U+FB6F` (start of An-Naml 27:25): clamped
  only the sajdah overline contours to the existing advance so they no
  longer fill the ayah-24 marker crown (`U+FB6E`). Letterforms (full
  **أَلَّا**) and advance width are unchanged — no contour deletion and no
  extra gap before يسجدوا.
* Page layout: contain-fit by default (full page, no scroll); optional
  `readingBoost` lerps only up to width-fit (vertical scroll OK, never
  horizontal). Uniform page scale only — no per-line `FittedBox` stretching.
* Desktop zoom on `MushafReader`: Ctrl/⌘+scroll, trackpad pinch, and
  Ctrl/⌘+±/0 adjust session `readingBoost` via
  `MushafReaderController.sessionReadingBoost` / `nudgeReadingBoost` /
  `resetSessionReadingBoost` (capped at width-fit).
* Reference page box now matches KFQC Hafs aspect (`345×550` → ~500×797)
  via `KfqcPageGeometry` / `mushafReferencePageHeight`. Ayah content is
  top-aligned with the page number pinned to the bottom.
* Added KFQC visual golden suite (`test/goldens/`): smoke pages compare
  `MushafPage` renders to SVG rasters with ink-density + structure checks.
  Tools: `tool/analyze_kfqc_geometry.dart`, `tool/rasterize_kfqc_svg.dart`.
  Full 604-page run: `MUSHAF_KFQC_FULL_GOLDENS=1`.

## 0.3.2

* Added `Ayah.uthmaniText` (Uthmanic Hafs from `quran.json` `text` key).
* Added `Hizb.startAyahUthmaniText` for fast hizb selector subtitles.
* Added `Juz.startSurahNumber` and `Juz.startAyahInSurah` for English juz
  subtitles. Regenerate `ayahs.hive`, `hizbs.hive`, and `juzs.hive` after
  upgrading (manifest hash bump triggers asset refresh in host apps).

## 0.3.1

* Fixed `HiveBoxManager` reference counting: `instance` / factory no longer
  inflate the count; use `acquire()` for owned lifetimes. `getBasmalahSync()`
  peeks via `instance` instead of leaking a ref.
* `HiveBoxManager.dispose()` and `HiveQuranRepository.dispose()` no-op when
  ref count is already zero (prevents stray teardown).
* `PageAyahWidget` disposes tap/long-press recognizers for ayah ids no longer
  in the fragment list.

## 0.3.0

* Added `Juz.endAyahId` for authoritative juz boundary lookups; regenerate
  `juzs.hive` after upgrading.
* Added `Ayah.hizb` and `Ayah.quarterInHizb` getters derived from
  `hizbQuarter`.
* Added `Hizb` model, `hizbs.hive` (60 derived entries), and navigation APIs:
  `getHizbs`, `getHizbSync`, `getHizbStartPage`, `jumpToHizb`, `juzAyahBounds`,
  `hizbAyahBounds`. When `endAyahId` is missing on a stored juz or hizb,
  bounds APIs derive the end from the next division's `startAyahId - 1` (or
  ayah 6236 for the last division).
* Split controller notifications into `MushafSelectionListenable` and
  `MushafPageListenable` (`controller.selection` / `controller.page`) for
  narrower rebuilds; `MushafPage` listens to selection directly.
* Exported `SurahTiming` and `AyahTiming` JSON models for host-app recitation
  timing (no bundled audio or player).
* Fixed `HiveQuranRepository` reference counting: `instance` / factory no
  longer inflate the count; use `acquire()` for owned lifetimes (controllers).
  `BasmalahWidget` and `JuzWidget` no longer call the factory from `build()`.
* `MushafReader` keeps only the visible page window alive in `PageView`
  (current ±1) instead of every visited page; pass `keepAlive` on standalone
  `MushafPage` when embedding in your own pager.
* `MushafReader` async page callbacks guard with `mounted` after awaits.

## 0.2.0

* Surah header banners use offline-precompiled `.svg.vec` assets loaded via
  `flutter_svg` (sources in `tool/svg/`, regenerate with
  `tool/compile_surah_headers.sh`).
* Added `MushafStyle.surahHeaderImageDark` for dark-theme banner overrides;
  `surahHeaderImage` now applies to the light banner only.
* `SurahHeaderWidget.isDark` and `MushafPageRange.isDark` are nullable — when
  null, banner variant follows `Theme.of(context).brightness`.
* Added `MushafPageRange` for rendering a full page or ayah range (single-page
  and cross-page contiguous selections) with automatic fragment filtering and
  newline compaction.
* Added `MushafPageRangeLayout` utilities for host apps to query chrome
  availability (`basmalahPossible`, `surahHeaderPossible`, etc.).
* Added `MushafReaderController.orderedAyahIdsOnPage`.
* Refactored `MushafPage` surah-block rendering to share logic with
  `MushafPageRange`.
* `PageAyahWidget` `onAyahSelection` is optional when highlighting is disabled.

## 0.1.0

* **Breaking:** Removed deprecated `MushafPage.onTapAyah` / `onLongPressAyah` — use `onAyahIdTap` / `onAyahIdLongPress`.
* Merged single- and two-page readers into `MushafReader` via `pagesPerViewport` (`1` or `2`).
* `MushafTwoPageReader` is deprecated; use `MushafReader(pagesPerViewport: 2, onSpreadChanged: ...)`.
* Aligned `getSurahSync` with `getJuzSync` (map lookup, returns `null` when missing).
* Added `IQuranRepository.getSurahSync`.

## 0.0.2

* Added `MushafStyle.modify()` factory and `.modify()` chaining for modifier-only styling.
* Added `MushafConstants`, callback typedefs, `AyahIdResolver`, and `Ayah.globalIdFor()`.
* Unified `MushafPage` callbacks: `onAyahIdTap` / `onAyahIdLongPress` (deprecated `onTapAyah` / `onLongPressAyah`).
* Documented public API with dartdoc; added English and Arabic READMEs.
* Exported `IQuranRepository`; optional `repository` on `MushafReaderController`.
* Added MIT license and pub.dev metadata (`homepage`, `repository`, `issue_tracker`).
* Added RTL support for `MushafReader` and `MushafTwoPageReader`.
* Optimized `PageAyahWidget` rendering to reduce GC churn.
* Improved performance of `JuzWidget`, `SurahNameWidget`, and `SurahHeaderWidget` by caching async operations.
* Refactored `MushafReaderController` for better testability.
* Added comprehensive unit and widget tests.
* Updated documentation and examples.

## 0.0.1

* Initial release.

