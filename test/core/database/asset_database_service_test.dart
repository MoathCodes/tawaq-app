import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:tawaq/core/database/asset_database_service.dart';

Uint8List _sqliteBytes({required int rowCount}) {
  final file = File(
    p.join(
      Directory.systemTemp.path,
      'tawaq_sqlite_${rowCount}_${DateTime.now().microsecondsSinceEpoch}.db',
    ),
  );
  final db = sqlite3.open(file.path);
  try {
    db.execute('CREATE TABLE t(x INTEGER);');
    for (var i = 0; i < rowCount; i++) {
      db.execute('INSERT INTO t(x) VALUES (?);', [i]);
    }
  } finally {
    db.dispose();
  }
  final bytes = file.readAsBytesSync();
  file.deleteSync();
  return Uint8List.fromList(bytes);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('assetDatabaseNeedsCopy / version key', () {
    test('version key is size fingerprint', () {
      expect(assetDatabaseVersionKey(1024), 'size:1024');
    });

    test('needs copy when missing or version mismatch', () {
      expect(
        assetDatabaseNeedsCopy(
          fileExists: false,
          persistedVersion: null,
          bundledVersion: 'size:1',
        ),
        isTrue,
      );
      expect(
        assetDatabaseNeedsCopy(
          fileExists: true,
          persistedVersion: 'size:1',
          bundledVersion: 'size:1',
        ),
        isFalse,
      );
      expect(
        assetDatabaseNeedsCopy(
          fileExists: true,
          persistedVersion: 'size:1',
          bundledVersion: 'size:2',
        ),
        isTrue,
      );
    });
  });

  group('AssetDatabaseService re-copy', () {
    test('replaces on-disk file when bundled size changes', () async {
      final docs = await Directory.systemTemp.createTemp('tawaq_asset_db_');
      addTearDown(() => docs.delete(recursive: true));

      final v1 = _sqliteBytes(rowCount: 1);
      var bundled = v1;

      final service = AssetDatabaseService(
        documentsDirectory: () async => docs,
        loadAsset: (path) async {
          expect(path, 'assets/database/demo.db');
          return ByteData.sublistView(bundled);
        },
      );
      addTearDown(service.dispose);

      final db1 = await service.openDatabase('assets/database/demo.db');
      expect(db1.select('SELECT COUNT(*) AS c FROM t').first['c'], 1);
      service.dispose();

      final onDisk = File(p.join(docs.path, 'tawaq', 'databases', 'demo.db'));
      expect(onDisk.existsSync(), isTrue);
      final versionFile = File('${onDisk.path}.version.json');
      expect(
        jsonDecode(versionFile.readAsStringSync())['version_key'],
        assetDatabaseVersionKey(v1.length),
      );

      // Larger bundled asset → different size fingerprint → re-copy.
      // Force a larger file via a blob column (row count alone can stay one page).
      bundled = () {
        final file = File(
          p.join(
            docs.path,
            'bundle_v2_${DateTime.now().microsecondsSinceEpoch}.db',
          ),
        );
        final db = sqlite3.open(file.path);
        try {
          db.execute('CREATE TABLE t(x INTEGER, blob BLOB);');
          db.execute('INSERT INTO t(x, blob) VALUES (?, ?);', [
            1,
            Uint8List(32 * 1024),
          ]);
        } finally {
          db.dispose();
        }
        final bytes = Uint8List.fromList(file.readAsBytesSync());
        file.deleteSync();
        return bytes;
      }();
      expect(bundled.length, isNot(v1.length));

      final service2 = AssetDatabaseService(
        documentsDirectory: () async => docs,
        loadAsset: (path) async => ByteData.sublistView(bundled),
      );
      addTearDown(service2.dispose);

      final db2 = await service2.openDatabase('assets/database/demo.db');
      expect(
        db2.select('SELECT length(blob) AS n FROM t').first['n'],
        32 * 1024,
      );
      expect(
        jsonDecode(versionFile.readAsStringSync())['version_key'],
        assetDatabaseVersionKey(bundled.length),
      );
    });
  });
}
