import 'package:adhan_dart/adhan_dart.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hasanat/feature/prayer/data/database/prayer_database.dart';
import 'package:hasanat/feature/prayer/data/models/prayer_completion.dart';
import 'package:hasanat/feature/prayer/data/repository/prayer_repo.dart';
import 'package:hasanat/feature/prayer/domain/services/prayer_service.dart';
import 'package:hasanat/feature/settings/data/models/prayer_settings_model.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Prayer streak calculation', () {
    late PrayerDatabase db;
    late PrayerRepo repo;
    late PrayerService service;
    final talker = TalkerFlutter.init();
    late Location loc;

    setUp(() {
      tz.initializeTimeZones();
      loc = UTC;
      db = PrayerDatabase(NativeDatabase.memory(), talker);
      repo = PrayerRepo(prayerDatabase: db, talker: talker);
      final settings = PrayerSettings.defaultSettings().copyWith(location: loc);
      service = PrayerService(repo, settings, talker);
    });

    Future<void> seedDays(int consecutiveDays) async {
      final now = TZDateTime.now(loc);
      int id = 1;
      for (int i = 0; i < consecutiveDays; i++) {
        final dayDate = TZDateTime(loc, now.year, now.month, now.day)
            .subtract(Duration(days: i));
        for (final prayer in const [
          Prayer.fajr,
          Prayer.dhuhr,
          Prayer.asr,
          Prayer.maghrib,
          Prayer.isha,
        ]) {
          await db.insertOrUpdateCompletion(
            PrayerCompletionsCompanion.insert(
              id: Value(id++),
              completionTime: dayDate,
              prayer: prayer,
              status: CompletionStatus.jamaah,
            ),
          );
        }
      }
      print(await db.select(db.prayerCompletions).get().then(
            (value) => value.length,
          ));
    }

    test('computes current and best streak', () async {
      await seedDays(5); // current streak of 5 consecutive days ending today

      // Seed an older streak of 8 days that ended 10 days ago
      final now = TZDateTime.now(loc);
      int idCounter = 10000;
      for (int offset = 10; offset < 18; offset++) {
        final day = TZDateTime(loc, now.year, now.month, now.day)
            .subtract(Duration(days: offset));
        for (final p in [
          Prayer.fajr,
          Prayer.dhuhr,
          Prayer.asr,
          Prayer.maghrib,
          Prayer.isha
        ]) {
          await db.insertOrUpdateCompletion(
            PrayerCompletionsCompanion.insert(
              id: Value(idCounter++),
              completionTime: day,
              prayer: p,
              status: CompletionStatus.jamaah,
            ),
          );
        }
      }

      final streaks = await service.computeStreaks(loc);

      expect(streaks.current, 5);
      expect(streaks.best, 8);
    });
  });
}
