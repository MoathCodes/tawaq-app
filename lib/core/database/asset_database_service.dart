import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:tawaq/core/storage/app_storage_paths.dart';

part 'asset_database_service.g.dart';

const _persistedVersionFileSuffix = '.version.json';

/// Content identity; legacy size-only markers deliberately require a refresh.
String assetDatabaseVersionKey(List<int> bytes) =>
    'sha256:${sha256.convert(bytes)}';

/// Whether the on-disk copy must be replaced from the asset bundle.
bool assetDatabaseNeedsCopy({
  required bool fileExists,
  required String? persistedVersion,
  required String bundledVersion,
}) => !fileExists || persistedVersion != bundledVersion;

void _stageDatabaseBytes((String path, Uint8List bytes) args) {
  final file = File(args.$1);
  Directory(p.dirname(args.$1)).createSync(recursive: true);
  file.writeAsBytesSync(args.$2, flush: true);
  final staged = sqlite3.open(file.path, mode: OpenMode.readOnly);
  try {
    final check = staged.select('PRAGMA quick_check');
    if (check.length != 1 || check.first.values.single != 'ok') {
      throw StateError('Bundled database failed integrity validation');
    }
  } finally {
    staged.close();
  }
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
  final staging = File('$versionPath.staging');
  await staging.writeAsString(
    jsonEncode({'version_key': versionKey}),
    flush: true,
  );
  await staging.rename(versionPath);
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
/// a writable directory (application support) and opening them with sqlite3.
/// Databases are cached to avoid repeated copying and opening.
///
/// Copies are versioned (SHA-256 content digest, unlike fortress
/// `version_key`): a mismatch or missing on-disk file triggers replace.
class AssetDatabaseService {
  /// Creates an [AssetDatabaseService].
  ///
  /// [storageDirectory] and [loadAsset] are test seams; production uses the
  /// shared application storage paths and [rootBundle].
  new({
    Future<Directory> Function()? storageDirectory,
    Future<ByteData> Function(String assetPath)? loadAsset,
  }) : _storageDirectory =
           storageDirectory ??
           (() async => (await AppStoragePaths.resolve()).root),
       _loadAsset = loadAsset ?? rootBundle.load;

  final Future<Directory> Function() _storageDirectory;
  final Future<ByteData> Function(String assetPath) _loadAsset;

  final Map<String, Database> _openDatabases = {};
  final Map<String, Completer<Database>> _inFlight = {};
  bool _disposed = false;

  /// Opens a database from the given asset path.
  ///
  /// The database is copied to the application's content database directory
  /// when missing or when the bundled
  /// version key differs from the persisted one, then opened with sqlite3.
  /// Subsequent calls with the same [assetPath] return the cached instance.
  /// Concurrent opens for the same path share a single in-flight [Completer].
  Future<Database> openDatabase(String assetPath) {
    if (_disposed) {
      return Future.error(StateError('AssetDatabaseService has been disposed'));
    }

    final cached = _openDatabases[assetPath];
    if (cached != null) {
      return Future.value(cached);
    }

    final pending = _inFlight[assetPath];
    if (pending != null) {
      return pending.future;
    }

    final completer = Completer<Database>();
    _inFlight[assetPath] = completer;
    unawaited(_openDatabase(assetPath, completer));
    return completer.future;
  }

  Future<void> _openDatabase(
    String assetPath,
    Completer<Database> completer,
  ) async {
    try {
      final storageDirectory = await _storageDirectory();
      if (_disposed) {
        throw StateError('AssetDatabaseService has been disposed');
      }
      final dbFileName = p.basename(assetPath);
      final dbPath = p.join(
        storageDirectory.path,
        'content',
        'databases',
        dbFileName,
      );
      final versionPath = '$dbPath$_persistedVersionFileSuffix';

      final data = await _loadAsset(assetPath);
      if (_disposed) {
        throw StateError('AssetDatabaseService has been disposed');
      }
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      final bundledVersion = await Isolate.run(
        () => assetDatabaseVersionKey(bytes),
      );
      if (_disposed) throw StateError('AssetDatabaseService has been disposed');
      final persistedVersion = await _readPersistedVersionKey(versionPath);
      final dbFile = File(dbPath);
      final needsCopy = assetDatabaseNeedsCopy(
        fileExists: dbFile.existsSync(),
        persistedVersion: persistedVersion,
        bundledVersion: bundledVersion,
      );

      if (needsCopy) {
        final staging = File('$dbPath.staging');
        try {
          await Isolate.run(() => _stageDatabaseBytes((staging.path, bytes)));
          if (_disposed)
            throw StateError('AssetDatabaseService has been disposed');
          // No connection is published until the validated copy and marker land.
          // A crash between them is safe: the old marker forces another refresh.
          await staging.rename(dbPath);
          await _writePersistedVersionKey(versionPath, bundledVersion);
        } finally {
          if (await staging.exists()) await staging.delete();
        }
      }

      final raced = _openDatabases[assetPath];
      if (raced != null) {
        completer.complete(raced);
        return;
      }

      final database = sqlite3.open(dbPath);
      if (_disposed) {
        database.close();
        throw StateError('AssetDatabaseService has been disposed');
      }
      final existing = _openDatabases[assetPath];
      if (existing != null) {
        // Orphan: close the duplicate connection (sqlite3 Database.close).
        database.close();
        completer.complete(existing);
        return;
      }
      _openDatabases[assetPath] = database;
      completer.complete(database);
    } on Object catch (error, stackTrace) {
      if (!completer.isCompleted) {
        completer.completeError(error, stackTrace);
      }
    } finally {
      if (identical(_inFlight[assetPath], completer)) {
        _inFlight.remove(assetPath);
      }
    }
  }

  /// Closes all open databases and releases resources.
  void dispose() {
    if (_disposed) return;
    _disposed = true;

    for (final db in _openDatabases.values) {
      db.close();
    }
    _openDatabases.clear();

    final error = StateError('AssetDatabaseService has been disposed');
    for (final completer in _inFlight.values) {
      if (!completer.isCompleted) completer.completeError(error);
    }
    _inFlight.clear();
  }
}
