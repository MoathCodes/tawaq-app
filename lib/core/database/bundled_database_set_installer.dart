import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

/// Installs a coherent immutable corpus, publishing its pointer last.
/// Existing generations remain available to already-open connections.
Future<String> installBundledDatabaseSet({
  required Directory root,
  required String versionKey,
  required List<String> fileNames,
  required Future<List<int>> Function(String) load,
}) async {
  await root.create(recursive: true);
  final marker = File(p.join(root.path, 'install.lock.json'));
  try {
    final value =
        jsonDecode(await marker.readAsString()) as Map<String, dynamic>;
    final relative = value['directory'];
    if (value.containsKey('directory') &&
        (relative is! String ||
            relative.isEmpty ||
            relative == '.' ||
            relative == '..' ||
            relative != p.basename(relative))) {
      throw const FormatException('Invalid corpus directory pointer');
    }
    final directory =
        relative is String &&
            relative.isNotEmpty &&
            relative != '.' &&
            relative != '..' &&
            relative == p.basename(relative)
        ? p.join(root.path, relative)
        : root.path;
    if (value['version_key'] == versionKey &&
        fileNames.every((name) => File(p.join(directory, name)).existsSync())) {
      return directory;
    }
  } on Object {
    /* Missing/legacy/corrupt markers are refreshed safely. */
  }
  // A corrupt pointer must never cause deletion of a generation that an
  // existing reader may still have open. Each attempt gets its own directory.
  final prefix = 'corpus-${sha256.convert(utf8.encode(versionKey))}-';
  final staging = await root.createTemp(prefix);
  final generationName = '${p.basename(staging.path)}-ready';
  final generation = Directory(p.join(root.path, generationName));
  try {
    for (final name in fileNames) {
      if (name != p.basename(name))
        throw ArgumentError.value(name, 'fileNames');
      final bytes = await load(name);
      final file = File(p.join(staging.path, name));
      await file.writeAsBytes(bytes, flush: true);
      await Isolate.run(() {
        final database = sqlite3.open(file.path, mode: OpenMode.readOnly);
        try {
          final result = database.select('PRAGMA quick_check');
          if (result.length != 1 || result.single.values.single != 'ok') {
            throw const FormatException('Invalid bundled database');
          }
        } finally {
          database.dispose();
        }
      });
    }
    await staging.rename(generation.path);
    final stagedMarker = File('${marker.path}.staging');
    await stagedMarker.writeAsString(
      jsonEncode({'version_key': versionKey, 'directory': generationName}),
      flush: true,
    );
    await stagedMarker.rename(marker.path);
    return generation.path;
  } finally {
    if (await staging.exists()) await staging.delete(recursive: true);
  }
}
