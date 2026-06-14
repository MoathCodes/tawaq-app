import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/feature/prayer/domain/services/adhan_time_utils.dart';

void main() {
  group('adhan time utils', () {
    test('applyAdhanAdjustment adds minutes', () {
      final base = DateTime(2026, 6, 9, 12);
      final adjusted = applyAdhanAdjustment(
        prayerTime: base,
        prayer: Prayer.dhuhr,
        adjustments: {Prayer.dhuhr: 5},
      );
      expect(adjusted, base.add(const Duration(minutes: 5)));
    });

    test('didCrossPrayerTime detects boundary within window', () {
      final target = DateTime(2026, 6, 9, 12);
      expect(
        didCrossPrayerTime(
          previous: target.subtract(const Duration(seconds: 1)),
          now: target.add(const Duration(seconds: 1)),
          target: target,
        ),
        isTrue,
      );
      expect(
        didCrossPrayerTime(
          previous: target.subtract(const Duration(minutes: 5)),
          now: target.add(const Duration(minutes: 5)),
          target: target,
        ),
        isFalse,
      );
    });

    test('didCrossPrayerTime does not fire twice after crossing', () {
      final target = DateTime(2026, 6, 9, 5, 30);
      expect(
        didCrossPrayerTime(
          previous: target.add(const Duration(seconds: 1)),
          now: target.add(const Duration(seconds: 2)),
          target: target,
        ),
        isFalse,
      );
    });

    test('adhanDayKey is stable per calendar day', () {
      expect(adhanDayKey(DateTime(2026, 6, 9)), 20260609);
    });
  });
}
