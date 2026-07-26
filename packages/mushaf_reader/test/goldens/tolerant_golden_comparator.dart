import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf_reader/src/core/kfqc_page_geometry.dart';
import 'package:path/path.dart' as p;

/// Result of comparing a Flutter screenshot to a KFQC SVG raster.
class KfqcImageDiff {
  const KfqcImageDiff({
    required this.candidateInkRatio,
    required this.referenceInkRatio,
    required this.inkDelta,
    required this.structureMae,
    required this.width,
    required this.height,
  });

  /// Fraction of candidate pixels darker than [inkLumaThreshold].
  final double candidateInkRatio;

  /// Fraction of reference pixels darker than [inkLumaThreshold].
  final double referenceInkRatio;

  /// Absolute difference between ink ratios.
  final double inkDelta;

  /// Mean absolute error on downsampled ink-density grids (0–1).
  final double structureMae;

  final int width;
  final int height;

  /// Pixels with luma below this count as ink.
  static const int inkLumaThreshold = 240;

  /// Fails when the page is blank / nearly blank.
  static const double minInkRatio = 0.04;

  /// Max allowed |candidate − reference| ink ratio.
  ///
  /// Page 604 (multi-surah headers) can differ by ~0.14 while still intact.
  static const double maxInkDelta = 0.16;

  /// Max allowed downsampled density MAE (layout / corruption check).
  ///
  /// QCF outlines ≠ SVG paths, so structural MAE on dense pages sits ~0.40–0.48
  /// when healthy; blank/corrupt pages exceed this or fail [minInkRatio].
  static const double maxStructureMae = 0.52;

  bool get passed =>
      candidateInkRatio >= minInkRatio &&
      inkDelta <= maxInkDelta &&
      structureMae <= maxStructureMae;

  String get summary =>
      'ink=${candidateInkRatio.toStringAsFixed(3)} '
      'refInk=${referenceInkRatio.toStringAsFixed(3)} '
      'Δink=${inkDelta.toStringAsFixed(3)} '
      'structMae=${structureMae.toStringAsFixed(3)} '
      '($width×$height)';
}

/// Decodes PNG bytes to raw RGBA via Flutter's image codec.
Future<({int width, int height, Uint8List rgba})> decodePngRgba(
  Uint8List pngBytes,
) async {
  final codec = await ui.instantiateImageCodec(pngBytes);
  final frame = await codec.getNextFrame();
  final image = frame.image;
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (bytes == null) {
    throw StateError('Failed to decode PNG to RGBA');
  }
  return (
    width: image.width,
    height: image.height,
    rgba: bytes.buffer.asUint8List(),
  );
}

/// Compares [candidatePng] (Flutter render) to [referencePng] (SVG raster).
Future<KfqcImageDiff> compareKfqcImages({
  required Uint8List candidatePng,
  required Uint8List referencePng,
  int structureWidth = 46,
  int structureHeight = 72,
}) async {
  final candidate = await decodePngRgba(candidatePng);
  final reference = await decodePngRgba(referencePng);

  if (candidate.width != reference.width ||
      candidate.height != reference.height) {
    throw TestFailure(
      'Size mismatch: candidate ${candidate.width}×${candidate.height} '
      'vs reference ${reference.width}×${reference.height}',
    );
  }

  final candidateInk = _inkRatio(candidate.rgba);
  final referenceInk = _inkRatio(reference.rgba);

  // Crop chrome bands (header / page-number) before structure compare.
  final croppedCand = _cropContent(candidate.rgba, candidate.width, candidate.height);
  final croppedRef = _cropContent(reference.rgba, reference.width, reference.height);

  final sw = structureWidth.clamp(8, croppedCand.width);
  final sh = structureHeight.clamp(8, croppedCand.height);
  final structW = croppedCand.width == croppedCand.height
      ? math.min(sw, sh)
      : sw;
  final structH = croppedCand.width == croppedCand.height ? structW : sh;

  final candGrid = _downsampleInkDensity(
    croppedCand.rgba,
    croppedCand.width,
    croppedCand.height,
    structW,
    structH,
  );
  final refGrid = _downsampleInkDensity(
    croppedRef.rgba,
    croppedRef.width,
    croppedRef.height,
    structW,
    structH,
  );

  var absErr = 0.0;
  for (var i = 0; i < candGrid.length; i++) {
    absErr += (candGrid[i] - refGrid[i]).abs();
  }
  final structureMae = absErr / candGrid.length;

  return KfqcImageDiff(
    candidateInkRatio: candidateInk,
    referenceInkRatio: referenceInk,
    inkDelta: (candidateInk - referenceInk).abs(),
    structureMae: structureMae,
    width: candidate.width,
    height: candidate.height,
  );
}

double _inkRatio(Uint8List rgba) {
  final pixels = rgba.length ~/ 4;
  if (pixels == 0) return 0;
  var ink = 0;
  for (var i = 0; i < rgba.length; i += 4) {
    final a = rgba[i + 3];
    if (a < 16) continue;
    final luma =
        (0.299 * rgba[i] + 0.587 * rgba[i + 1] + 0.114 * rgba[i + 2]).round();
    if (luma < KfqcImageDiff.inkLumaThreshold) ink++;
  }
  return ink / pixels;
}

({int width, int height, Uint8List rgba}) _cropContent(
  Uint8List rgba,
  int width,
  int height,
) {
  // Special square pages: light crop.
  if (width == height) {
    final inset = (height * 0.06).round().clamp(0, height ~/ 4);
    return _cropRect(rgba, width, height, inset, inset, width - inset, height - inset);
  }

  final top = (height *
          (KfqcPageGeometry.medianTopInsetSvg /
              KfqcPageGeometry.normalPageHeight))
      .round()
      .clamp(0, height ~/ 3);
  final bottom = (height *
          (KfqcPageGeometry.medianBottomInsetSvg /
              KfqcPageGeometry.normalPageHeight))
      .round()
      .clamp(0, height ~/ 5);
  // Also trim a band for Flutter page-number chrome.
  final bottomExtra = (height * 0.04).round();
  return _cropRect(
    rgba,
    width,
    height,
    0,
    top,
    width,
    height - bottom - bottomExtra,
  );
}

({int width, int height, Uint8List rgba}) _cropRect(
  Uint8List rgba,
  int width,
  int height,
  int x0,
  int y0,
  int x1,
  int y1,
) {
  final w = (x1 - x0).clamp(1, width);
  final h = (y1 - y0).clamp(1, height);
  final out = Uint8List(w * h * 4);
  for (var y = 0; y < h; y++) {
    final srcRow = ((y0 + y) * width + x0) * 4;
    final dstRow = y * w * 4;
    out.setRange(dstRow, dstRow + w * 4, rgba, srcRow);
  }
  return (width: w, height: h, rgba: out);
}

/// Average-pool to [outW]×[outH]; each cell is ink fraction in 0–1.
Float64List _downsampleInkDensity(
  Uint8List rgba,
  int width,
  int height,
  int outW,
  int outH,
) {
  final out = Float64List(outW * outH);
  for (var oy = 0; oy < outH; oy++) {
    final y0 = (oy * height / outH).floor();
    final y1 = (((oy + 1) * height / outH).ceil()).clamp(y0 + 1, height);
    for (var ox = 0; ox < outW; ox++) {
      final x0 = (ox * width / outW).floor();
      final x1 = (((ox + 1) * width / outW).ceil()).clamp(x0 + 1, width);
      var ink = 0;
      var count = 0;
      for (var y = y0; y < y1; y++) {
        for (var x = x0; x < x1; x++) {
          final i = (y * width + x) * 4;
          final luma =
              0.299 * rgba[i] + 0.587 * rgba[i + 1] + 0.114 * rgba[i + 2];
          if (luma < KfqcImageDiff.inkLumaThreshold) ink++;
          count++;
        }
      }
      out[oy * outW + ox] = count == 0 ? 0.0 : ink / count;
    }
  }
  return out;
}

/// Golden comparator that diffs Flutter captures against KFQC SVG rasters.
///
/// Does **not** overwrite goldens on `--update-goldens` (refs are SVG-derived).
class TolerantKfqcGoldenComparator extends LocalFileComparator {
  TolerantKfqcGoldenComparator(super.testFile);

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) async {
    throw UnsupportedError(
      'KFQC SVG reference goldens must not be updated from Flutter captures. '
      'Re-run: dart run tool/rasterize_kfqc_svg.dart',
    );
  }

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final referenceBytes = await getGoldenBytes(golden);
    final diff = await compareKfqcImages(
      candidatePng: imageBytes,
      referencePng: Uint8List.fromList(referenceBytes),
    );
    if (diff.passed) return true;

    final result = ComparisonResult(
      passed: false,
      diffPercent: diff.structureMae,
      error:
          'KFQC visual golden failed: ${diff.summary}\n'
          'thresholds: minInk=${KfqcImageDiff.minInkRatio} '
          'maxInkΔ=${KfqcImageDiff.maxInkDelta} '
          'maxStructMae=${KfqcImageDiff.maxStructureMae}',
    );
    final feedback = await generateFailureOutput(result, golden, basedir);
    throw FlutterError(feedback);
  }
}

/// Resolves `test/goldens/kfqc_refs/NNN.png` from the package root.
String kfqcRefPath(int page, {Directory? packageRoot}) {
  final root = packageRoot ?? _findPackageRoot();
  final stem = page.toString().padLeft(3, '0');
  return p.join(root.path, 'test', 'goldens', 'kfqc_refs', '$stem.png');
}

Directory _findPackageRoot() {
  var dir = Directory.current;
  while (!File(p.join(dir.path, 'pubspec.yaml')).existsSync()) {
    dir = dir.parent;
  }
  return dir;
}
