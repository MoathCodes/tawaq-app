/// Measured King Fahd Complex (KFQC) Hafs page geometry from the
/// `quran-svg` mushaf (`mushafs/hafs/kfqc`).
///
/// Values come from SVG `viewBox` plus ayah-marker / polygon metadata.
/// Re-run `dart run tool/analyze_kfqc_geometry.dart` after updating the
/// research clone to refresh these numbers.
///
/// See also:
/// - [mushafReferencePageHeight], which uses [flutterReferenceHeight]
/// - `tool/rasterize_kfqc_svg.dart`, which rasterizes at [rasterScale]
abstract final class KfqcPageGeometry {
  /// Normal-page SVG width (pages 3–604).
  static const double normalPageWidth = 345;

  /// Normal-page SVG height (pages 3–604).
  static const double normalPageHeight = 550;

  /// Square SVG size for ornamental pages 1–2.
  static const double specialPageSize = 235;

  /// Width / height for normal KFQC pages (~0.627).
  static const double normalAspectRatio = normalPageWidth / normalPageHeight;

  /// Default [MushafScale.referenceWidth] used by the package.
  static const double flutterReferenceWidth = 500;

  /// Reference page height that preserves [normalAspectRatio] at
  /// [flutterReferenceWidth] (`500 * 550 / 345` ≈ 797.1).
  static const double flutterReferenceHeight =
      flutterReferenceWidth * normalPageHeight / normalPageWidth;

  /// Median ayah-marker line gap on dense normal pages (SVG units).
  static const double medianLineGapSvg = 35.83;

  /// Median first-marker Y inset from the top of a normal page.
  static const double medianTopInsetSvg = 64.86;

  /// Median last-marker clearance above the bottom of a normal page.
  static const double medianBottomInsetSvg = 20.51;

  /// Median leftmost marker X on a normal page.
  static const double medianLeftMarginSvg = 15.95;

  /// Raster scale applied when converting SVG → PNG for goldens (`2` →
  /// `690×1100` for normal pages, `470×470` for pages 1–2).
  static const int rasterScale = 2;

  /// Physical PNG width for a normal-page golden (`345 * 2`).
  static const int normalRasterWidth = 690;

  /// Physical PNG height for a normal-page golden (`550 * 2`).
  static const int normalRasterHeight = 1100;

  /// Physical PNG size for ornamental pages 1–2 (`235 * 2`).
  static const int specialRasterSize = 470;

  /// Smoke pages exercised in CI golden tests.
  static const List<int> smokePages = [1, 2, 3, 50, 106, 604];

  /// Whether [page] uses the square ornamental viewBox.
  static bool isSpecialPage(int page) => page == 1 || page == 2;

  /// Logical viewport size for golden renders of [page].
  static ({double width, double height}) logicalSizeForPage(int page) {
    if (isSpecialPage(page)) {
      return (width: specialPageSize, height: specialPageSize);
    }
    return (width: normalPageWidth, height: normalPageHeight);
  }

  /// Physical raster size for golden refs of [page].
  static ({int width, int height}) rasterSizeForPage(int page) {
    if (isSpecialPage(page)) {
      return (width: specialRasterSize, height: specialRasterSize);
    }
    return (width: normalRasterWidth, height: normalRasterHeight);
  }

  /// Zero-padded page file stem (`001` … `604`).
  static String pageStem(int page) => page.toString().padLeft(3, '0');
}
