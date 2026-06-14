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

