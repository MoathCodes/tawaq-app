import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:mushaf_reader/src/core/kfqc_page_geometry.dart';
import 'package:mushaf_reader/src/data/models/mushaf_style.dart';
import 'package:mushaf_reader/src/data/models/quran_page.dart';

/// Logical pixel height of a Mushaf page at the reference layout (width 500).
///
/// Matches the KFQC Hafs page aspect (`345×550`) via
/// [KfqcPageGeometry.flutterReferenceHeight] (~797.1). Used by [MushafScale]
/// auto-fit to clamp vertical scaling in [MushafPage].
const double mushafReferencePageHeight =
    KfqcPageGeometry.flutterReferenceHeight;

/// Snaps [logicalSize] to the nearest physical pixel for crisp QCF rendering.
double snapToDevicePixel(BuildContext context, double logicalSize) {
  if (logicalSize <= 0) return logicalSize;
  final dpr = MediaQuery.devicePixelRatioOf(context);
  return (logicalSize * dpr).round() / dpr;
}

/// Scale so the full design page ([referenceWidth] × [mushafReferencePageHeight])
/// fits in the pane with no scrolling.
double resolveContainScale({
  required MushafScale scale,
  required double availableWidth,
  required double availableHeight,
}) {
  final widthFit = resolveWidthFitScale(
    scale: scale,
    availableWidth: availableWidth,
  );
  if (!availableHeight.isFinite) return widthFit;
  final heightFit = availableHeight / mushafReferencePageHeight;
  return math.min(widthFit, heightFit).clamp(scale.minScale, scale.maxScale);
}

/// Largest uniform scale that never exceeds [availableWidth] (no horizontal scroll).
double resolveWidthFitScale({
  required MushafScale scale,
  required double availableWidth,
}) {
  return (availableWidth / scale.referenceWidth).clamp(
    scale.minScale,
    scale.maxScale,
  );
}

/// Width/height contain fit without [MushafScale.readingBoost].
double resolveBaseFitScale({
  required MushafScale scale,
  required double availableWidth,
  required double availableHeight,
}) => resolveContainScale(
  scale: scale,
  availableWidth: availableWidth,
  availableHeight: availableHeight,
);

/// Clamped user reading boost from [MushafScale].
double resolveReadingBoost(MushafScale scale) {
  if (scale.ayahFontSize != null) return 1;
  return scale.readingBoost.clamp(
    scale.minReadingBoost,
    scale.maxReadingBoost,
  );
}

/// Maps [readingBoost] onto \[containScale, widthFitScale\].
///
/// - boost ≤ 1 → `containScale * boost` (fit page, optionally smaller)
/// - boost > 1 → lerp toward [widthFitScale] (optional larger text; vertical
///   scroll may appear; never above width fit → no horizontal scroll)
double resolvePageScale({
  required MushafScale scaleConfig,
  required double availableWidth,
  required double availableHeight,
  BuildContext? context,
  QuranPage? page,
  bool hideHeader = false,
  int pageNumber = 1,
  MushafStyle? style,
}) {
  if (scaleConfig.factor != null) {
    final widthFit = resolveWidthFitScale(
      scale: scaleConfig,
      availableWidth: availableWidth,
    );
    return scaleConfig.factor!.clamp(scaleConfig.minScale, widthFit);
  }

  if (scaleConfig.ayahFontSize != null) {
    return resolveContainScale(
      scale: scaleConfig,
      availableWidth: availableWidth,
      availableHeight: availableHeight,
    );
  }

  final widthFit = resolveWidthFitScale(
    scale: scaleConfig,
    availableWidth: availableWidth,
  );
  final contain = resolveContainScale(
    scale: scaleConfig,
    availableWidth: availableWidth,
    availableHeight: availableHeight,
  );

  final boost = resolveReadingBoost(scaleConfig);
  late final double scale;
  if (boost <= 1) {
    scale = contain * boost;
  } else {
    final maxB = scaleConfig.maxReadingBoost;
    final t = maxB <= 1 ? 1.0 : ((boost - 1) / (maxB - 1)).clamp(0.0, 1.0);
    scale = contain + (widthFit - contain) * t;
  }

  return scale.clamp(scaleConfig.minScale, widthFit);
}

/// Memoizes [resolvePageScale] for repeated builds with the same inputs.
final class PageScaleCache {
  int? _pageNumber;
  double? _availableWidth;
  double? _availableHeight;
  bool? _hideHeader;
  int? _scaleConfigHash;
  int? _styleHash;
  double? _cachedScale;

  /// Returns a cached scale when inputs match the previous call.
  double resolve({
    required BuildContext context,
    required MushafScale scaleConfig,
    required QuranPage page,
    required double availableWidth,
    required double availableHeight,
    required bool hideHeader,
    required int pageNumber,
    MushafStyle? style,
  }) {
    final scaleConfigHash = Object.hash(
      scaleConfig.factor,
      scaleConfig.ayahFontSize,
      scaleConfig.basmalahFontSize,
      scaleConfig.pageNumberFontSize,
      scaleConfig.minScale,
      scaleConfig.maxScale,
      scaleConfig.referenceWidth,
      scaleConfig.readingBoost,
      scaleConfig.minReadingBoost,
      scaleConfig.maxReadingBoost,
    );
    final styleHash = style == null
        ? 0
        : Object.hash(
            style.ayahStyle,
            style.ayahStyleModifier,
            style.highlightColor,
            style.backgroundColor,
          );

    if (_cachedScale != null &&
        _pageNumber == pageNumber &&
        _availableWidth == availableWidth &&
        _availableHeight == availableHeight &&
        _hideHeader == hideHeader &&
        _scaleConfigHash == scaleConfigHash &&
        _styleHash == styleHash) {
      return _cachedScale!;
    }

    final scale = resolvePageScale(
      scaleConfig: scaleConfig,
      availableWidth: availableWidth,
      availableHeight: availableHeight,
      context: context,
      page: page,
      hideHeader: hideHeader,
      pageNumber: pageNumber,
      style: style,
    );

    _pageNumber = pageNumber;
    _availableWidth = availableWidth;
    _availableHeight = availableHeight;
    _hideHeader = hideHeader;
    _scaleConfigHash = scaleConfigHash;
    _styleHash = styleHash;
    _cachedScale = scale;
    return scale;
  }

  /// Clears the cached scale (e.g. when the page or style changes).
  void clear() {
    _pageNumber = null;
    _availableWidth = null;
    _availableHeight = null;
    _hideHeader = null;
    _scaleConfigHash = null;
    _styleHash = null;
    _cachedScale = null;
  }
}

/// Estimates vertical space reserved for headers, banners, and page number.
double estimatePageChromeHeight({
  required QuranPage page,
  required double scale,
  required bool hideHeader,
}) {
  var reserved = 48 * scale + 36 * scale; // page number + padding

  if (!hideHeader) {
    reserved += 44 * scale;
  }

  for (final block in page.surahs) {
    if (block.hasBasmalah) {
      reserved += 72 * scale;
      if (block.surahNumber != 9 && block.surahNumber != 1) {
        reserved += 28 * scale;
      }
    }
  }

  return reserved;
}

/// Whether the painted page at [scale] exceeds [availableHeight] (needs
/// vertical scroll). Always false when height is unbounded.
bool pageNeedsVerticalScroll({
  required double scale,
  required double availableHeight,
  required MushafScale scaleConfig,
}) {
  if (!availableHeight.isFinite) return false;
  final paintedHeight = mushafReferencePageHeight * scale;
  return paintedHeight > availableHeight + 0.5;
}

@Deprecated('Use resolvePageScale')
double resolveFitScale({
  required MushafScale scale,
  required double availableWidth,
  required double availableHeight,
}) => resolvePageScale(
  scaleConfig: scale,
  availableWidth: availableWidth,
  availableHeight: availableHeight,
);
