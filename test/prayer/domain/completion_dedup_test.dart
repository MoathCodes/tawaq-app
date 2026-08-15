import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/feature/prayer/domain/completion_dedup.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_completion.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart';

void main() {
  setUpAll(tz.initializeTimeZones);

  group('completion dedup helpers', () {
    late Location location;
    final day = DateTime(2024, 5, 15);

    setUp(() {
      location = getLocation('Asia/Riyadh');
    });

    test('pickCanonical prefers highest id', () {
      final rows = [
        PrayerCompletion(
          id: 1,
          prayer: Prayer.fajr,
          completionTime: day,
          status: CompletionStatus.onTime,
        ),
        PrayerCompletion(
          id: 3,
          prayer: Prayer.fajr,
          completionTime: day.add(const Duration(hours: 1)),
          status: CompletionStatus.jamaah,
        ),
      ];

      final canonical = pickCanonical(
        rows,
        prayer: Prayer.fajr,
        location: location,
        day: day,
      );

      expect(canonical?.id, 3);
      expect(canonical?.status, CompletionStatus.jamaah);
    });

    test('dedupeCompletions keeps one row per prayer per day', () {
      final rows = [
        PrayerCompletion(
          id: 1,
          prayer: Prayer.fajr,
          completionTime: day,
          status: CompletionStatus.onTime,
        ),
        PrayerCompletion(
          id: 2,
          prayer: Prayer.fajr,
          completionTime: day,
          status: CompletionStatus.late,
        ),
        PrayerCompletion(
          id: 3,
          prayer: Prayer.dhuhr,
          completionTime: day,
          status: CompletionStatus.jamaah,
        ),
      ];

      final deduped = dedupeCompletions(rows, location);

      expect(deduped, hasLength(2));
      expect(
        deduped.singleWhere((c) => c.prayer == Prayer.fajr).id,
        2,
      );
    });

    test('mapPrayerStatuses returns canonical statuses', () {
      final rows = [
        PrayerCompletion(
          id: 1,
          prayer: Prayer.fajr,
          completionTime: day,
          status: CompletionStatus.onTime,
        ),
        PrayerCompletion(
          id: 4,
          prayer: Prayer.fajr,
          completionTime: day,
          status: CompletionStatus.jamaah,
        ),
      ];

      final statuses = mapPrayerStatuses(rows, location, day);

      expect(statuses[Prayer.fajr], CompletionStatus.jamaah);
      expect(statuses[Prayer.dhuhr], CompletionStatus.none);
    });

    test('countDedupedStatuses does not double-count duplicates', () {
      final rows = [
        PrayerCompletion(
          id: 1,
          prayer: Prayer.fajr,
          completionTime: day,
          status: CompletionStatus.jamaah,
        ),
        PrayerCompletion(
          id: 2,
          prayer: Prayer.fajr,
          completionTime: day,
          status: CompletionStatus.onTime,
        ),
      ];

      final counts = countDedupedStatuses(rows, location);

      expect(counts[CompletionStatus.jamaah], 0);
      expect(counts[CompletionStatus.onTime], 1);
    });
  });
}
