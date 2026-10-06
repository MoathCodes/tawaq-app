import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf_reader/src/data/hive/hive_box_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'failed initialization reaches caller once and a fresh acquisition retries',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'mushaf-init-recovery-',
      );
      final manager = HiveBoxManager.acquire();
      final unhandled = <Object>[];
      var attempts = 0;
      const channel = MethodChannel('plugins.flutter.io/path_provider');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'getApplicationDocumentsDirectory') {
          if (++attempts == 1)
            throw PlatformException(code: 'fixture-unavailable');
          return directory.path;
        }
        return null;
      });
      addTearDown(() async {
        HiveBoxManager.instance.closeAll();
        messenger.setMockMethodCallHandler(channel, null);
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await directory.delete(recursive: true);
      });
      await runZonedGuarded(() async {
        await expectLater(
          manager.init(subDirectory: 'retry'),
          throwsA(isA<PlatformException>()),
        );
        await Future<void>.delayed(Duration.zero);
      }, (error, stack) => unhandled.add(error));
      expect(
        unhandled,
        isEmpty,
        reason: 'The caller already handles the initialization error.',
      );
      expect(HiveBoxManager.refCount, 0);
      final retry = HiveBoxManager.acquire();
      await retry.init(subDirectory: 'retry');
      expect(retry.surahsBox.length, 114);
      expect(attempts, 2);
      retry.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      // A surviving manifest must not cause a missing bundled box to become empty.
      await File('${directory.path}/retry/surahs.hive').delete();
      final repair = HiveBoxManager.acquire();
      await repair.init(subDirectory: 'retry');
      expect(repair.surahsBox.length, 114);
      repair.dispose();
    },
  );
}
