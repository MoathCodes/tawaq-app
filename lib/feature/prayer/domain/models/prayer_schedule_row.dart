import 'package:adhan_dart/adhan_dart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'prayer_schedule_row.freezed.dart';

/// Model representing a row in the prayer schedule.
///
/// Pre-computed display data for the prayer table and schedule list.
@freezed
abstract class PrayerScheduleRow with _$PrayerScheduleRow {
  /// Creates a [PrayerScheduleRow] instance.
  const factory({
    /// The prayer this row represents.
    required Prayer prayer,

    /// The actual DateTime for this prayer (in the user's timezone).
    required DateTime prayerTime,

    /// Formatted adhan time string.
    required String formattedAdhanTime,

    /// Formatted iqamah time string (null if not applicable).
    String? formattedIqamahTime,

    /// The completion time (date) for logging purposes.
    DateTime? completionDate,
  }) = _PrayerScheduleRow;
}
