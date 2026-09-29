import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mushaf_reader/src/data/hive/hive_box_manager.dart';
import 'package:mushaf_reader/src/data/repository/hive_quran_repo.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late Directory hostDir;
  late HiveBoxManager manager;
  late HiveQuranRepository repository;
  const channel = MethodChannel('plugins.flutter.io/path_provider');

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('mushaf_search_');
    hostDir = await Directory(p.join(tempDir.path, 'host')).create();
    Hive.init(hostDir.path);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => tempDir.path);
    manager = HiveBoxManager.acquire();
    await manager.init(subDirectory: 'reader');
    repository = HiveQuranRepository.acquire();
    await repository.ensureReady();
  });

  tearDownAll(() async {
    await Hive.close();
    repository.dispose();
    manager.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await tempDir.delete(recursive: true);
  });

  test('reader initialization preserves the host Hive directory', () async {
    final hostBox = await Hive.openBox<String>('host_settings');
    expect(hostBox.path, p.join(hostDir.path, 'host_settings.hive'));
    expect(
      manager.surahsBox.path,
      p.join(tempDir.path, 'reader', 'surahs.hive'),
    );
  });

  test('deferred search survives host Hive reinitialization', () async {
    // Tawaq initializes app storage after the reader but before the first search.
    Hive.init(hostDir.path);
    final box = await manager.ensureSearchIndexBoxOpen();
    expect(box.path, p.join(tempDir.path, 'reader', 'search_index.hive'));
    expect(box.length, 6236);
    expect(
      File(p.join(hostDir.path, 'search_index.hive')).existsSync(),
      isFalse,
    );

    final matches = await repository.searchAyahs('الرحمن');
    expect(matches.map((ayah) => ayah.ayahId), contains(1));
    expect(await repository.searchAyahs('ٱلرَّحْمَٰنِ'), matches);
    expect(await repository.searchAyahs('   '), isEmpty);
    expect(await repository.searchAyahs('zzzzzz'), isEmpty);
    expect(await repository.searchAyahs('الرحمن', maxResults: 2), hasLength(2));
    final scoped = await repository.searchAyahs('الرحمن', surahNumber: 55);
    expect(scoped, isNotEmpty);
    expect(scoped.every((ayah) => ayah.surahNumber == 55), isTrue);
  });
}
