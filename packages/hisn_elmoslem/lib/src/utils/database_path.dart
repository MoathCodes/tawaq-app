import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;

/// Resolves a bundled database asset to a readable file path.
Future<String> resolveDatabasePath(String fileName) async {
  final relativePath = 'assets/database/$fileName';

  try {
    final packageUri = await Isolate.resolvePackageUri(
      Uri.parse('package:hisn_elmoslem/$relativePath'),
    );
    if (packageUri != null) {
      final packageFile = File.fromUri(packageUri);
      if (packageFile.existsSync()) {
        return packageFile.path;
      }
    }
  } on UnsupportedError {
    // Flutter test/runtime — fall through to filesystem paths.
  } on Object {
    // Missing package config — fall through.
  }

  final possiblePaths = <String>[
    relativePath,
    p.join('assets/database', fileName),
    p.join('packages/hisn_elmoslem', relativePath),
    p.join(Directory.current.path, relativePath),
    p.join(Directory.current.path, 'assets/database', fileName),
    p.join(Directory.current.path, 'packages/hisn_elmoslem', relativePath),
    p.join(Directory.current.parent.path, 'packages/hisn_elmoslem', relativePath),
  ];

  for (final path in possiblePaths) {
    final file = File(path);
    if (file.existsSync()) {
      return file.absolute.path;
    }
  }

  throw StateError(
    'Database file not found: $fileName. Tried:\n'
    '${['package:hisn_elmoslem/$relativePath', ...possiblePaths].map((e) => '  - $e').join('\n')}',
  );
}

/// Directory containing all bundled Hisn SQLite files.
Future<String> resolveDatabaseDirectory() async {
  final hisnPath = await resolveDatabasePath('hisn_elmoslem.db');
  return p.dirname(hisnPath);
}
