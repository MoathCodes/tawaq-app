import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf_reader/src/data/hive/hive_box_manager.dart';
import 'package:mushaf_reader/src/data/repository/hive_quran_repo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'repository completes cleanly when disposed during initialization',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'mushaf_reader_repo_lifecycle_',
      );
      addTearDown(() async {
        while (HiveQuranRepository.refCount > 0) {
          HiveQuranRepository.instance.dispose();
        }
        while (HiveBoxManager.refCount > 0) {
          HiveBoxManager.instance.dispose();
        }
        await Future<void>.delayed(const Duration(milliseconds: 100));
        if (tempDir.existsSync()) await tempDir.delete(recursive: true);
      });

      HiveQuranRepository.instance.closeAll();
      HiveBoxManager.instance.closeAll();
      final documents = Completer<String>();
      const channel = MethodChannel('plugins.flutter.io/path_provider');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'getApplicationDocumentsDirectory') {
              return documents.future;
            }
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );

      final repository = HiveQuranRepository.acquire();
      final initialization = repository.ensureReady();
      repository.dispose();
      documents.complete(tempDir.path);

      await expectLater(initialization, completes);
      expect(HiveQuranRepository.refCount, 0);
      expect(HiveBoxManager.refCount, 0);
    },
  );
}
