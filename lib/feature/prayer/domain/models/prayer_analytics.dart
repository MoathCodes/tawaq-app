import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tawaq/l10n/app_localizations.dart';

part 'prayer_analytics.freezed.dart';

/// A class that holds the prayer analytics data.
@freezed
abstract class PrayerAnalytics with _$PrayerAnalytics {
  /// Creates a new instance of [PrayerAnalytics].
  const factory({
    /// The period of the analytics.
    required PrayerAnalyticsPeriod period,

    /// The percentage of completed prayers.
    required double completionPercentage,

    /// The current streak of completed prayers.
    required int currentStreak,

    /// The best streak of completed prayers.
    required int bestStreak,

    /// The percentage of prayers performed in congregation.
    required double jamaahPercentage,

    /// The percentage of prayers performed on time.
    required double onTimePercentage,

    /// The percentage of missed prayers.
    required double missedPercentage,

    /// The percentage of late prayers.
    required double latePercentage,
  }) = _PrayerAnalytics;

  /// Creates an empty instance of [PrayerAnalytics].
  factory empty() => const PrayerAnalytics(
    period: .weekly,
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

/// The period of the prayer analytics.
enum PrayerAnalyticsPeriod {
  /// The analytics for a single day.
  // daily,

  /// The analytics for the last 7 days.
  weekly,

  /// The analytics for the last 30 days.
  monthly,

  /// The analytics for the last 365 days.
  yearly
  ;

  /// The duration of the period.
  Duration get duration {
    return switch (this) {
      // .daily => const Duration(days: 1),
      .weekly => const Duration(days: 7),
      .monthly => const Duration(days: 30),
      .yearly => const Duration(days: 365),
    };
  }

  /// Returns the localized name of the period.
  String getLocaleName(AppLocalizations l10n) {
    return switch (this) {
      // .daily => l10n.daily,
      .weekly => l10n.weekly,
      .monthly => l10n.monthly,
      .yearly => l10n.yearly,
    };
  }
}
