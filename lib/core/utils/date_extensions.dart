/// Extension methods for [DateTime] to perform date-only comparisons.
extension DateExtensions on DateTime {
  /// Checks if this [DateTime] is after [other] by date (ignoring time).
  bool isAfterByDate(DateTime other) {
    return isAfter(other) &&
        (year > other.year ||
            (year == other.year &&
                (month > other.month ||
                    (month == other.month && day > other.day))));
  }

  /// Checks if this [DateTime] is before [other] by date (ignoring time).
  bool isBeforeByDate(DateTime other) {
    return isBefore(other) &&
        (year < other.year ||
            (year == other.year &&
                (month < other.month ||
                    (month == other.month && day < other.day))));
  }

  /// Checks if this [DateTime] is on the same day as [other].
  bool isSameDate(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  /// Checks if this [DateTime] is between [from] and [to] (inclusive).
  bool isBetween(DateTime from, DateTime to) {
    return (isAfter(from) || isSameDate(from)) &&
        (isBefore(to) || isSameDate(to));
  }
}
