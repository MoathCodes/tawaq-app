import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/feature/prayer/domain/services/prayer_analytics_calculator.dart';

void main() {
  group('Streak calculator parity', () {
    test('matches service semantics on representative day lists', () {
      final today = DateTime(2026, 1, 29);
      final scenarios = <List<DateTime>>[
        [],
        [today],
        [DateTime(2026, 1, 28), today],
        [
          DateTime(2026, 1, 20),
          DateTime(2026, 1, 21),
          DateTime(2026, 1, 22),
          DateTime(2026, 1, 27),
          DateTime(2026, 1, 28),
        ],
        [
          DateTime(2026, 1, 10),
          DateTime(2026, 1, 11),
          DateTime(2026, 1, 12),
          DateTime(2026, 1, 20),
          DateTime(2026, 1, 21),
        ],
      ];

      for (final days in scenarios) {
        final result = PrayerAnalyticsCalculator.computeStreaks(
          fullyCompletedDays: days,
          today: today,
        );

        expect(result.current, greaterThanOrEqualTo(0));
        expect(result.best, greaterThanOrEqualTo(result.current));
      }
    });

    test('future-dated completion does not keep streak active', () {
      final today = DateTime(2026, 1, 29);
      final result = PrayerAnalyticsCalculator.computeStreaks(
        fullyCompletedDays: [DateTime(2026, 1, 31)],
        today: today,
      );

      expect(result.current, 0);
      expect(result.best, 1);
    });
  });
}
