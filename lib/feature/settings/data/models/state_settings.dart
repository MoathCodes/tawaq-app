import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_screen_state.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_analytics.dart';
import 'package:tawaq/feature/quran/domain/models/quran_screen_state.dart';

part 'state_settings.freezed.dart';
part 'state_settings.g.dart';

/// Model representing the application state settings.
@freezed
abstract class StateSettings with _$StateSettings {
  /// Creates a [StateSettings] instance.
  factory StateSettings({
    /// Whether the sidebar is collapsed.
    required bool sidebarCollapsed,

    /// Selected analytics period for the prayer analysis section.
    required PrayerAnalyticsPeriod prayerAnalyticsPeriod,

    /// Quran screen state including page info, font size, layout, etc.
    required QuranScreenState quranState,

    /// Hadith screen persisted UI state.
    required HadithScreenState hadithState,
  }) = _StateSettings;

  /// Creates a [StateSettings] instance from a JSON map.
  factory StateSettings.fromJson(Map<String, dynamic> json) =>
      _$StateSettingsFromJson(json);

  /// Creates a default [StateSettings] instance.
  factory StateSettings.initial() => StateSettings(
    sidebarCollapsed: false,
    quranState: QuranScreenState.initial(),
    hadithState: HadithScreenState.initial(),
    prayerAnalyticsPeriod: PrayerAnalyticsPeriod.weekly,
  );
}

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
