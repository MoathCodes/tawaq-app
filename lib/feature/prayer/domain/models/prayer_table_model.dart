import 'package:adhan_dart/adhan_dart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'prayer_table_model.freezed.dart';

/// Model representing a row in the prayer times table.
@freezed
abstract class PrayerTableRow with _$PrayerTableRow {
  /// Creates a [PrayerTableRow] instance.
  const factory PrayerTableRow({
    required Prayer prayer,
    required ({String title, String? subtitle}) adhan,
    required ({String title, String? subtitle}) iqamah,
    required bool isCurrentPrayer,
    required bool isNextPrayer,
    // required bool isChecked,
  }) = _PrayerTableRow;
}
