import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_analytics.dart';

part 'prayer_analytics_prefs.freezed.dart';
part 'prayer_analytics_prefs.g.dart';

/// Persisted prayer analytics period selection.
@freezed
abstract class PrayerAnalyticsPrefs with _$PrayerAnalyticsPrefs {
  /// Creates a [PrayerAnalyticsPrefs] instance.
  const factory PrayerAnalyticsPrefs({
    @Default(PrayerAnalyticsPeriod.weekly) PrayerAnalyticsPeriod period,
  }) = _PrayerAnalyticsPrefs;

  /// Creates a [PrayerAnalyticsPrefs] instance from a JSON map.
  factory PrayerAnalyticsPrefs.fromJson(Map<String, dynamic> json) =>
      _$PrayerAnalyticsPrefsFromJson(json);

  /// Default prayer analytics prefs.
  factory PrayerAnalyticsPrefs.defaults() => const PrayerAnalyticsPrefs();
}
