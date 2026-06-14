// ignore_for_file: avoid_print
//
// Legacy PNG resizer — prefer `python3 render.py` (IBM Plex Sans Arabic renderer).
//
// Usage:
//   cd tooling/icons && dart pub get && dart run bin/generate_icons.dart
//   dart run bin/generate_icons.dart --install
//
// Requires ImageMagick (`magick`) for multi-size .ico output.

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:args/args.dart';
import 'package:image/image.dart';
import 'package:path/path.dart' as p;

const _macosSizes = <int>[16, 32, 64, 128, 256, 512, 1024];
const _windowsIcoSizes = <int>[16, 24, 32, 48, 64, 128, 256];
const _linuxSizes = <int>[16, 32, 48, 64, 128, 256, 512];
const _traySizes = <int>[16, 24, 32];

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addFlag(
      'install',
      help: 'Copy generated assets into the Tawaq Flutter project tree.',
    )
    ..addOption(
      'source',
      defaultsTo: 'source/app_icon.png',
      help: 'Master app icon PNG (square, ideally 1024×1024).',
    )
    ..addOption(
      'tray-source',
      defaultsTo: 'source/tray_icon.png',
      help: 'Optional transparent tray PNG. Auto-generated if missing.',
    )
    ..addOption(
      'out',
      defaultsTo: 'out',
      help: 'Output directory for generated assets.',
    );

  final args = parser.parse(arguments);
  if (args.rest.isNotEmpty) {
    print('Unexpected arguments: ${args.rest.join(' ')}');
    print(parser.usage);
    exitCode = 64;
    return;
  }

  final toolRoot = Directory(p.dirname(p.dirname(Platform.script.toFilePath())));
  final repoRoot = Directory(p.normalize(p.join(toolRoot.path, '..', '..')));
  final sourcePath = File(p.join(toolRoot.path, args['source'] as String));
  final traySourcePath = File(p.join(toolRoot.path, args['tray-source'] as String));
  final outRoot = Directory(p.join(toolRoot.path, args['out'] as String));

  if (!sourcePath.existsSync()) {
    print('Missing source icon: ${sourcePath.path}');
    exitCode = 1;
    return;
  }

  final masterBytes = await sourcePath.readAsBytes();
  final master = decodeImage(masterBytes);
  if (master == null) {
    print('Could not decode ${sourcePath.path}');
    exitCode = 1;
    return;
  }

  if (master.width != master.height) {
    print('Warning: source is ${master.width}×${master.height}; square is recommended.');
  }

  print('Source: ${sourcePath.path} (${master.width}×${master.height})');
  print('Output: ${outRoot.path}');

  await _writeMacosIcons(master, outRoot);
  await _writeWindowsIco(master, outRoot);
  await _writeLinuxIcons(master, outRoot);

  final trayMaster = traySourcePath.existsSync()
      ? decodeImage(await traySourcePath.readAsBytes())
      : _makeTrayFromAppIcon(master);
  if (trayMaster == null) {
    print('Could not build tray icon.');
    exitCode = 1;
    return;
  }
  await _writeTrayIcons(trayMaster, outRoot);

  if (args['install'] as bool) {
    await _install(repoRoot, outRoot);
    print('Installed icons into ${repoRoot.path}');
  } else {
    print('Done. Re-run with --install to copy files into the project.');
  }
}

Future<void> _writeMacosIcons(Image master, Directory outRoot) async {
  final dir = Directory(p.join(outRoot.path, 'macos', 'AppIcon.appiconset'));
  await dir.create(recursive: true);
  for (final size in _macosSizes) {
    final file = File(p.join(dir.path, 'app_icon_$size.png'));
    await file.writeAsBytes(_resizePng(master, size));
    print('  macOS  app_icon_$size.png');
  }
}

Future<void> _writeWindowsIco(Image master, Directory outRoot) async {
  final dir = Directory(p.join(outRoot.path, 'windows'));
  await dir.create(recursive: true);

  final tempPngs = <String>[];
  for (final size in _windowsIcoSizes) {
    final file = File(p.join(dir.path, 'app_icon_$size.png'));
    await file.writeAsBytes(_resizePng(master, size));
    tempPngs.add(file.path);
    print('  Windows app_icon_$size.png');
  }

  final icoPath = p.join(dir.path, 'app_icon.ico');
  final magick = await _findMagick();
  if (magick == null) {
    print(
      '  Skipped app_icon.ico (ImageMagick not found). Install magick or combine PNGs manually.',
    );
    return;
  }

  final result = magick == _MagickCli.magick
      ? await Process.run('magick', ['convert', ...tempPngs, icoPath])
      : await Process.run('convert', [...tempPngs, icoPath]);
  if (result.exitCode != 0) {
    print('  magick failed: ${result.stderr}');
    exitCode = 1;
    return;
  }
  print('  Windows app_icon.ico');
}

Future<void> _writeLinuxIcons(Image master, Directory outRoot) async {
  for (final size in _linuxSizes) {
    final dir = Directory(
      p.join(outRoot.path, 'linux', 'hicolor', '${size}x$size', 'apps'),
    );
    await dir.create(recursive: true);
    final file = File(p.join(dir.path, 'tawaq.png'));
    await file.writeAsBytes(_resizePng(master, size));
    print('  Linux  hicolor/${size}x$size/apps/tawaq.png');
  }
}

Future<void> _writeTrayIcons(Image trayMaster, Directory outRoot) async {
  final dir = Directory(p.join(outRoot.path, 'tray'));
  await dir.create(recursive: true);
  for (final size in _traySizes) {
    final file = File(p.join(dir.path, 'tray_icon_$size.png'));
    await file.writeAsBytes(_resizeTrayPng(trayMaster, size));
    print('  Tray   tray_icon_$size.png');
  }
  final primary = File(p.join(dir.path, 'tray_icon.png'));
  await primary.writeAsBytes(_resizeTrayPng(trayMaster, 32));
}

Future<void> _install(Directory repoRoot, Directory outRoot) async {
  final macosOut = Directory(
    p.join(
      repoRoot.path,
      'macos',
      'Runner',
      'Assets.xcassets',
      'AppIcon.appiconset',
    ),
  );
  await macosOut.create(recursive: true);
  for (final size in _macosSizes) {
    await _copyFile(
      p.join(outRoot.path, 'macos', 'AppIcon.appiconset', 'app_icon_$size.png'),
      p.join(macosOut.path, 'app_icon_$size.png'),
    );
  }

  final windowsResources = Directory(
    p.join(repoRoot.path, 'windows', 'runner', 'resources'),
  );
  await windowsResources.create(recursive: true);
  final ico = File(p.join(outRoot.path, 'windows', 'app_icon.ico'));
  if (ico.existsSync()) {
    await _copyFile(ico.path, p.join(windowsResources.path, 'app_icon.ico'));
  }

  final linuxOut = Directory(p.join(outRoot.path, 'linux', 'hicolor'));
  if (linuxOut.existsSync()) {
    final linuxDest = Directory(p.join(repoRoot.path, 'linux', 'icons', 'hicolor'));
    await _copyTree(linuxOut, linuxDest);
  }

  await _copyFile(
    p.join(outRoot.path, 'tray', 'tray_icon.png'),
    p.join(repoRoot.path, 'assets', 'images', 'tray_icon.png'),
  );
}

Uint8List _resizePng(Image source, int size) {
  final resized = copyResize(
    source,
    width: size,
    height: size,
    interpolation: Interpolation.cubic,
  );
  return Uint8List.fromList(encodePng(resized));
}

Uint8List _resizeTrayPng(Image source, int size) {
  final trimmed = _trimTransparent(source);
  final padding = (size * 0.12).round();
  final inner = math.max(1, size - padding * 2);
  final scaled = copyResize(
    trimmed,
    width: inner,
    height: inner,
    interpolation: Interpolation.cubic,
  );

  final canvas = Image(width: size, height: size, numChannels: 4);
  final offsetX = ((size - scaled.width) / 2).round();
  final offsetY = ((size - scaled.height) / 2).round();
  compositeImage(canvas, scaled, dstX: offsetX, dstY: offsetY);
  return Uint8List.fromList(encodePng(canvas));
}

Image _makeTrayFromAppIcon(Image source) {
  final rgba = source.convert(numChannels: 4);
  final bg = _estimateBackgroundColor(rgba);
  const threshold = 42;

  for (var y = 0; y < rgba.height; y++) {
    for (var x = 0; x < rgba.width; x++) {
      final pixel = rgba.getPixel(x, y);
      final dr = pixel.r - bg.$1;
      final dg = pixel.g - bg.$2;
      final db = pixel.b - bg.$3;
      final distance = math.sqrt(dr * dr + dg * dg + db * db);
      if (distance <= threshold) {
        rgba.setPixelRgba(x, y, pixel.r, pixel.g, pixel.b, 0);
      } else {
        rgba.setPixelRgba(x, y, pixel.r, pixel.g, pixel.b, 255);
      }
    }
  }

  return rgba;
}

(int, int, int) _estimateBackgroundColor(Image image) {
  final samples = <(int, int, int)>[];
  const sample = 6;
  final corners = [
    (0, 0),
    (image.width - sample, 0),
    (0, image.height - sample),
    (image.width - sample, image.height - sample),
  ];

  for (final (x0, y0) in corners) {
    var rSum = 0.0;
    var gSum = 0.0;
    var bSum = 0.0;
    var count = 0;
    for (var y = y0; y < y0 + sample && y < image.height; y++) {
      for (var x = x0; x < x0 + sample && x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        rSum += pixel.r;
        gSum += pixel.g;
        bSum += pixel.b;
        count++;
      }
    }
    samples.add((
      (rSum / count).round(),
      (gSum / count).round(),
      (bSum / count).round(),
    ));
  }

  final r = samples.map((s) => s.$1).reduce((a, b) => a + b) ~/ samples.length;
  final g = samples.map((s) => s.$2).reduce((a, b) => a + b) ~/ samples.length;
  final b = samples.map((s) => s.$3).reduce((a, b) => a + b) ~/ samples.length;
  return (r, g, b);
}

Image _trimTransparent(Image image) {
  var minX = image.width;
  var minY = image.height;
  var maxX = 0;
  var maxY = 0;

  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      if (image.getPixel(x, y).a > 16) {
        minX = math.min(minX, x);
        minY = math.min(minY, y);
        maxX = math.max(maxX, x);
        maxY = math.max(maxY, y);
      }
    }
  }

  if (maxX < minX || maxY < minY) {
    return image;
  }

  return copyCrop(
    image,
    x: minX,
    y: minY,
    width: maxX - minX + 1,
    height: maxY - minY + 1,
  );
}

enum _MagickCli { magick, convert }

Future<_MagickCli?> _findMagick() async {
  final magick = await Process.run('which', ['magick']);
  if (magick.exitCode == 0) {
    return _MagickCli.magick;
  }
  final convert = await Process.run('which', ['convert']);
  if (convert.exitCode == 0) {
    return _MagickCli.convert;
  }
  return null;
}

Future<void> _copyFile(String from, String to) async {
  await File(from).copy(to);
}

Future<void> _copyTree(Directory from, Directory to) async {
  if (to.existsSync()) {
    await to.delete(recursive: true);
  }
  await _copyDirectoryRecursive(from, to);
}

Future<void> _copyDirectoryRecursive(Directory from, Directory to) async {
  await to.create(recursive: true);
  await for (final entity in from.list()) {
    if (entity is File) {
      final dest = File(p.join(to.path, p.basename(entity.path)));
      await entity.copy(dest.path);
    } else if (entity is Directory) {
      await _copyDirectoryRecursive(
        entity,
        Directory(p.join(to.path, p.basename(entity.path))),
      );
    }
  }
}
