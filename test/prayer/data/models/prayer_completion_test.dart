import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/feature/prayer/data/models/prayer_completion.dart';
import 'package:tawaq/feature/prayer/presentation/extensions/completion_status_ui.dart';

void main() {
  group('CompletionStatus', () {
    group('getBadgeColor', () {
      late FColors lightColors;
      late FColors darkColors;

      setUp(() {
        lightColors = FTheme.neutral.light.desktop.colors;
        darkColors = FTheme.neutral.dark.desktop.colors;
      });

      test('jamaah returns primary color', () {
        expect(
          CompletionStatus.jamaah.getBadgeColor(lightColors),
          lightColors.primary,
        );
        expect(
          CompletionStatus.jamaah.getBadgeColor(darkColors),
          darkColors.primary,
        );
      });

      test(
        'onTime returns blended color between primary and mutedForeground',
        () {
          final color = CompletionStatus.onTime.getBadgeColor(lightColors);

          expect(color, isNot(equals(lightColors.primary)));
          expect(color, isNot(equals(lightColors.mutedForeground)));
          expect(color, isNot(equals(Colors.transparent)));
          expect(
            color,
            Color.lerp(lightColors.primary, lightColors.mutedForeground, 0.35),
          );
        },
      );

      test('late returns further blended color toward mutedForeground', () {
        final color = CompletionStatus.late.getBadgeColor(lightColors);

        expect(color, isNot(equals(lightColors.primary)));
        expect(
          color,
          Color.lerp(lightColors.primary, lightColors.mutedForeground, 0.65),
        );
      });

      test('missed returns mostly mutedForeground blend', () {
        final color = CompletionStatus.missed.getBadgeColor(lightColors);

        expect(color, isNot(equals(lightColors.primary)));
        expect(
          color,
          Color.lerp(lightColors.primary, lightColors.mutedForeground, 0.85),
        );
      });

      test('colors form a gradient hierarchy from primary to muted', () {
        final jamaah = CompletionStatus.jamaah.getBadgeColor(lightColors);
        final onTime = CompletionStatus.onTime.getBadgeColor(lightColors);
        final late = CompletionStatus.late.getBadgeColor(lightColors);
        final missed = CompletionStatus.missed.getBadgeColor(lightColors);

        // All should be distinct
        expect({jamaah, onTime, late, missed}.length, 4);
      });

      test('returns transparent for none', () {
        final color = CompletionStatus.none.getBadgeColor(lightColors);

        expect(color, Colors.transparent);
      });

      test('adapts to dark theme colors', () {
        final lightJamaah = CompletionStatus.jamaah.getBadgeColor(lightColors);
        final darkJamaah = CompletionStatus.jamaah.getBadgeColor(darkColors);

        // Different themes produce different colors
        expect(lightJamaah, isNot(equals(darkJamaah)));
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

    group('trackerCycleNext', () {
      test('cycles through logged statuses then clears', () {
        expect(CompletionStatus.none.trackerCycleNext, CompletionStatus.jamaah);
        expect(
          CompletionStatus.jamaah.trackerCycleNext,
          CompletionStatus.onTime,
        );
        expect(
          CompletionStatus.onTime.trackerCycleNext,
          CompletionStatus.late,
        );
        expect(CompletionStatus.late.trackerCycleNext, CompletionStatus.missed);
        expect(CompletionStatus.missed.trackerCycleNext, isNull);
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
