import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/core/utils/hijri_format.dart';

void main() {
  group('HijriFormat', () {
    test('formats Gregorian date in English', () {
      final label = HijriFormat.formatDate(
        DateTime(2026, 6, 10),
        'en',
      );

      expect(label, isNotEmpty);
      expect(label, isNot(contains('June')));
    });

    test('formats day-of-month for line calendar cells', () {
      final day = HijriFormat.dayOfMonth(DateTime(2026, 6, 10), 'ar');

      expect(day, isNotEmpty);
      expect(day, isNot(contains('10')));
    });

    test('falls back to English for unsupported locales', () {
      expect(
        () => HijriFormat.fromGregorian(DateTime(2026, 6, 10), 'fr'),
        returnsNormally,
      );
    });
  });
}
