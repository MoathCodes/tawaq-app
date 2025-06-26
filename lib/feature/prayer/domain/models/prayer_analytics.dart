import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hasanat/l10n/app_localizations.dart';

part 'prayer_analytics.freezed.dart';

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

  factory PrayerAnalytics.empty() => const PrayerAnalytics(
        period: PrayerAnalyticsPeriod.weekly,
        completionPercentage: 0,
        currentStreak: 0,
        bestStreak: 0,
        jamaahPercentage: 0,
        onTimePercentage: 0,
        missedPercentage: 0,
        latePercentage: 0,
      );

  // factory PrayerAnalytics.fromJson(Map<String, dynamic> json) =>
  //     _$PrayerAnalyticsFromJson(json);
}

// part 'prayer_analytics.g.dart';

enum PrayerAnalyticsPeriod {
  // daily,
  weekly,
  monthly,
  yearly;

  Duration get duration {
    return switch (this) {
      PrayerAnalyticsPeriod.weekly => const Duration(days: 7),
      PrayerAnalyticsPeriod.monthly => const Duration(days: 30),
      PrayerAnalyticsPeriod.yearly => const Duration(days: 365),
    };
  }

  String getLocaleName(AppLocalizations l10n) {
    return switch (this) {
      PrayerAnalyticsPeriod.weekly => l10n.weekly,
      PrayerAnalyticsPeriod.monthly => l10n.monthly,
      PrayerAnalyticsPeriod.yearly => l10n.yearly,
    };
  }
}
