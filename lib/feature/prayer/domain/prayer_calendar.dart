import 'package:tawaq/core/utils/prayer_extensions.dart';
import 'package:timezone/timezone.dart';

/// Converts a calendar day key (`yyyymmdd`) to a naive [DateTime].
DateTime dateFromCalendarDayKey(int dayKey) {
  return DateTime(
    dayKey ~/ 10000,
    (dayKey % 10000) ~/ 100,
    dayKey % 100,
  );
}

/// Stable day key from naive calendar components (`yyyymmdd`).
int calendarDayKeyFromDate(DateTime date) {
  return date.year * 10000 + date.month * 100 + date.day;
}

/// Whether [date] matches [dayKey] on the calendar.
bool isSameCalendarDayKey(DateTime date, int dayKey) {
  return calendarDayKeyFromDate(date) == dayKey;
}

/// Midnight on [time]'s calendar day in [location] (naive [DateTime]).
DateTime completionCalendarDay(DateTime time, Location location) {
  return time.calendarDayIn(location);
}

/// Stable grouping key `yyyyMMdd` in [location].
int completionDayKey(DateTime time, Location location) {
  return calendarDayKeyFromDate(completionCalendarDay(time, location));
}
