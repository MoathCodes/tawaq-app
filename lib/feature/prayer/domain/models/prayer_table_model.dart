


import 'package:adhan_dart/adhan_dart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'prayer_table_model.freezed.dart';


@freezed
abstract class PrayerTableRow with _$PrayerTableRow {
  const factory PrayerTableRow({
    required Prayer prayer,
    required ({String title, String? subtitle}) adhan,
    required ({String title, String? subtitle}) iqamah,
    required bool isCurrentPrayer,
    required bool isNextPrayer,
    // required bool isChecked,
  }) = _PrayerTableRow;
}