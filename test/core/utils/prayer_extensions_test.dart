import 'package:flutter_test/flutter_test.dart';
import 'package:hasanat/core/utils/prayer_extensions.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart';

void main() {
  setUpAll(tz.initializeTimeZones);

  group('DateTimeDifference', () {
    group('timeDifference', () {
      test('formats hours, minutes, seconds correctly', () {
        final time1 = DateTime(2024, 5, 15, 10, 30);
        final time2 = DateTime(2024, 5, 15, 8, 15, 30);

        // Difference is 2 hours, 14 minutes, 30 seconds
        expect(time1.timeDifference(time2), '02:14:30');
      });

      test('handles same time (zero difference)', () {
        final time = DateTime(2024, 5, 15, 10, 30);

        expect(time.timeDifference(time), '00:00:00');
      });

      test('handles small differences (under an hour)', () {
        final time1 = DateTime(2024, 5, 15, 10, 45, 30);
        final time2 = DateTime(2024, 5, 15, 10, 30);

        expect(time1.timeDifference(time2), '00:15:30');
      });

      test('handles large differences (multiple hours)', () {
        final time1 = DateTime(2024, 5, 15, 23, 59, 59);
        final time2 = DateTime(2024, 5, 15);

        expect(time1.timeDifference(time2), '23:59:59');
      });
    });

    group('toLocation', () {
      test('converts UTC to Riyadh timezone', () {
        final location = getLocation('Asia/Riyadh');
        final utcTime = DateTime.utc(2024, 5, 15, 12);

        final localTime = utcTime.toLocation(location);

        // Riyadh is UTC+3
        expect(localTime, isA<TZDateTime>());
        expect(localTime.hour, 15);
      });

      test('converts UTC to New York timezone', () {
        final location = getLocation('America/New_York');
        // January (EST, UTC-5)
        final utcTime = DateTime.utc(2024, 1, 15, 12);

        final localTime = utcTime.toLocation(location);

        expect(localTime, isA<TZDateTime>());
        expect(localTime.hour, 7); // 12 - 5 = 7
      });

      test('handles UTC timezone', () {
        final location = UTC;
        final utcTime = DateTime.utc(2024, 5, 15, 12);

        final localTime = utcTime.toLocation(location);

        expect(localTime.hour, 12);
      });
    });
  });

  group('DurationFormatting', () {
    group('toHHMMSS', () {
      test('formats duration with Western numerals', () {
        const duration = Duration(hours: 2, minutes: 30, seconds: 45);

        expect(duration.toHHMMSS(useHinduArabicNumerals: false), '02:30:45');
      });

      test('formats duration with Hindu-Arabic numerals', () {
        const duration = Duration(hours: 2, minutes: 30, seconds: 45);

        expect(duration.toHHMMSS(useHinduArabicNumerals: true), '٠٢:٣٠:٤٥');
      });

      test('formats zero duration', () {
        const duration = Duration.zero;

        expect(duration.toHHMMSS(useHinduArabicNumerals: false), '00:00:00');
      });

      test('pads single digits correctly', () {
        const duration = Duration(hours: 1, minutes: 5, seconds: 9);

        expect(duration.toHHMMSS(useHinduArabicNumerals: false), '01:05:09');
      });

      test('handles large hours', () {
        const duration = Duration(hours: 100);

        expect(duration.toHHMMSS(useHinduArabicNumerals: false), '100:00:00');
      });

      test('converts all digits to Hindu-Arabic', () {
        const duration = Duration(hours: 12, minutes: 34, seconds: 56);
        final result = duration.toHHMMSS(useHinduArabicNumerals: true);

        expect(result, '١٢:٣٤:٥٦');
        // Ensure no Western digits remain
        expect(RegExp(r'\d').hasMatch(result), isFalse);
      });
    });
  });
}
