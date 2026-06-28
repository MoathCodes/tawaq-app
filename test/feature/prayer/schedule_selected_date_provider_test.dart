import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/feature/prayer/domain/prayer_calendar.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_day.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_schedule/schedule_selected_date_provider.dart';

void main() {
  group('prayer_calendar', () {
    test('dateFromCalendarDayKey round-trips with calendarDayKeyFromDate', () {
      const key = 20260618;
      final date = dateFromCalendarDayKey(key);
      expect(calendarDayKeyFromDate(date), key);
      expect(date, DateTime(2026, 6, 18));
    });

    test('isSameCalendarDayKey matches calendar components', () {
      expect(isSameCalendarDayKey(DateTime(2026, 6, 18), 20260618), isTrue);
      expect(isSameCalendarDayKey(DateTime(2026, 6, 17), 20260618), isFalse);
    });
  });

  group('ScheduleSelectedDate', () {
    late ProviderContainer container;
    late NotifierProvider<TestDayKeyNotifier, int> testDayKeyProvider;

    setUp(() {
      testDayKeyProvider = NotifierProvider<TestDayKeyNotifier, int>(
        TestDayKeyNotifier.new,
      );

      container = ProviderContainer(
        overrides: [
          prayerCalendarDayKeyProvider.overrideWith(
            (ref) => ref.watch(testDayKeyProvider),
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('initializes to today from calendar day key', () {
      container.read(testDayKeyProvider.notifier).setKey(20260618);

      expect(
        container.read(scheduleSelectedDateProvider),
        DateTime(2026, 6, 18),
      );
    });

    test('user selection persists when day key is unchanged', () {
      container.read(testDayKeyProvider.notifier).setKey(20260618);
      final yesterday = DateTime(2026, 6, 17);

      container.read(scheduleSelectedDateProvider.notifier).select(yesterday);

      expect(container.read(scheduleSelectedDateProvider), yesterday);
      // Re-read does not reset to today.
      expect(container.read(scheduleSelectedDateProvider), yesterday);
    });

    test('midnight rollover follows today when viewing today', () {
      container.read(testDayKeyProvider.notifier).setKey(20260618);
      expect(
        container.read(scheduleSelectedDateProvider),
        DateTime(2026, 6, 18),
      );

      container.read(testDayKeyProvider.notifier).setKey(20260619);

      expect(
        container.read(scheduleSelectedDateProvider),
        DateTime(2026, 6, 19),
      );
    });

    test('midnight rollover preserves historical selection', () {
      container.read(testDayKeyProvider.notifier).setKey(20260618);
      final historical = DateTime(2026, 6, 15);
      container
          .read(scheduleSelectedDateProvider.notifier)
          .select(historical);

      container.read(testDayKeyProvider.notifier).setKey(20260619);

      expect(container.read(scheduleSelectedDateProvider), historical);
    });
  });
}

class TestDayKeyNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setKey(int key) => state = key;
}
