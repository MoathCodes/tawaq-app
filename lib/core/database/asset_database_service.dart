import 'dart:io';
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sqlite3/sqlite3.dart';

part 'asset_database_service.g.dart';

void _copyDatabaseBytes((String path, Uint8List bytes) args) {
  final file = File(args.$1);
  Directory(p.dirname(args.$1)).createSync(recursive: true);
  file.writeAsBytesSync(args.$2, flush: true);
}

/// Provides a singleton instance of [AssetDatabaseService].
@Riverpod(keepAlive: true)
AssetDatabaseService assetDatabaseService(Ref ref) {
  final service = AssetDatabaseService();
  ref.onDispose(service.dispose);
  return service;
}

/// Service for managing SQLite databases bundled as Flutter assets.
///
/// This service handles copying database files from the assets bundle to
/// a writable directory (app documents) and opening them with sqlite3.
/// Databases are cached to avoid repeated copying and opening.
class AssetDatabaseService {
  final Map<String, Database> _openDatabases = {};

  /// Opens a database from the given asset path.
  ///
  /// The database is copied to the app documents directory (under the
  /// `tawaq/databases/` subdirectory) if it doesn't exist there yet,
  /// then opened with sqlite3. Subsequent calls with the same [assetPath]
  /// return the cached database instance.
  ///
  /// Example:
  /// ```dart
  /// final db = await service.openDatabase(
  ///   Assets.database.tafseerAr.tafseerMouaser,
  /// );
  /// final result = db.select('SELECT * FROM tafseer WHERE sura_no = ?', [1]);
  /// ```
  Future<Database> openDatabase(String assetPath) async {
    if (_openDatabases.containsKey(assetPath)) {
      return _openDatabases[assetPath]!;
    }

    final documentsDir = await getApplicationDocumentsDirectory();
    final dbFileName = p.basename(assetPath);
    final dbPath = p.join(
      documentsDir.path,
      'tawaq',
      'databases',
      dbFileName,
    );

    final dbFile = File(dbPath);
    if (!dbFile.existsSync()) {
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      await Isolate.run(() => _copyDatabaseBytes((dbPath, bytes)));
    }

    final database = sqlite3.open(dbPath);
    _openDatabases[assetPath] = database;

    return database;
  }

  /// Closes all open databases and releases resources.
  void dispose() {
    for (final db in _openDatabases.values) {
      db.close();
    }
    _openDatabases.clear();
  }
}
