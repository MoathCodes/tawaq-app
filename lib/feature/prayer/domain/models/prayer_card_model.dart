import 'package:adhan_dart/adhan_dart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'prayer_card_model.freezed.dart';

@freezed
abstract class PrayerCardInfo with _$PrayerCardInfo {
  const factory PrayerCardInfo({
    required String time,
    required Prayer prayer,
    required String adhanTime,
    required String iqamahTime,
  }) = _PrayerCardInfo;

  factory PrayerCardInfo.empty() => const PrayerCardInfo(
        time: "00:00",
        prayer: Prayer.fajrAfter,
        adhanTime: "00:00",
        iqamahTime: "00:00",
      );
}
