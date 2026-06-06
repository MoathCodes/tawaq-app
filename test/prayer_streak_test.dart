import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivez_flutter/hivez_flutter.dart';
import 'package:logger/logger.dart';
import 'package:tawaq/feature/prayer/data/database/prayer_database.dart';
import 'package:tawaq/feature/prayer/data/models/prayer_completion.dart';
import 'package:tawaq/feature/prayer/data/repository/prayer_repo.dart';
import 'package:tawaq/feature/prayer/domain/services/prayer_service.dart';
import 'package:tawaq/feature/settings/data/models/prayer_settings_model.dart';
import 'package:tawaq/hive/hive_registrar.g.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Initialize Hive for tests with a temp directory
    Hive
      ..init('./test/hive_test_db')
      ..registerAdapters();
  });

  group('Prayer streak calculation', () {
    late Box<int, PrayerCompletion> box;
    late PrayerDatabase db;
    late PrayerRepo repo;
    late PrayerService service;
    final log = Logger();
    late Location loc;

    setUp(() async {
      tz.initializeTimeZones();
      loc = UTC;

      // Create a unique box name for each test to avoid conflicts
      final boxName = 'prayer_test_${DateTime.now().millisecondsSinceEpoch}';
      box = Box<int, PrayerCompletion>(boxName);

      // Clear any existing data
      await box.clear();

      db = PrayerDatabase(box);
      repo = PrayerRepo(prayerDatabase: db, log: log);
      final settings = PrayerSettings.defaultSettings().copyWith(location: loc);
      service = PrayerService(repo, settings, log);
    });

    tearDown(() async {
      await box.clear();
      await box.deleteFromDisk();
    });

    /// Helper to seed completed days
    /// [consecutiveDays] - number of consecutive days to seed
    /// [daysAgo] - how many days in the past the MOST RECENT day should be
    ///            (0 = today, 1 = yesterday, etc.)
    Future<void> seedConsecutiveDays(
      int consecutiveDays, {
      int daysAgo = 0,
    }) async {
      final now = TZDateTime.now(loc);
      final today = TZDateTime(loc, now.year, now.month, now.day);

      for (var i = 0; i < consecutiveDays; i++) {
        // Most recent day is at daysAgo, then go further back
        final dayDate = today.subtract(Duration(days: daysAgo + i));

        for (final prayer in const [
          Prayer.fajr,
          Prayer.dhuhr,
          Prayer.asr,
          Prayer.maghrib,
          Prayer.isha,
        ]) {
          final completion = PrayerCompletion(
            id: null, // Let Hivez auto-assign unique IDs
            completionTime: dayDate,
            prayer: prayer,
            status: CompletionStatus.jamaah,
          );
          await db.insertOrUpdateCompletion(completion, loc);
        }
      }
    }

    test('returns (0, 0) when no prayers completed', () async {
      final streaks = await service.computeStreaks(loc);

      expect(streaks.current, 0);
      expect(streaks.best, 0);
    });

    test('returns (1, 1) when only today is completed', () async {
      await seedConsecutiveDays(1);

      final streaks = await service.computeStreaks(loc);

      expect(streaks.current, 1);
      expect(streaks.best, 1);
    });

    test('computes current streak of 5 days ending today', () async {
      await seedConsecutiveDays(5);

      final streaks = await service.computeStreaks(loc);

      expect(streaks.current, 5);
      expect(streaks.best, 5);
    });

    test('current streak is active when yesterday was completed', () async {
      await seedConsecutiveDays(3, daysAgo: 1);

      final streaks = await service.computeStreaks(loc);

      expect(streaks.current, 3);
      expect(streaks.best, 3);
    });

    test(
      'current streak is broken when last completion was 2 days ago',
      () async {
        await seedConsecutiveDays(5, daysAgo: 2);

        final streaks = await service.computeStreaks(loc);

        expect(
          streaks.current,
          0,
          reason: 'Streak should be broken after 2 days gap',
        );
        expect(streaks.best, 5);
      },
    );

    test('computes best streak correctly with gap in middle', () async {
      // Seed 5 days ending today
      await seedConsecutiveDays(5);

      // Seed an older streak of 8 days that ended 10 days ago
      await seedConsecutiveDays(8, daysAgo: 10);

      final streaks = await service.computeStreaks(loc);

      expect(streaks.current, 5, reason: 'Current streak includes today');
      expect(streaks.best, 8, reason: 'Best streak is the longer past streak');
    });

    test('handles multiple gaps and finds longest streak', () async {
      // Streak 1: 3 days ending 25 days ago (Oct 23-25)
      await seedConsecutiveDays(3, daysAgo: 23);

      // GAP of 3 days (Oct 26-28)

      // Streak 2: 10 days ending 12 days ago (Oct 29-Nov 7) - BEST
      await seedConsecutiveDays(10, daysAgo: 11);

      // GAP of 8 days (Nov 8-15)

      // Streak 3: 2 days ending yesterday (Nov 16-17, current but short)
      await seedConsecutiveDays(2, daysAgo: 1);

      final streaks = await service.computeStreaks(loc);

      expect(streaks.current, 2, reason: 'Current streak is the recent 2 days');
      expect(streaks.best, 10, reason: 'Best streak is 10 days in the middle');
    });

    test('handles single day gaps correctly', () async {
      // Day 1-3 completed
      await seedConsecutiveDays(3, daysAgo: 5);

      // Gap on day 4 (4 days ago)

      // Day 5-6 completed (today and yesterday)
      await seedConsecutiveDays(2);

      final streaks = await service.computeStreaks(loc);

      expect(streaks.current, 2, reason: 'Current streak is recent 2 days');
      expect(streaks.best, 3, reason: 'Best streak is the older 3 days');
    });

    test('current streak extends with today completed', () async {
      // Complete yesterday
      await seedConsecutiveDays(1, daysAgo: 1);

      var streaks = await service.computeStreaks(loc);
      expect(streaks.current, 1);
      expect(streaks.best, 1);

      // Now complete today - streak should extend
      await seedConsecutiveDays(1);

      streaks = await service.computeStreaks(loc);
      expect(streaks.current, 2);
      expect(streaks.best, 2);
    });

    test('incomplete day (less than 5 prayers) does not count', () async {
      final now = TZDateTime.now(loc);
      final today = TZDateTime(loc, now.year, now.month, now.day);

      // Only complete 3 prayers today (not all 5)
      for (final prayer in const [Prayer.fajr, Prayer.dhuhr, Prayer.asr]) {
        await db.insertOrUpdateCompletion(
          PrayerCompletion(
            id: null,
            completionTime: today,
            prayer: prayer,
            status: CompletionStatus.jamaah,
          ),
          loc,
        );
      }

      final streaks = await service.computeStreaks(loc);

      expect(streaks.current, 0, reason: 'Incomplete day should not count');
      expect(streaks.best, 0);
    });

    test('missed or none status prayers do not count', () async {
      final now = TZDateTime.now(loc);
      final today = TZDateTime(loc, now.year, now.month, now.day);

      // Complete some prayers but mark some as missed
      await db.insertOrUpdateCompletion(
        PrayerCompletion(
          id: null,
          completionTime: today,
          prayer: Prayer.fajr,
          status: CompletionStatus.jamaah,
        ),
          loc,
        );
      await db.insertOrUpdateCompletion(
        PrayerCompletion(
          id: null,
          completionTime: today,
          prayer: Prayer.dhuhr,
          status: CompletionStatus.missed, // Missed!
        ),
          loc,
        );
      await db.insertOrUpdateCompletion(
        PrayerCompletion(
          id: null,
          completionTime: today,
          prayer: Prayer.asr,
          status: CompletionStatus.jamaah,
        ),
          loc,
        );
      await db.insertOrUpdateCompletion(
        PrayerCompletion(
          id: null,
          completionTime: today,
          prayer: Prayer.maghrib,
          status: CompletionStatus.jamaah,
        ),
          loc,
        );
      await db.insertOrUpdateCompletion(
        PrayerCompletion(
          id: null,
          completionTime: today,
          prayer: Prayer.isha,
          status: CompletionStatus.none, // None!
        ),
          loc,
        );

      final streaks = await service.computeStreaks(loc);

      expect(
        streaks.current,
        0,
        reason: 'Day with missed/none prayers should not count',
      );
      expect(streaks.best, 0);
    });

    test('long streak of 30 days is computed correctly', () async {
      await seedConsecutiveDays(30);

      final streaks = await service.computeStreaks(loc);

      expect(streaks.current, 30);
      expect(streaks.best, 30);
    });

    test('alternating days do not form a streak', () async {
      // Complete every other day: day 0, day 2, day 4, day 6
      final now = TZDateTime.now(loc);

      for (final daysBack in [0, 2, 4, 6]) {
        final dayDate = TZDateTime(
          loc,
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: daysBack));

        for (final prayer in const [
          Prayer.fajr,
          Prayer.dhuhr,
          Prayer.asr,
          Prayer.maghrib,
          Prayer.isha,
        ]) {
          await db.insertOrUpdateCompletion(
            PrayerCompletion(
              id: null,
              completionTime: dayDate,
              prayer: prayer,
              status: CompletionStatus.onTime,
            ),
            loc,
          );
        }
      }

      final streaks = await service.computeStreaks(loc);

      expect(streaks.current, 1, reason: 'Only today counts as current');
      expect(streaks.best, 1, reason: 'No consecutive days, so best is 1');
    });
  });
}
