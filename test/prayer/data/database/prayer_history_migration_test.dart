import 'dart:convert';
import 'dart:io';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivez_flutter/hivez_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tawaq/feature/prayer/data/database/prayer_history_migration.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_completion.dart';
import 'package:tawaq/hive/hive_registrar.g.dart';

class _Box extends Mock implements Box<int, PrayerCompletion> {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late Box<int, PrayerCompletion> box;
  late PrayerHistoryMigration migration;
  late Map<int, PrayerCompletion> original;

  setUpAll(() => Hive.registerAdapters());

  setUp(() async {
    root = await Directory.systemTemp.createTemp('tawaq-history-migration-');
    Hive.init(root.path);
    box = Box<int, PrayerCompletion>('history');
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
    migration = PrayerHistoryMigration(
      box,
      Directory('${root.path}/migration'),
    );
  });
  tearDown(() async {
    await box.closeBox();
    await root.delete(recursive: true);
  });

  Future<Map<int, PrayerCompletion>> snapshot() async => {
    for (final key in await box.getAllKeys()) key: (await box.get(key))!,
  };
  Future<String> phase() async =>
      (jsonDecode(
            await File(
              '${root.path}/migration/${PrayerHistoryMigration.version}.journal.json',
            ).readAsString(),
          ) as Map)['phase']
          as String;

  test('exact backup, approved removal, independent reopen and rerun preserve all other wire statuses', () async {
    expect(CompletionStatus.values.map((s) => s.index), [0, 1, 2, 3, 4]);
    final digest = await migration.prepare();
    expect(await snapshot(), original);
    await expectLater(
      migration.apply(approvedBackupSha256: 'unapproved'),
      throwsStateError,
    );
    expect(await snapshot(), original);
    await migration.apply(approvedBackupSha256: digest);
    expect(await phase(), 'complete');
    await box.closeBox();
    box = Box<int, PrayerCompletion>('history');
    final expected = Map.of(original)..remove(13);
    expect(await snapshot(), expected);
    await PrayerHistoryMigration(
      box,
      migration.directory,
    ).apply(approvedBackupSha256: digest);
    expect(await snapshot(), expected);
    final backup = jsonDecode(
      await File(
        '${migration.directory.path}/${PrayerHistoryMigration.version}.backup.json',
      ).readAsString(),
    ) as Map;
    expect((backup['rows'] as List).length, 5);
    expect((backup['rows'] as List)[3]['value']['status'], 'missed');
  });

  test(
    'interrupted deletion can resume without touching other records',
    () async {
      final secondMissed = original[13]!.copyWith(id: 22);
      await box.put(22, secondMissed);
      final digest = await migration.prepare();
      await box.delete(13);
      await box.flushBox();
      await box.closeBox();
      box = Box<int, PrayerCompletion>('history');
      await PrayerHistoryMigration(
        box,
        migration.directory,
      ).apply(approvedBackupSha256: digest);
      expect(await snapshot(), Map.of(original)..remove(13));
      expect(await phase(), 'complete');
    },
  );

  test(
    'an edit after preparation refuses mutation and retains backup',
    () async {
      final digest = await migration.prepare();
      await box.put(10, original[10]!.copyWith(status: CompletionStatus.late));
      final edited = await snapshot();
      await expectLater(
        migration.apply(approvedBackupSha256: digest),
        throwsStateError,
      );
      expect(await snapshot(), edited);
      expect(await phase(), 'prepared');
    },
  );

  test(
    'failed durable flush never marks complete and retry acknowledges storage',
    () async {
      final digest = await migration.prepare();
      final failing = _Box();
      when(failing.getAllKeys).thenAnswer((_) => box.getAllKeys());
      when(() => failing.get(any()))
          .thenAnswer((call) => box.get(call.positionalArguments[0] as int));
      when(() => failing.delete(any()))
          .thenAnswer((call) => box.delete(call.positionalArguments[0] as int));
      when(failing.flushBox).thenThrow(StateError('injected flush failure'));
      await expectLater(
        PrayerHistoryMigration(
          failing,
          migration.directory,
        ).apply(approvedBackupSha256: digest),
        throwsStateError,
      );
      expect(await phase(), 'applying');
      await migration.apply(approvedBackupSha256: digest);
      expect(await phase(), 'complete');
      expect(await snapshot(), Map.of(original)..remove(13));
    },
  );
}
