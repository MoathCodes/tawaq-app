/// Converts a [prayerCalendarDayKey] (`yyyymmdd`) to a naive calendar [DateTime].
DateTime dateFromCalendarDayKey(int dayKey) {
  return DateTime(
    dayKey ~/ 10000,
    (dayKey % 10000) ~/ 100,
    dayKey % 100,
  );
}

/// Stable day key for [date]'s calendar components (`yyyymmdd`).
int calendarDayKeyFromDate(DateTime date) {
  return date.year * 10000 + date.month * 100 + date.day;
}

/// Whether [date] matches [dayKey] on the calendar.
bool isSameCalendarDayKey(DateTime date, int dayKey) {
  return calendarDayKeyFromDate(date) == dayKey;
}
