#!/usr/bin/env dart
// Analyzes KFQC Hafs SVG/JSON geometry and prints constants for
// lib/src/core/kfqc_page_geometry.dart.
//
// Usage (from package root):
//   dart run tool/analyze_kfqc_geometry.dart
//
// Requires `.research/quran-svg/mushafs/hafs/kfqc/` (gitignored research clone).

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

void main(List<String> args) {
  final root = _packageRoot();
  final kfqc = Directory(
    '${root.path}/.research/quran-svg/mushafs/hafs/kfqc',
  );
  if (!kfqc.existsSync()) {
    stderr.writeln('Missing ${kfqc.path}');
    stderr.writeln(
      'Clone https://github.com/quranpedia/quran-svg into .research/quran-svg',
    );
    exit(1);
  }

  final markers =
      (jsonDecode(File('${kfqc.path}/json/markers.json').readAsStringSync())
              as List)
          .cast<Map<String, dynamic>>();

  final byPage = <int, List<Map<String, dynamic>>>{};
  for (final m in markers) {
    final page = m['page'] as int;
    byPage.putIfAbsent(page, () => []).add(m);
  }

  final gaps = <double>[];
  final topInsets = <double>[];
  final bottomInsets = <double>[];
  final leftMargins = <double>[];
  final rightMargins = <double>[];

  for (var page = 3; page <= 604; page++) {
    final ms = byPage[page];
    if (ms == null || ms.isEmpty) continue;
    final lines = _lineClusters(ms);
    final lineYs = [
      for (final line in lines)
        line.map((m) => (m['y'] as num).toDouble()).reduce((a, b) => a + b) /
            line.length,
    ];
    if (lines.length >= 10) {
      for (var i = 0; i < lineYs.length - 1; i++) {
        gaps.add(lineYs[i + 1] - lineYs[i]);
      }
    }
    final ys = ms.map((m) => (m['y'] as num).toDouble()).toList();
    final xs = ms.map((m) => (m['x'] as num).toDouble()).toList();
    topInsets.add(ys.reduce(math.min));
    bottomInsets.add(550 - ys.reduce(math.max));
    leftMargins.add(xs.reduce(math.min));
    rightMargins.add(345 - xs.reduce(math.max));
  }

  stdout.writeln('KFQC geometry (hafs/kfqc)');
  stdout.writeln('  normal viewBox: 345 × 550');
  stdout.writeln('  special pages 1–2: 235 × 235');
  stdout.writeln(
    '  flutterReferenceHeight @ width 500: ${500 * 550 / 345}',
  );
  stdout.writeln('  medianLineGapSvg: ${_median(gaps)}');
  stdout.writeln('  medianTopInsetSvg: ${_median(topInsets)}');
  stdout.writeln('  medianBottomInsetSvg: ${_median(bottomInsets)}');
  stdout.writeln('  medianLeftMarginSvg: ${_median(leftMargins)}');
  stdout.writeln('  medianRightMarginSvg: ${_median(rightMargins)}');
  stdout.writeln('  gap/pageHeight: ${_median(gaps) / 550}');
}

Directory _packageRoot() {
  var dir = Directory.current;
  while (!File('${dir.path}/pubspec.yaml').existsSync()) {
    dir = dir.parent;
  }
  return dir;
}

List<List<Map<String, dynamic>>> _lineClusters(
  List<Map<String, dynamic>> markers, {
  double thresh = 8,
}) {
  final sorted = [...markers]
    ..sort((a, b) {
      final ay = (a['y'] as num).toDouble();
      final by = (b['y'] as num).toDouble();
      final c = ay.compareTo(by);
      if (c != 0) return c;
      return (b['x'] as num).compareTo(a['x'] as num);
    });
  final lines = <List<Map<String, dynamic>>>[];
  for (final m in sorted) {
    if (lines.isEmpty ||
        ((m['y'] as num).toDouble() - (lines.last.first['y'] as num).toDouble())
                .abs() >
            thresh) {
      lines.add([m]);
    } else {
      lines.last.add(m);
    }
  }
  return lines;
}

double _median(List<double> values) {
  if (values.isEmpty) return double.nan;
  final sorted = [...values]..sort();
  final mid = sorted.length ~/ 2;
  if (sorted.length.isOdd) return sorted[mid];
  return (sorted[mid - 1] + sorted[mid]) / 2;
}
