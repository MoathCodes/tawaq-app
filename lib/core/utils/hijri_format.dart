import 'package:hijri_date/hijri.dart';

/// Hijri date formatting keyed off Gregorian [DateTime]s.
///
/// Prayer data and scheduling stay on the Gregorian calendar; these helpers are
/// for presentation only.
abstract final class HijriFormat {
  /// Resolves a Hijri date for the given Gregorian [date].
  static HijriDate fromGregorian(DateTime date, String languageCode) {
    HijriDate.setLocal(_resolveLocale(languageCode));
    return HijriDate.fromDate(date.toLocal());
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
