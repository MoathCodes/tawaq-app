import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hasanat/feature/prayer/data/models/prayer_completion.dart';

void main() {
  group('CompletionStatus', () {
    group('getBadgeColor', () {
      test('returns teal for jamaah (light mode)', () {
        final color = CompletionStatus.jamaah.getBadgeColor();

        expect(color, const Color(0xFF14B8A6));
      });

      test('returns dark teal for jamaah (dark mode)', () {
        final color = CompletionStatus.jamaah.getBadgeColor(isDark: true);

        expect(color, const Color(0xFF0F766E));
      });

      test('returns blue for onTime (light mode)', () {
        final color = CompletionStatus.onTime.getBadgeColor();

        expect(color, const Color(0xFF60A5FA));
      });

      test('returns dark blue for onTime (dark mode)', () {
        final color = CompletionStatus.onTime.getBadgeColor(isDark: true);

        expect(color, const Color(0xFF1E40AF));
      });

      test('returns amber for late (light mode)', () {
        final color = CompletionStatus.late.getBadgeColor();

        expect(color, const Color(0xFFF59E0B));
      });

      test('returns dark amber for late (dark mode)', () {
        final color = CompletionStatus.late.getBadgeColor(isDark: true);

        expect(color, const Color(0xFF92400E));
      });

      test('returns rose for missed (light mode)', () {
        final color = CompletionStatus.missed.getBadgeColor();

        expect(color, const Color(0xFFFB7185));
      });

      test('returns dark rose for missed (dark mode)', () {
        final color = CompletionStatus.missed.getBadgeColor(isDark: true);

        expect(color, const Color(0xFF9F1239));
      });

      test('returns transparent for none', () {
        final color = CompletionStatus.none.getBadgeColor();

        expect(color, Colors.transparent);
      });
    });

    group('getIcon', () {
      test('returns users icon for jamaah', () {
        final icon = CompletionStatus.jamaah.getIcon();

        expect(icon, isNotNull);
      });

      test('returns checkCheck icon for onTime', () {
        final icon = CompletionStatus.onTime.getIcon();

        expect(icon, isNotNull);
      });

      test('returns clock icon for late', () {
        final icon = CompletionStatus.late.getIcon();

        expect(icon, isNotNull);
      });

      test('returns circleX icon for missed', () {
        final icon = CompletionStatus.missed.getIcon();

        expect(icon, isNotNull);
      });

      test('returns null for none', () {
        final icon = CompletionStatus.none.getIcon();

        expect(icon, isNull);
      });
    });

    group('values', () {
      test('has 5 values', () {
        expect(CompletionStatus.values, hasLength(5));
      });

      test('contains all expected values', () {
        expect(
          CompletionStatus.values,
          containsAll([
            CompletionStatus.jamaah,
            CompletionStatus.onTime,
            CompletionStatus.late,
            CompletionStatus.missed,
            CompletionStatus.none,
          ]),
        );
      });
    });
  });

  group('PrayerCompletion', () {
    test('creates instance with required fields', () {
      final completion = PrayerCompletion(
        id: 1,
        prayer: Prayer.fajr,
        completionTime: DateTime(2024, 5, 15, 5),
        status: CompletionStatus.jamaah,
      );

      expect(completion.id, 1);
      expect(completion.prayer, Prayer.fajr);
      expect(completion.completionTime.day, 15);
      expect(completion.status, CompletionStatus.jamaah);
    });

    test('allows null id for new completions', () {
      final completion = PrayerCompletion(
        id: null,
        prayer: Prayer.dhuhr,
        completionTime: DateTime.now(),
        status: CompletionStatus.onTime,
      );

      expect(completion.id, isNull);
    });

    test('copyWith updates specified fields', () {
      final original = PrayerCompletion(
        id: 1,
        prayer: Prayer.fajr,
        completionTime: DateTime(2024, 5, 15),
        status: CompletionStatus.onTime,
      );

      final updated = original.copyWith(status: CompletionStatus.jamaah);

      expect(updated.id, original.id);
      expect(updated.prayer, original.prayer);
      expect(updated.completionTime, original.completionTime);
      expect(updated.status, CompletionStatus.jamaah);
    });

    test('copyWith preserves unmodified fields', () {
      final original = PrayerCompletion(
        id: 5,
        prayer: Prayer.isha,
        completionTime: DateTime(2024, 5, 15, 21),
        status: CompletionStatus.late,
      );

      final updated = original.copyWith(id: 10);

      expect(updated.id, 10);
      expect(updated.prayer, Prayer.isha);
      expect(updated.completionTime, original.completionTime);
      expect(updated.status, CompletionStatus.late);
    });

    test('equality works correctly', () {
      final a = PrayerCompletion(
        id: 1,
        prayer: Prayer.fajr,
        completionTime: DateTime(2024, 5, 15, 5),
        status: CompletionStatus.jamaah,
      );
      final b = PrayerCompletion(
        id: 1,
        prayer: Prayer.fajr,
        completionTime: DateTime(2024, 5, 15, 5),
        status: CompletionStatus.jamaah,
      );

      expect(a, equals(b));
    });

    test('different completions are not equal', () {
      final a = PrayerCompletion(
        id: 1,
        prayer: Prayer.fajr,
        completionTime: DateTime(2024, 5, 15),
        status: CompletionStatus.jamaah,
      );
      final b = PrayerCompletion(
        id: 2,
        prayer: Prayer.fajr,
        completionTime: DateTime(2024, 5, 15),
        status: CompletionStatus.jamaah,
      );

      expect(a, isNot(equals(b)));
    });
  });
}
