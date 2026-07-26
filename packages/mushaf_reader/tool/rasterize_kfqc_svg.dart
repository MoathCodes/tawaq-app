#!/usr/bin/env dart
// Rasterizes KFQC Hafs SVG pages to PNG goldens via ImageMagick `magick`.
//
// Usage (from package root):
//   dart run tool/rasterize_kfqc_svg.dart
//   dart run tool/rasterize_kfqc_svg.dart --pages=1,2,3,50,106,604
//   dart run tool/rasterize_kfqc_svg.dart --all
//
// Requires:
//   - ImageMagick (`magick` on PATH)
//   - `.research/quran-svg/mushafs/hafs/kfqc/svg/` (gitignored research clone)

import 'dart:io';

const _smokePages = [1, 2, 3, 50, 106, 604];
const _rasterScale = 2;
const _normalW = 345;
const _normalH = 550;
const _special = 235;

Future<void> main(List<String> args) async {
  final root = _packageRoot();
  final svgDir = Directory(
    '${root.path}/.research/quran-svg/mushafs/hafs/kfqc/svg',
  );
  final outDir = Directory('${root.path}/test/goldens/kfqc_refs');

  if (!svgDir.existsSync()) {
    stderr.writeln('Missing ${svgDir.path}');
    stderr.writeln(
      'Clone https://github.com/quranpedia/quran-svg into .research/quran-svg',
    );
    exit(1);
  }

  final magick = await _findMagick();
  if (magick == null) {
    stderr.writeln('ImageMagick `magick` not found on PATH');
    exit(1);
  }

  final pages = _parsePages(args);
  await outDir.create(recursive: true);

  stdout.writeln('Rasterizing ${pages.length} page(s) → ${outDir.path}');
  for (final page in pages) {
    final stem = page.toString().padLeft(3, '0');
    final svg = File('${svgDir.path}/$stem.svg');
    if (!svg.existsSync()) {
      stderr.writeln('Missing ${svg.path}');
      exit(1);
    }
    final out = File('${outDir.path}/$stem.png');
    final special = page == 1 || page == 2;
    final w = (special ? _special : _normalW) * _rasterScale;
    final h = (special ? _special : _normalH) * _rasterScale;

    final result = await Process.run(magick, [
      '-density',
      '144',
      svg.path,
      '-background',
      'white',
      '-alpha',
      'remove',
      '-alpha',
      'off',
      '-resize',
      '${w}x$h!',
      out.path,
    ]);
    if (result.exitCode != 0) {
      stderr.writeln('magick failed for page $page:');
      stderr.writeln(result.stderr);
      exit(result.exitCode);
    }
    stdout.writeln('  $stem.png (${w}×$h)');
  }
  stdout.writeln('Done.');
}

List<int> _parsePages(List<String> args) {
  if (args.contains('--all')) {
    return [for (var p = 1; p <= 604; p++) p];
  }
  for (final arg in args) {
    if (arg.startsWith('--pages=')) {
      return arg
          .substring('--pages='.length)
          .split(',')
          .map((s) => int.parse(s.trim()))
          .toList();
    }
  }
  return List<int>.from(_smokePages);
}

Future<String?> _findMagick() async {
  final which = await Process.run('which', ['magick']);
  if (which.exitCode == 0) {
    return (which.stdout as String).trim().split('\n').first;
  }
  return null;
}

Directory _packageRoot() {
  var dir = Directory.current;
  while (!File('${dir.path}/pubspec.yaml').existsSync()) {
    dir = dir.parent;
  }
  return dir;
}
