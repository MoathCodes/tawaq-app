import 'package:adhan_dart/adhan_dart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hasanat/feature/prayer/data/models/prayer_completion.dart';

part 'prayer_tracker_card_model.freezed.dart';

@freezed
abstract class PrayerTrackerCardModel with _$PrayerTrackerCardModel {
  const factory PrayerTrackerCardModel({
    required Prayer prayer,
    required String adhan,
    required String subtitle,
    required bool isCurrentPrayer,
    required bool isTimePassed,
    required PrayerCompletion? completion,
  }) = _PrayerTrackerCardModel;

  factory PrayerTrackerCardModel.empty() => const PrayerTrackerCardModel(
        prayer: Prayer.fajrAfter,
        adhan: "00:00",
        subtitle: "Fajr",
        isCurrentPrayer: false,
        isTimePassed: false,
        completion: null,
      );
}
