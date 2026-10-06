// Fixture overrides belong to an independent root test scope.
// ignore_for_file: riverpod_lint/scoped_providers_should_specify_dependencies

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivez_flutter/hivez_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/bootstrap/app_init_providers.dart';
import 'package:tawaq/feature/prayer/data/database/prayer_database.dart';
import 'package:tawaq/feature/prayer/data/database/prayer_history_migration.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_completion.dart';
import 'package:tawaq/hive/hive_registrar.g.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late Box<int, PrayerCompletion> box;
  late Map<int, PrayerCompletion> original;

  setUpAll(() {
    Hive.registerAdapters();
    tz.initializeTimeZones();
  });
  setUp(() async {
    root = await Directory.systemTemp.createTemp('tawaq-history-startup-');
    Hive.init(root.path);
    box = Box<int, PrayerCompletion>('prayer_completions');
    original = {
      for (final status in CompletionStatus.values)
        10 + status.index: PrayerCompletion(
          id: 10 + status.index,
          prayer: Prayer.fajr,
          completionTime: DateTime.utc(2026, 9, 20 + status.index, 4),
          status: status,
        ),
    };
    for (final entry in original.entries) {
      await box.put(entry.key, entry.value);
    }
  });
  tearDown(() async {
    await box.closeBox();
    await root.delete(recursive: true);
  });

  test(
    'startup backs up and removes missed before any read or write',
    () async {
      final storage = Completer<void>();
      final container = ProviderContainer(
        overrides: [hiveCoreInitProvider.overrideWith((ref) => storage.future)],
      );
      final database = container.read(prayerDatabaseProvider);
      var readFinished = false;
      final reading = database.getAllCompletions().then((rows) {
        readFinished = true;
        return rows;
      });
      final extra = PrayerCompletion(
        id: null,
        prayer: Prayer.dhuhr,
        completionTime: DateTime.utc(2026, 10, 4, 9),
        status: CompletionStatus.onTime,
      );
      final writing = database.insertOrUpdateCompletion(
        extra,
        getLocation('Asia/Riyadh'),
      );
      await Future<void>.delayed(Duration.zero);
      expect(readFinished, isFalse);
      expect((await box.getAllKeys()).toList()..sort(), original.keys.toList());
      storage.complete();
      await container.read(prayerHistoryReadyProvider.future);
      expect(await reading, isNot(contains(original[13])));
      await writing;
      for (final entry in original.entries) {
        expect(
          await box.get(entry.key),
          entry.key == 13 ? isNull : entry.value,
        );
      }
      final folder = Directory('${root.path}/migrations/prayer-history');
      final backup = jsonDecode(
        await File(
          '${folder.path}/${PrayerHistoryMigration.version}.backup.json',
        ).readAsString(),
      ) as Map;
      expect((backup['rows'] as List).length, original.length);
      final journal = jsonDecode(
        await File(
          '${folder.path}/${PrayerHistoryMigration.version}.journal.json',
        ).readAsString(),
      ) as Map;
      expect(journal['phase'], 'complete');
      await database.close();
      container.dispose();
      // Independent restart must use the completed marker without rewriting
      // the original backup or removing the newly recorded positive row.
      final backupBytes = await File(
        '${folder.path}/${PrayerHistoryMigration.version}.backup.json',
      ).readAsBytes();
      final restarted = ProviderContainer(
        overrides: [hiveCoreInitProvider.overrideWith((ref) async {})],
      );
      await restarted.read(prayerHistoryReadyProvider.future);
      expect(
        await restarted.read(prayerDatabaseProvider).getAllCompletions(),
        hasLength(5),
      );
      expect(
        await File(
          '${folder.path}/${PrayerHistoryMigration.version}.backup.json',
        ).readAsBytes(),
        backupBytes,
      );
      await restarted.read(prayerDatabaseProvider).close();
      restarted.dispose();
    },
  );

  test(
    'failed initialization blocks mutation and retries on the same owner',
    () async {
      var attempts = 0;
      final database = PrayerDatabase(
        box,
        initialize: () {
          if (++attempts == 1)
            throw StateError('fixture initialization failure');
          return Future<void>.value();
        },
      );
      await expectLater(database.deleteCompletion(10), throwsStateError);
      expect(await box.get(10), original[10]);
      await database.deleteCompletion(10);
      expect(await box.get(10), isNull);
      expect(attempts, 2);
    },
  );
}
