// Keep explicit constructor names so Hive CE preserves persisted field IDs.
// ignore_for_file: unnecessary_type_name_in_constructor

import 'package:adhan_dart/adhan_dart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'prayer_completion.freezed.dart';
part 'prayer_completion.g.dart';

/// The status of a prayer completion.
enum CompletionStatus {
  /// The prayer was performed in congregation.
  jamaah,

  /// The prayer was performed on time.
  onTime,

  /// The prayer was performed late.
  late,

  /// Legacy wire value only. Retained at index 3 for compatible Hive decoding.
  /// A missed prayer is not a completion record; never offer this as input.
  missed,

  /// The prayer has not been performed yet.
  none,
}

/// User-selectable completion statuses; none clears a record.
const selectableCompletionStatuses = [
  CompletionStatus.jamaah,
  CompletionStatus.onTime,
  CompletionStatus.late,
  CompletionStatus.none,
];

/// A prayer completion.
@freezed
abstract class PrayerCompletion with _$PrayerCompletion {
  /// Creates a new instance of [PrayerCompletion].
  factory PrayerCompletion({
    /// The unique identifier of the prayer completion.
    required int? id,

    /// The prayer that was completed.
    required Prayer prayer,

    /// The time the prayer was completed.
    required DateTime completionTime,

    /// The status of the prayer completion.
    required CompletionStatus status,
  }) = _PrayerCompletion;

  /// Creates a new instance of [PrayerCompletion] from a JSON object.
  factory PrayerCompletion.fromJson(Map<String, dynamic> json) =>
      _$PrayerCompletionFromJson(json);
  // @override
  // Map<String, dynamic> toJson() => _$PrayerCompletionToJson(this);
}
