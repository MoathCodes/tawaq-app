import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:tawaq/core/database/bundled_database_set_installer.dart';

void main() {
  test('failed multi-file staging preserves the complete active corpus; retry recovers', () async {
    final root = await Directory.systemTemp.createTemp('tawaq-corpus-');
    addTearDown(() => root.delete(recursive: true));
    Future<List<int>> databaseBytes(int value) async {
      final file = File(p.join(root.path, 'fixture.db'));
      if (await file.exists()) await file.delete();
      final database = sqlite3.open(file.path);
      database.execute('CREATE TABLE corpus (value INTEGER)');
      database.execute('INSERT INTO corpus VALUES ($value)');
      database.dispose();
      return file.readAsBytes();
    }

    final oldBytes = await databaseBytes(1);
    final newBytes = await databaseBytes(2);
    final oldDirectory = await installBundledDatabaseSet(
      root: root,
      versionKey: 'old',
      fileNames: ['a.db', 'b.db'],
      load: (_) async => oldBytes,
    );
    final marker = File(p.join(root.path, 'install.lock.json'));
    final previousMarker = await marker.readAsString();
    await expectLater(
      installBundledDatabaseSet(
        root: root,
        versionKey: 'new',
        fileNames: ['a.db', 'b.db'],
        load: (name) async {
          if (name == 'b.db')
            throw const FileSystemException('injected copy failure');
          return newBytes;
        },
      ),
      throwsA(isA<FileSystemException>()),
    );
    expect(await marker.readAsString(), previousMarker);
    expect(await File(p.join(oldDirectory, 'a.db')).readAsBytes(), oldBytes);
    final newDirectory = await installBundledDatabaseSet(
      root: root,
      versionKey: 'new',
      fileNames: ['a.db', 'b.db'],
      load: (_) async => newBytes,
    );
    expect(newDirectory, isNot(oldDirectory));
    expect(
      (jsonDecode(await marker.readAsString()) as Map)['version_key'],
      'new',
    );
    expect(await File(p.join(newDirectory, 'b.db')).readAsBytes(), newBytes);
    // A corrupt marker must not delete files still used by an existing reader.
    final open = sqlite3.open(
      p.join(newDirectory, 'a.db'),
      mode: OpenMode.readOnly,
    );
    await marker.writeAsString('{broken');
    final repaired = await installBundledDatabaseSet(
      root: root,
      versionKey: 'new',
      fileNames: ['a.db', 'b.db'],
      load: (_) async => newBytes,
    );
    expect(repaired, isNot(newDirectory));
    expect(await File(p.join(newDirectory, 'a.db')).readAsBytes(), newBytes);
    expect(open.select('SELECT value FROM corpus').single['value'], 2);
    open.dispose();
    // An identical install must not read/copy the source again.
    expect(
      await installBundledDatabaseSet(
        root: root,
        versionKey: 'new',
        fileNames: ['a.db', 'b.db'],
        load: (_) => throw StateError('unexpected replacement'),
      ),
      repaired,
    );
  });
}
