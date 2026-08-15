import 'package:hijri_date/hijri.dart';
import 'package:timezone/timezone.dart' show TZDateTime;

/// Hijri date formatting keyed off Gregorian [DateTime]s.
///
/// Prayer data and scheduling stay on the Gregorian calendar; these helpers are
/// for presentation only.
abstract final class HijriFormat {
  /// Resolves a Hijri date for the given Gregorian [date].
  ///
  /// Uses [date]'s year/month/day wall components as-is. Do not call
  /// [DateTime.toLocal] first — when [date] is a prayer-TZ [TZDateTime], that
  /// would remap to the device timezone and can shift the calendar day.
  static HijriDate fromGregorian(DateTime date, String languageCode) {
    HijriDate.setLocal(_resolveLocale(languageCode));
    return HijriDate.fromDate(DateTime(date.year, date.month, date.day));
  }

  /// Formats [date] using hijri_date pattern tokens (`dd`, `MMMM`, `DD`, …).
  static String formatDate(
    DateTime date,
    String languageCode, {
    String pattern = 'dd MMMM yyyy',
  }) {
    return fromGregorian(date, languageCode).toFormat(pattern);
  }

  /// Full Hijri label for accessibility.
  static String accessibilityLabel(DateTime date, String languageCode) {
    return formatDate(date, languageCode, pattern: 'DDDD, dd MMMM yyyy');
  }

  /// Short weekday name for line-calendar cells.
  static String shortWeekday(DateTime date, String languageCode) {
    return formatDate(date, languageCode, pattern: 'DD');
  }

  /// Day-of-month numeral for line-calendar cells.
  static String dayOfMonth(DateTime date, String languageCode) {
    return formatDate(date, languageCode, pattern: 'dd');
  }

  static String _resolveLocale(String languageCode) {
    final code = languageCode.split('_').first;
    return switch (code) {
      'ar' => 'ar',
      'tr' => 'tr',
      'id' => 'id',
      'ms' => 'ms',
      'bn' => 'bn',
      'ur' => 'ur',
      'fil' => 'fil',
      _ => 'en',
    };
  }
}
