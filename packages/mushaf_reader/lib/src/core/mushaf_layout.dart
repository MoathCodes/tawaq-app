import 'package:flutter/widgets.dart';
import 'package:mushaf_reader/src/core/fonts.dart';
import 'package:mushaf_reader/src/data/models/mushaf_style.dart';
import 'package:mushaf_reader/src/data/models/quran_page.dart';

/// Reference page height used for auto-fit calculations.
const double mushafReferencePageHeight = 850;

/// Snaps [logicalSize] to the nearest physical pixel for crisp QCF rendering.
double snapToDevicePixel(BuildContext context, double logicalSize) {
  if (logicalSize <= 0) return logicalSize;
  final dpr = MediaQuery.devicePixelRatioOf(context);
  return (logicalSize * dpr).round() / dpr;
}

/// Width/height fit without [MushafScale.readingBoost].
double resolveBaseFitScale({
  required MushafScale scale,
  required double availableWidth,
  required double availableHeight,
}) {
  var fitScale = scale.scaleForWidth(availableWidth);

  if (availableHeight.isFinite) {
    final heightScale = availableHeight / mushafReferencePageHeight;
    fitScale = fitScale.clamp(scale.minScale, heightScale);
  }

  return fitScale;
}

/// Clamped user reading boost from [MushafScale].
double resolveReadingBoost(MushafScale scale) {
  if (scale.ayahFontSize != null) return 1;
  return scale.readingBoost.clamp(
    scale.minReadingBoost,
    scale.maxReadingBoost,
  );
}

/// Whether [glyphText] fits at [scale] within [maxAyahHeight].
bool glyphFitsAtScale({
  required BuildContext context,
  required MushafScale scaleConfig,
  required QuranPage page,
  required double scale,
  required double maxAyahHeight,
  required double contentWidth,
  required int pageNumber,
  MushafStyle? style,
}) {
  if (!maxAyahHeight.isFinite || maxAyahHeight <= 0) return true;

  final mushafStyle = style ?? const MushafStyle();
  final ayahFontSize = snapToDevicePixel(
    context,
    scaleConfig.getAyahFontSize(scale),
  );
  final textStyle = MushafTextStyleMerger.mergeAyahStyle(
    userStyle: mushafStyle.ayahStyle,
    modifier: mushafStyle.ayahStyleModifier,
    pageNumber: pageNumber,
    baseSize: ayahFontSize,
  );

  final painter = TextPainter(
    text: TextSpan(text: page.glyphText, style: textStyle),
    textDirection: TextDirection.rtl,
    textAlign: TextAlign.center,
    locale: const Locale('ar'),
    maxLines: null,
  )..layout(maxWidth: contentWidth);

  return painter.height <= maxAyahHeight;
}

/// Largest reading boost so [baseFit] × boost still fits [maxAyahHeight].
double findMaxReadingBoostForPage({
  required BuildContext context,
  required MushafScale scaleConfig,
  required QuranPage page,
  required double baseFit,
  required double maxAyahHeight,
  required double contentWidth,
  required int pageNumber,
  MushafStyle? style,
}) {
  var low = scaleConfig.minReadingBoost;
  var high = scaleConfig.maxReadingBoost;

  if (glyphFitsAtScale(
    context: context,
    scaleConfig: scaleConfig,
    page: page,
    scale: baseFit * high,
    maxAyahHeight: maxAyahHeight,
    contentWidth: contentWidth,
    pageNumber: pageNumber,
    style: style,
  )) {
    return high;
  }

  for (var i = 0; i < 12; i++) {
    final mid = (low + high) / 2;
    if (glyphFitsAtScale(
      context: context,
      scaleConfig: scaleConfig,
      page: page,
      scale: baseFit * mid,
      maxAyahHeight: maxAyahHeight,
      contentWidth: contentWidth,
      pageNumber: pageNumber,
      style: style,
    )) {
      low = mid;
    } else {
      high = mid;
    }
  }

  return low;
}

/// Lowers [baseFit] until [glyphText] fits at boost 1.0.
double clampBaseFitForGlyphHeight({
  required BuildContext context,
  required MushafScale scaleConfig,
  required QuranPage page,
  required double baseFit,
  required double maxAyahHeight,
  required double contentWidth,
  required int pageNumber,
  MushafStyle? style,
}) {
  if (!maxAyahHeight.isFinite || maxAyahHeight <= 0) {
    return baseFit;
  }

  var effective = baseFit;
  final minScale = scaleConfig.minScale;

  while (effective > minScale) {
    if (glyphFitsAtScale(
      context: context,
      scaleConfig: scaleConfig,
      page: page,
      scale: effective,
      maxAyahHeight: maxAyahHeight,
      contentWidth: contentWidth,
      pageNumber: pageNumber,
      style: style,
    )) {
      return effective;
    }

    effective *= 0.96;
    if (effective <= minScale) {
      return minScale;
    }
  }

  return minScale;
}

/// Resolves final page scale: fit → clamp at 1.0 → apply reading boost (monotonic).
double resolvePageScale({
  required BuildContext context,
  required MushafScale scaleConfig,
  required QuranPage page,
  required double availableWidth,
  required double availableHeight,
  required bool hideHeader,
  required int pageNumber,
  MushafStyle? style,
}) {
  if (scaleConfig.ayahFontSize != null) {
    return resolveBaseFitScale(
      scale: scaleConfig,
      availableWidth: availableWidth,
      availableHeight: availableHeight,
    );
  }

  var baseFit = resolveBaseFitScale(
    scale: scaleConfig,
    availableWidth: availableWidth,
    availableHeight: availableHeight,
  );

  if (!availableHeight.isFinite) {
    return baseFit * resolveReadingBoost(scaleConfig);
  }

  final chromeHeight = estimatePageChromeHeight(
    page: page,
    scale: baseFit,
    hideHeader: hideHeader,
  );
  final maxAyahHeight = availableHeight - chromeHeight;
  var contentWidth = scaleConfig.referenceWidth * baseFit;

  baseFit = clampBaseFitForGlyphHeight(
    context: context,
    scaleConfig: scaleConfig,
    page: page,
    baseFit: baseFit,
    maxAyahHeight: maxAyahHeight,
    contentWidth: contentWidth,
    pageNumber: pageNumber,
    style: style,
  );

  contentWidth = scaleConfig.referenceWidth * baseFit;

  final userBoost = resolveReadingBoost(scaleConfig);
  final maxBoost = findMaxReadingBoostForPage(
    context: context,
    scaleConfig: scaleConfig,
    page: page,
    baseFit: baseFit,
    maxAyahHeight: maxAyahHeight,
    contentWidth: contentWidth,
    pageNumber: pageNumber,
    style: style,
  );

  return baseFit * (userBoost < maxBoost ? userBoost : maxBoost);
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

// Deprecated: use [resolveBaseFitScale] + [resolvePageScale].
@Deprecated('Use resolvePageScale')
double resolveFitScale({
  required MushafScale scale,
  required double availableWidth,
  required double availableHeight,
}) {
  var fitScale = resolveBaseFitScale(
    scale: scale,
    availableWidth: availableWidth,
    availableHeight: availableHeight,
  );
  return fitScale * resolveReadingBoost(scale);
}

// Deprecated: use clampBaseFitForGlyphHeight
@Deprecated('Use clampBaseFitForGlyphHeight')
double clampScaleForGlyphHeight({
  required BuildContext context,
  required MushafScale scaleConfig,
  required QuranPage page,
  required double effectiveScale,
  required double maxAyahHeight,
  required double contentWidth,
  required int pageNumber,
  MushafStyle? style,
}) => clampBaseFitForGlyphHeight(
  context: context,
  scaleConfig: scaleConfig,
  page: page,
  baseFit: effectiveScale,
  maxAyahHeight: maxAyahHeight,
  contentWidth: contentWidth,
  pageNumber: pageNumber,
  style: style,
);
