import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivez_flutter/hivez_flutter.dart';
import 'package:logger/logger.dart';
import 'package:tawaq/feature/prayer/data/database/prayer_database.dart';
import 'package:tawaq/feature/prayer/data/repository/prayer_repo.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_analytics.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_completion.dart';
import 'package:tawaq/feature/prayer/domain/services/prayer_analytics_calculator.dart';
import 'package:tawaq/hive/hive_registrar.g.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    Hive
      ..init('./test/hive_test_db')
      ..registerAdapters();
  });

  group('countAllStatusesOnPeriod window', () {
    late Box<int, PrayerCompletion> box;
    late PrayerRepo repo;
    late Location location;

    setUp(() async {
      tz.initializeTimeZones();
      location = UTC;

      final boxName =
          'period_count_test_${DateTime.now().millisecondsSinceEpoch}';
      box = Box<int, PrayerCompletion>(boxName);
      await box.clear();

      final db = PrayerDatabase(box);
      repo = PrayerRepo(prayerDatabase: db, log: Logger());
    });

    tearDown(() async {
      await box.clear();
      await box.deleteFromDisk();
    });

    Future<void> seed(
      DateTime date,
      CompletionStatus status,
    ) async {
      await repo.addOrUpdateCompletion(
        PrayerCompletion(
          id: null,
          prayer: Prayer.fajr,
          completionTime: date,
          status: status,
        ),
        location,
      );
    }

    test('weekly count excludes day before chart range start', () async {
      final anchor = DateTime(2026, 1, 29, 12);
      final range = PrayerAnalyticsCalculator.periodCalendarRange(
        PrayerAnalyticsPeriod.weekly,
        anchor,
      );
      final dayBeforeRange = range.start.subtract(const Duration(days: 1));

      await seed(dayBeforeRange, CompletionStatus.jamaah);
      await seed(range.start, CompletionStatus.jamaah);

      final counts = await repo.countAllStatusesOnPeriod(
        PrayerAnalyticsPeriod.weekly,
        location,
        anchor,
      );

      expect(counts[CompletionStatus.jamaah], 1);
    });

    test('weekly count includes day at range start', () async {
      final anchor = DateTime(2026, 1, 29, 12);
      final range = PrayerAnalyticsCalculator.periodCalendarRange(
        PrayerAnalyticsPeriod.weekly,
        anchor,
      );

      await seed(range.start, CompletionStatus.onTime);

      final counts = await repo.countAllStatusesOnPeriod(
        PrayerAnalyticsPeriod.weekly,
        location,
        anchor,
      );

      expect(counts[CompletionStatus.onTime], 1);
    });
  });
}
