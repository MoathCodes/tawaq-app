import 'dart:io';
import 'dart:async';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:tawaq/core/database/asset_database_service.dart';
import 'package:tawaq/core/utils/app_clock_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_day.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_schedule/schedule_selected_date_provider.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_day_models.dart';
class DayKey extends Notifier<int> {
  @override int build() => 0;
  void set(int key) => state = key;
}
class FailingRepository implements IQuranRepository {
  final ready = Completer<void>();
  int calls = 0;
  @override Future<void> ensureReady() { calls++; return ready.future; }
  @override void dispose() {}
  @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('audit: failed mushaf readiness is reused on retry', () async {
    final repo = FailingRepository();
    final controller = MushafReaderController.withRepository(repository: repo);
    addTearDown(controller.dispose);
    final first = controller.ensureReady();
    final failure = expectLater(first, throwsStateError);
    repo.ready.completeError(StateError('temporary failure'));
    await failure;
    final retry = controller.ensureReady();
    expect(identical(first, retry), isTrue);
    await expectLater(retry, throwsStateError);
    expect(repo.calls, 1);
  });
  test('audit: same-size changed bundle leaves old installed content', () async {
    final dir = await Directory.systemTemp.createTemp('tawaq_audit_');
    addTearDown(() => dir.delete(recursive:true));
    Uint8List make(int value) {
      final path = '${dir.path}/source$value.db';
      final db = sqlite3.open(path);
      db.execute('CREATE TABLE t(x INTEGER)');
      db.execute('INSERT INTO t VALUES (?)', [value]);
      db.close();
      return File(path).readAsBytesSync();
    }
    final oldBytes = make(10), newBytes = make(20);
    expect(oldBytes.length, newBytes.length);
    AssetDatabaseService service(Uint8List bytes) => AssetDatabaseService(
      documentsDirectory: () async => dir,
      loadAsset: (_) async => ByteData.sublistView(bytes),
    );
    final first = service(oldBytes);
    await first.openDatabase('assets/demo.db');
    first.dispose();
    final second = service(newBytes);
    addTearDown(second.dispose);
    final installed = await second.openDatabase('assets/demo.db');
    expect(installed.select('SELECT x FROM t').first['x'], 10);
  });
  test('audit: first real configured day does not replace fallback date', () async {
    final key = NotifierProvider<DayKey,int>(DayKey.new);
    final container = ProviderContainer(overrides: [
      prayerCalendarDayKeyProvider.overrideWith((ref) => ref.watch(key)),
      prayerDayProvider.overrideWithBuild((ref, notifier) => const Stream<PrayerDaySnapshot>.empty()),
      appClockProvider.overrideWith((ref) => Stream.value(DateTime.utc(2026,9,6,22))),
    ]);
    addTearDown(container.dispose);
    final clock = container.listen(appClockProvider, (_,__){});
    addTearDown(clock.close);
    await container.read(appClockProvider.future);
    final sub = container.listen(scheduleSelectedDateProvider, (_,__){});
    addTearDown(sub.close);
    expect(container.read(scheduleSelectedDateProvider), DateTime(2026,9,6));
    container.read(key.notifier).set(20260907);
    expect(container.read(scheduleSelectedDateProvider), DateTime(2026,9,6));
  });
}
