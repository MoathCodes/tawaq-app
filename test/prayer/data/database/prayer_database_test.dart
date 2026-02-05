import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hasanat/feature/prayer/data/database/prayer_database.dart';
import 'package:hasanat/feature/prayer/data/models/prayer_completion.dart';
import 'package:hasanat/hive/hive_registrar.g.dart';
import 'package:hivez_flutter/hivez_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    tz.initializeTimeZones();
    Hive
      ..init('./test/hive_test_db')
      ..registerAdapters();
  });

  group('PrayerDatabase', () {
    late Box<int, PrayerCompletion> box;
    late PrayerDatabase db;
    late Location location;

    setUp(() async {
      location = getLocation('Asia/Riyadh');
      final boxName = 'prayer_db_test_${DateTime.now().millisecondsSinceEpoch}';
      box = Box<int, PrayerCompletion>(boxName);
      await box.clear();
      db = PrayerDatabase(box);
    });

    tearDown(() async {
      await box.clear();
      await box.deleteFromDisk();
    });

    group('insertOrUpdateCompletion', () {
      test('inserts new completion when none exists', () async {
        final completion = PrayerCompletion(
          id: null,
          prayer: Prayer.fajr,
          completionTime: DateTime(2024, 5, 15, 5),
          status: CompletionStatus.jamaah,
        );

        await db.insertOrUpdateCompletion(completion);

        final all = await db.getAllCompletions();
        expect(all, hasLength(1));
        expect(all.first.prayer, Prayer.fajr);
        expect(all.first.status, CompletionStatus.jamaah);
      });

      test('updates existing completion for same prayer and date', () async {
        final date = DateTime(2024, 5, 15, 5);

        // Insert initial
        await db.insertOrUpdateCompletion(
          PrayerCompletion(
            id: null,
            prayer: Prayer.fajr,
            completionTime: date,
            status: CompletionStatus.onTime,
          ),
        );

        // Update to jamaah
        await db.insertOrUpdateCompletion(
          PrayerCompletion(
            id: null,
            prayer: Prayer.fajr,
            completionTime: date,
            status: CompletionStatus.jamaah,
          ),
        );

        final all = await db.getAllCompletions();
        expect(all, hasLength(1), reason: 'Should not create duplicate');
        expect(all.first.status, CompletionStatus.jamaah);
      });

      test('allows different prayers on same date', () async {
        final date = DateTime(2024, 5, 15);

        for (final prayer in [Prayer.fajr, Prayer.dhuhr, Prayer.asr]) {
          await db.insertOrUpdateCompletion(
            PrayerCompletion(
              id: null,
              prayer: prayer,
              completionTime: date,
              status: CompletionStatus.onTime,
            ),
          );
        }

        final all = await db.getAllCompletions();
        expect(all, hasLength(3));
      });

      test('allows same prayer on different dates', () async {
        await db.insertOrUpdateCompletion(
          PrayerCompletion(
            id: null,
            prayer: Prayer.fajr,
            completionTime: DateTime(2024, 5, 15),
            status: CompletionStatus.onTime,
          ),
        );
        await db.insertOrUpdateCompletion(
          PrayerCompletion(
            id: null,
            prayer: Prayer.fajr,
            completionTime: DateTime(2024, 5, 16),
            status: CompletionStatus.onTime,
          ),
        );

        final all = await db.getAllCompletions();
        expect(all, hasLength(2));
      });
    });

    group('getCompletionsForDate', () {
      test('returns only completions for specified date', () async {
        await db.insertOrUpdateCompletion(
          PrayerCompletion(
            id: null,
            prayer: Prayer.fajr,
            completionTime: DateTime(2024, 5, 15, 5),
            status: CompletionStatus.onTime,
          ),
        );
        await db.insertOrUpdateCompletion(
          PrayerCompletion(
            id: null,
            prayer: Prayer.dhuhr,
            completionTime: DateTime(2024, 5, 15, 12, 30),
            status: CompletionStatus.jamaah,
          ),
        );
        await db.insertOrUpdateCompletion(
          PrayerCompletion(
            id: null,
            prayer: Prayer.fajr,
            completionTime: DateTime(2024, 5, 16, 5),
            status: CompletionStatus.onTime,
          ),
        );

        final result = await db.getCompletionsForDate(DateTime(2024, 5, 15));

        expect(result, hasLength(2));
        expect(result.every((c) => c.completionTime.day == 15), isTrue);
      });

      test('returns empty list when no completions for date', () async {
        await db.insertOrUpdateCompletion(
          PrayerCompletion(
            id: null,
            prayer: Prayer.fajr,
            completionTime: DateTime(2024, 5, 15),
            status: CompletionStatus.onTime,
          ),
        );

        final result = await db.getCompletionsForDate(DateTime(2024, 5, 20));

        expect(result, isEmpty);
      });
    });

    group('getCompletionsBetween', () {
      test('returns completions within date range (inclusive)', () async {
        await db.insertOrUpdateCompletion(
          PrayerCompletion(
            id: null,
            prayer: Prayer.fajr,
            completionTime: DateTime(2024, 5, 10),
            status: CompletionStatus.onTime,
          ),
        );
        await db.insertOrUpdateCompletion(
          PrayerCompletion(
            id: null,
            prayer: Prayer.dhuhr,
            completionTime: DateTime(2024, 5, 15),
            status: CompletionStatus.onTime,
          ),
        );
        await db.insertOrUpdateCompletion(
          PrayerCompletion(
            id: null,
            prayer: Prayer.asr,
            completionTime: DateTime(2024, 5, 20),
            status: CompletionStatus.onTime,
          ),
        );
        await db.insertOrUpdateCompletion(
          PrayerCompletion(
            id: null,
            prayer: Prayer.maghrib,
            completionTime: DateTime(2024, 5, 25),
            status: CompletionStatus.onTime,
          ),
        );

        final result = await db.getCompletionsBetween(
          DateTime(2024, 5, 15),
          DateTime(2024, 5, 20),
        );

        expect(result, hasLength(2));
      });
    });

    group('countAllPrayerStatusOnDate', () {
      test('returns counts for each status', () async {
        final baseDate = DateTime(2024, 5, 15);

        await db.insertOrUpdateCompletion(
          PrayerCompletion(
            id: null,
            prayer: Prayer.fajr,
            completionTime: baseDate,
            status: CompletionStatus.jamaah,
          ),
        );
        await db.insertOrUpdateCompletion(
          PrayerCompletion(
            id: null,
            prayer: Prayer.dhuhr,
            completionTime: baseDate,
            status: CompletionStatus.jamaah,
          ),
        );
        await db.insertOrUpdateCompletion(
          PrayerCompletion(
            id: null,
            prayer: Prayer.asr,
            completionTime: baseDate,
            status: CompletionStatus.onTime,
          ),
        );
        await db.insertOrUpdateCompletion(
          PrayerCompletion(
            id: null,
            prayer: Prayer.maghrib,
            completionTime: baseDate,
            status: CompletionStatus.late,
          ),
        );
        await db.insertOrUpdateCompletion(
          PrayerCompletion(
            id: null,
            prayer: Prayer.isha,
            completionTime: baseDate,
            status: CompletionStatus.missed,
          ),
        );

        final result = await db.countAllPrayerStatusOnDate(
          baseDate.subtract(const Duration(days: 1)),
          baseDate.add(const Duration(days: 1)),
        );

        expect(result[CompletionStatus.jamaah], 2);
        expect(result[CompletionStatus.onTime], 1);
        expect(result[CompletionStatus.late], 1);
        expect(result[CompletionStatus.missed], 1);
        expect(result[CompletionStatus.none], 0);
      });

      test('returns zeros for empty database', () async {
        final result = await db.countAllPrayerStatusOnDate(
          DateTime(2024, 5),
          DateTime(2024, 5, 31),
        );

        expect(result[CompletionStatus.jamaah], 0);
        expect(result[CompletionStatus.onTime], 0);
        expect(result[CompletionStatus.late], 0);
        expect(result[CompletionStatus.missed], 0);
        expect(result[CompletionStatus.none], 0);
      });
    });

    group('getFullyCompletedDays', () {
      Future<void> seedDay(
        DateTime date,
        List<CompletionStatus> statuses,
      ) async {
        final prayers = [
          Prayer.fajr,
          Prayer.dhuhr,
          Prayer.asr,
          Prayer.maghrib,
          Prayer.isha,
        ];
        for (var i = 0; i < prayers.length && i < statuses.length; i++) {
          await db.insertOrUpdateCompletion(
            PrayerCompletion(
              id: null,
              prayer: prayers[i],
              completionTime: date,
              status: statuses[i],
            ),
          );
        }
      }

      test('returns day when all 5 prayers are completed', () async {
        final date = DateTime(2024, 5, 15);
        await seedDay(date, [
          CompletionStatus.jamaah,
          CompletionStatus.onTime,
          CompletionStatus.onTime,
          CompletionStatus.onTime,
          CompletionStatus.jamaah,
        ]);

        final result = await db.getFullyCompletedDays(location);

        expect(result, hasLength(1));
        expect(result.first.day, 15);
      });

      test('excludes day when any prayer is missed', () async {
        final date = DateTime(2024, 5, 15);
        await seedDay(date, [
          CompletionStatus.jamaah,
          CompletionStatus.onTime,
          CompletionStatus.onTime,
          CompletionStatus.missed, // One missed
          CompletionStatus.onTime,
        ]);

        final result = await db.getFullyCompletedDays(location);

        expect(result, isEmpty);
      });

      test('excludes day when not all prayers are recorded', () async {
        final date = DateTime(2024, 5, 15);
        // Only 3 prayers recorded
        await db.insertOrUpdateCompletion(
          PrayerCompletion(
            id: null,
            prayer: Prayer.fajr,
            completionTime: date,
            status: CompletionStatus.onTime,
          ),
        );
        await db.insertOrUpdateCompletion(
          PrayerCompletion(
            id: null,
            prayer: Prayer.dhuhr,
            completionTime: date,
            status: CompletionStatus.onTime,
          ),
        );
        await db.insertOrUpdateCompletion(
          PrayerCompletion(
            id: null,
            prayer: Prayer.asr,
            completionTime: date,
            status: CompletionStatus.onTime,
          ),
        );

        final result = await db.getFullyCompletedDays(location);

        expect(result, isEmpty);
      });

      test('includes late prayers as completed', () async {
        final date = DateTime(2024, 5, 15);
        await seedDay(date, [
          CompletionStatus.late,
          CompletionStatus.late,
          CompletionStatus.late,
          CompletionStatus.late,
          CompletionStatus.late,
        ]);

        final result = await db.getFullyCompletedDays(location);

        expect(result, hasLength(1));
      });

      test('returns sorted list of dates', () async {
        await seedDay(
          DateTime(2024, 5, 20),
          List.filled(5, CompletionStatus.onTime),
        );
        await seedDay(
          DateTime(2024, 5, 10),
          List.filled(5, CompletionStatus.onTime),
        );
        await seedDay(
          DateTime(2024, 5, 15),
          List.filled(5, CompletionStatus.onTime),
        );

        final result = await db.getFullyCompletedDays(location);

        expect(result, hasLength(3));
        expect(result[0].day, 10);
        expect(result[1].day, 15);
        expect(result[2].day, 20);
      });
    });

    group('deleteCompletion', () {
      test('removes completion by id', () async {
        await db.insertOrUpdateCompletion(
          PrayerCompletion(
            id: null,
            prayer: Prayer.fajr,
            completionTime: DateTime(2024, 5, 15),
            status: CompletionStatus.onTime,
          ),
        );

        final all = await db.getAllCompletions();
        expect(all, hasLength(1));

        await db.deleteCompletion(all.first.id!);

        final afterDelete = await db.getAllCompletions();
        expect(afterDelete, isEmpty);
      });
    });

    group('isCompletionExists', () {
      test('returns true when completion exists', () async {
        await db.insertOrUpdateCompletion(
          PrayerCompletion(
            id: null,
            prayer: Prayer.fajr,
            completionTime: DateTime(2024, 5, 15),
            status: CompletionStatus.onTime,
          ),
        );

        final all = await db.getAllCompletions();
        final exists = await db.isCompletionExists(all.first.id!);

        expect(exists, isTrue);
      });

      test('returns false when completion does not exist', () async {
        final exists = await db.isCompletionExists(999999);

        expect(exists, isFalse);
      });
    });
  });
}
