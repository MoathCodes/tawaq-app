import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hasanat/l10n/app_localizations.dart';

part 'prayer_analytics.freezed.dart';
// part 'prayer_analytics.g.dart';

enum PrayerAnalyticsPeriod {
  // daily,
  weekly,
  monthly,
  yearly;

  String getLocaleName(AppLocalizations l10n) {
    return switch (this) {
      PrayerAnalyticsPeriod.weekly => l10n.weekly,
      PrayerAnalyticsPeriod.monthly => l10n.monthly,
      PrayerAnalyticsPeriod.yearly => l10n.yearly,
    };
  }
}

@freezed
abstract class PrayerAnalytics with _$PrayerAnalytics {
  const factory PrayerAnalytics({
    required PrayerAnalyticsPeriod period,
    required double completionPercentage,
    required int currentStreak,
    required int bestStreak,
    required double jamaahPercentage,
    required double onTimePercentage,
    required double missedPercentage,
    required double latePercentage,
  }) = _PrayerAnalytics;

  // factory PrayerAnalytics.fromJson(Map<String, dynamic> json) =>
  //     _$PrayerAnalyticsFromJson(json);
}