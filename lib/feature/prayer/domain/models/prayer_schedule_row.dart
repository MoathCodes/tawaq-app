import 'package:adhan_dart/adhan_dart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tawaq/feature/prayer/data/models/prayer_completion.dart';

part 'prayer_schedule_row.freezed.dart';

/// Model representing a row in the prayer schedule.
///
/// This is a unified model used by both the prayer table and the schedule list.
/// It contains all the pre-computed data needed for display.
@freezed
abstract class PrayerScheduleRow with _$PrayerScheduleRow {
  /// Creates a [PrayerScheduleRow] instance.
  const factory PrayerScheduleRow({
    /// The prayer this row represents.
    required Prayer prayer,

    /// The actual DateTime for this prayer (in the user's timezone).
    required DateTime prayerTime,

    /// Formatted adhan time string.
    required String formattedAdhanTime,

    /// Formatted iqamah time string (null if not applicable).
    String? formattedIqamahTime,

    /// Relative time subtitle (e.g., "in 2 hours", "30 mins ago").
    String? relativeTimeSubtitle,

    /// Whether this is the currently active prayer.
    @Default(false) bool isCurrentPrayer,

    /// Whether this is the next upcoming prayer.
    @Default(false) bool isNextPrayer,

    /// The completion status for this prayer.
    @Default(CompletionStatus.none) CompletionStatus completionStatus,

    /// The completion time (date) for logging purposes.
    DateTime? completionDate,
  }) = _PrayerScheduleRow;
}
