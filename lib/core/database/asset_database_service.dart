import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sqlite3/sqlite3.dart';

part 'asset_database_service.g.dart';

const _persistedVersionFileSuffix = '.version.json';

/// Bundled-asset version key (size fingerprint), mirrored after fortress.
String assetDatabaseVersionKey(int byteLength) => 'size:$byteLength';

/// Whether the on-disk copy must be replaced from the asset bundle.
bool assetDatabaseNeedsCopy({
  required bool fileExists,
  required String? persistedVersion,
  required String bundledVersion,
}) =>
    !fileExists || persistedVersion != bundledVersion;

void _copyDatabaseBytes((String path, Uint8List bytes) args) {
  final file = File(args.$1);
  Directory(p.dirname(args.$1)).createSync(recursive: true);
  file.writeAsBytesSync(args.$2, flush: true);
}

Future<String?> _readPersistedVersionKey(String versionPath) async {
  final file = File(versionPath);
  if (!file.existsSync()) return null;
  try {
    final persisted =
        jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final versionKey = persisted['version_key'];
    return versionKey is String && versionKey.isNotEmpty ? versionKey : null;
  } on Object {
    return null;
  }
}

Future<void> _writePersistedVersionKey(
  String versionPath,
  String versionKey,
) async {
  final file = File(versionPath);
  await file.parent.create(recursive: true);
  await file.writeAsString(
    jsonEncode({'version_key': versionKey}),
    flush: true,
  );
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
///
/// Copies are versioned (size fingerprint, same idea as fortress
/// `version_key`): a mismatch or missing on-disk file triggers replace.
class AssetDatabaseService {
  /// Creates an [AssetDatabaseService].
  ///
  /// [documentsDirectory] and [loadAsset] are test seams; production uses
  /// path_provider + [rootBundle].
  AssetDatabaseService({
    Future<Directory> Function()? documentsDirectory,
    Future<ByteData> Function(String assetPath)? loadAsset,
  }) : _documentsDirectory =
           documentsDirectory ?? getApplicationDocumentsDirectory,
       _loadAsset = loadAsset ?? rootBundle.load;

  final Future<Directory> Function() _documentsDirectory;
  final Future<ByteData> Function(String assetPath) _loadAsset;

  final Map<String, Database> _openDatabases = {};
  final Map<String, Completer<Database>> _inFlight = {};

  /// Opens a database from the given asset path.
  ///
  /// The database is copied to the app documents directory (under the
  /// `tawaq/databases/` subdirectory) when missing or when the bundled
  /// version key differs from the persisted one, then opened with sqlite3.
  /// Subsequent calls with the same [assetPath] return the cached instance.
  /// Concurrent opens for the same path share a single in-flight [Completer].
  Future<Database> openDatabase(String assetPath) async {
    final cached = _openDatabases[assetPath];
    if (cached != null) {
      return cached;
    }

    final pending = _inFlight[assetPath];
    if (pending != null) {
      return pending.future;
    }

    final completer = Completer<Database>();
    _inFlight[assetPath] = completer;
    try {
      final documentsDir = await _documentsDirectory();
      final dbFileName = p.basename(assetPath);
      final dbPath = p.join(
        documentsDir.path,
        'tawaq',
        'databases',
        dbFileName,
      );
      final versionPath = '$dbPath$_persistedVersionFileSuffix';

      final data = await _loadAsset(assetPath);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      final bundledVersion = assetDatabaseVersionKey(bytes.lengthInBytes);
      final persistedVersion = await _readPersistedVersionKey(versionPath);
      final dbFile = File(dbPath);
      final needsCopy = assetDatabaseNeedsCopy(
        fileExists: dbFile.existsSync(),
        persistedVersion: persistedVersion,
        bundledVersion: bundledVersion,
      );

      if (needsCopy) {
        await Isolate.run(() => _copyDatabaseBytes((dbPath, bytes)));
        await _writePersistedVersionKey(versionPath, bundledVersion);
      }

      final raced = _openDatabases[assetPath];
      if (raced != null) {
        completer.complete(raced);
        return raced;
      }

      final database = sqlite3.open(dbPath);
      final existing = _openDatabases[assetPath];
      if (existing != null) {
        // Orphan: close the duplicate connection (sqlite3 Database.close).
        database.close();
        completer.complete(existing);
        return existing;
      }
      _openDatabases[assetPath] = database;
      completer.complete(database);
      return database;
    } on Object catch (error, stackTrace) {
      completer.completeError(error, stackTrace);
      rethrow;
    } finally {
      _inFlight.remove(assetPath);
    }
  }

  /// Closes all open databases and releases resources.
  void dispose() {
    for (final db in _openDatabases.values) {
      db.close();
    }
    _openDatabases.clear();
    _inFlight.clear();
  }
}
