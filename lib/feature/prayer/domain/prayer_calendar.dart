import 'package:tawaq/core/utils/prayer_extensions.dart';
import 'package:timezone/timezone.dart';

/// Converts a calendar day key (`yyyymmdd`) to a naive [DateTime].
///
/// Prefer [calendarDayFromKey] when the day key was computed in a specific
/// [Location]; this helper keeps call sites that only need year/month/day.
DateTime dateFromCalendarDayKey(int dayKey) {
  return DateTime(
    dayKey ~/ 10000,
    (dayKey % 10000) ~/ 100,
    dayKey % 100,
  );
}

/// Calendar midnight for [dayKey] in [location].
DateTime calendarDayFromKey(int dayKey, Location location) {
  return TZDateTime(
    location,
    dayKey ~/ 10000,
    (dayKey % 10000) ~/ 100,
    dayKey % 100,
  );
}

/// Stable day key from already-resolved calendar wall components (`yyyymmdd`).
///
/// Use only when [date]'s year/month/day already mean the intended calendar
/// day (e.g. a [TZDateTime] in the prayer location, or components from a day
/// key). For arbitrary instants, use [completionDayKey].
int calendarDayKeyFromDate(DateTime date) {
  return date.year * 10000 + date.month * 100 + date.day;
}

/// Whether [date]'s wall components match [dayKey].
bool isSameCalendarDayKey(DateTime date, int dayKey) {
  return calendarDayKeyFromDate(date) == dayKey;
}

/// Midnight on [time]'s calendar day in [location] (naive [DateTime]).
DateTime completionCalendarDay(DateTime time, Location location) {
  return time.calendarDayIn(location);
}

/// Stable grouping key `yyyyMMdd` for [time] in [location].
///
/// Canonical day-key entry point for instants. UI code that already holds
/// calendar components (from a day key) should use [calendarDayKeyFromDate].
int completionDayKey(DateTime time, Location location) {
  return calendarDayKeyFromDate(completionCalendarDay(time, location));
}
