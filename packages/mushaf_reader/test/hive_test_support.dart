import 'dart:io';

import 'package:path/path.dart' as p;

/// Resolves the package root by walking up until `pubspec.yaml` is found.
Directory findPackageRoot([Directory? start]) {
  var dir = start ?? Directory.current;
  while (!File(p.join(dir.path, 'pubspec.yaml')).existsSync()) {
    dir = dir.parent;
  }
  return dir;
}

/// Path to bundled hive assets under [findPackageRoot].
String bundledHiveAssetsPath([Directory? start]) =>
    p.join(findPackageRoot(start).path, 'assets', 'hive');
