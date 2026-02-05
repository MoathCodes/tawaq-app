import 'package:flutter_test/flutter_test.dart';
import 'package:hasanat/core/utils/date_extensions.dart';

void main() {
  group('DateExtensions', () {
    group('isSameDate', () {
      test('returns true for same date with different times', () {
        final date1 = DateTime(2024, 5, 15, 10, 30);
        final date2 = DateTime(2024, 5, 15, 22, 45);

        expect(date1.isSameDate(date2), isTrue);
      });

      test('returns true for exact same DateTime', () {
        final date = DateTime(2024, 5, 15, 10, 30);

        expect(date.isSameDate(date), isTrue);
      });

      test('returns false for different days', () {
        final date1 = DateTime(2024, 5, 15);
        final date2 = DateTime(2024, 5, 16);

        expect(date1.isSameDate(date2), isFalse);
      });

      test('returns false for different months', () {
        final date1 = DateTime(2024, 5, 15);
        final date2 = DateTime(2024, 6, 15);

        expect(date1.isSameDate(date2), isFalse);
      });

      test('returns false for different years', () {
        final date1 = DateTime(2024, 5, 15);
        final date2 = DateTime(2025, 5, 15);

        expect(date1.isSameDate(date2), isFalse);
      });

      test('handles midnight edge case', () {
        final endOfDay = DateTime(2024, 5, 15, 23, 59, 59);
        final startOfNextDay = DateTime(2024, 5, 16);

        expect(endOfDay.isSameDate(startOfNextDay), isFalse);
      });
    });

    group('isBetween', () {
      test('returns true when date is within range', () {
        final date = DateTime(2024, 5, 15);
        final from = DateTime(2024, 5, 10);
        final to = DateTime(2024, 5, 20);

        expect(date.isBetween(from, to), isTrue);
      });

      test('returns true when date equals from (inclusive)', () {
        final date = DateTime(2024, 5, 10);
        final from = DateTime(2024, 5, 10);
        final to = DateTime(2024, 5, 20);

        expect(date.isBetween(from, to), isTrue);
      });

      test('returns true when date equals to (inclusive)', () {
        final date = DateTime(2024, 5, 20);
        final from = DateTime(2024, 5, 10);
        final to = DateTime(2024, 5, 20);

        expect(date.isBetween(from, to), isTrue);
      });

      test('returns false when date is before range', () {
        final date = DateTime(2024, 5, 5);
        final from = DateTime(2024, 5, 10);
        final to = DateTime(2024, 5, 20);

        expect(date.isBetween(from, to), isFalse);
      });

      test('returns false when date is after range', () {
        final date = DateTime(2024, 5, 25);
        final from = DateTime(2024, 5, 10);
        final to = DateTime(2024, 5, 20);

        expect(date.isBetween(from, to), isFalse);
      });

      test('handles same from and to date', () {
        final date = DateTime(2024, 5, 15);
        final fromTo = DateTime(2024, 5, 15);

        expect(date.isBetween(fromTo, fromTo), isTrue);
      });

      test('returns true when date with time is on same day as boundaries', () {
        final date = DateTime(2024, 5, 15, 12, 30);
        final from = DateTime(2024, 5, 15);
        final to = DateTime(2024, 5, 15, 23, 59);

        expect(date.isBetween(from, to), isTrue);
      });
    });

    group('isAfterByDate', () {
      test('returns true when date is after by year', () {
        final date1 = DateTime(2025);
        final date2 = DateTime(2024, 12, 31);

        expect(date1.isAfterByDate(date2), isTrue);
      });

      test('returns true when date is after by month', () {
        final date1 = DateTime(2024, 6);
        final date2 = DateTime(2024, 5, 31);

        expect(date1.isAfterByDate(date2), isTrue);
      });

      test('returns true when date is after by day', () {
        final date1 = DateTime(2024, 5, 16);
        final date2 = DateTime(2024, 5, 15);

        expect(date1.isAfterByDate(date2), isTrue);
      });

      test('returns false for same date with different times', () {
        final date1 = DateTime(2024, 5, 15, 23, 59);
        final date2 = DateTime(2024, 5, 15);

        // Same date, even though time is after
        expect(date1.isAfterByDate(date2), isFalse);
      });

      test('returns false when date is before', () {
        final date1 = DateTime(2024, 5, 14);
        final date2 = DateTime(2024, 5, 15);

        expect(date1.isAfterByDate(date2), isFalse);
      });
    });

    group('isBeforeByDate', () {
      test('returns true when date is before by year', () {
        final date1 = DateTime(2024, 12, 31);
        final date2 = DateTime(2025);

        expect(date1.isBeforeByDate(date2), isTrue);
      });

      test('returns true when date is before by month', () {
        final date1 = DateTime(2024, 5, 31);
        final date2 = DateTime(2024, 6);

        expect(date1.isBeforeByDate(date2), isTrue);
      });

      test('returns true when date is before by day', () {
        final date1 = DateTime(2024, 5, 15);
        final date2 = DateTime(2024, 5, 16);

        expect(date1.isBeforeByDate(date2), isTrue);
      });

      test('returns false for same date with different times', () {
        final date1 = DateTime(2024, 5, 15);
        final date2 = DateTime(2024, 5, 15, 23, 59);

        // Same date, even though time is before
        expect(date1.isBeforeByDate(date2), isFalse);
      });

      test('returns false when date is after', () {
        final date1 = DateTime(2024, 5, 16);
        final date2 = DateTime(2024, 5, 15);

        expect(date1.isBeforeByDate(date2), isFalse);
      });
    });
  });
}
