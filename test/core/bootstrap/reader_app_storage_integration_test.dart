import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:path/path.dart' as p;
import 'package:tawaq/core/storage/app_storage_paths.dart';
import 'package:tawaq/feature/quran/data/models/quran_note.dart';
import 'package:tawaq/hive/hive_registrar.g.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('reader preparation preserves app adapter types and durable reflection round-trip', () async {
    final directory = await Directory.systemTemp.createTemp(
      'tawaq-reader-app-storage-',
    );
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getApplicationSupportDirectory') {
        return directory.path;
      }
      return null;
    });
    addTearDown(() async {
      await Hive.close();
      messenger.setMockMethodCallHandler(channel, null);
      await directory.delete(recursive: true);
    });
    final storagePaths = await AppStoragePaths.resolve();
    expect(storagePaths.hive.path, p.join(storagePaths.root.path, 'hive'));
    expect(
      storagePaths.quran.path,
      p.join(storagePaths.root.path, 'content', 'quran'),
    );
    await MushafReaderLibrary.ensureInitialized(
      storageDirectory: storagePaths.quran,
    );
    await Hive.initFlutter(storagePaths.hive.path);
    Hive.registerAdapters();
    final box = await Hive.openBox<QuranNote>('round-trip');
    final now = DateTime.utc(2026, 10, 5);
    final note = QuranNote(
      text: 'Integration fixture reflection',
      createdAt: now,
      updatedAt: now,
    );
    await box.put(1, note);
    await box.flush();
    await box.close();
    final reopened = await Hive.openBox<QuranNote>('round-trip');
    expect(reopened.get(1), note);
    expect(reopened.path, p.join(storagePaths.hive.path, 'round-trip.hive'));
    expect(
      File(p.join(directory.path, 'round-trip.hive')).existsSync(),
      isFalse,
    );
  });
}
