extension DateExtensions on DateTime {
  /// Checks if this [DateTime] is on the same day as [other].
  bool isAfterByDate(DateTime other) {
    return isAfter(other) &&
        (year > other.year ||
            (year == other.year &&
                (month > other.month ||
                    (month == other.month && day > other.day))));
  }

  bool isBeforeByDate(DateTime other) {
    return isBefore(other) &&
        (year < other.year ||
            (year == other.year &&
                (month < other.month ||
                    (month == other.month && day < other.day))));
  }

  bool isSameDate(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  bool isBetween(DateTime from, DateTime to) {
    return (isAfter(from) || isSameDate(from)) &&
        (isBefore(to) || isSameDate(to));
  }
}
