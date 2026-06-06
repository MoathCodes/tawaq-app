// Freezed annotations often target specific fields/getters.
// ignore_for_file: invalid_annotation_target

import 'package:adhan_dart/adhan_dart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tawaq/feature/settings/data/location_constants.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/timezone.dart';

part 'prayer_settings_model.freezed.dart';
part 'prayer_settings_model.g.dart';

/// Converts a JSON map to a map of [Prayer] to [int] adjustments.
Map<Prayer, int> adhanAdjustmentsFromJson(Map<String, dynamic> json) {
  return json.map(
    (key, value) =>
        MapEntry(Prayer.values.firstWhere((e) => e.name == key), value as int),
  );
}

/// Converts a map of [Prayer] to [int] adjustments to a JSON map.
Map<String, int> adhanAdjustmentsToJson(Map<Prayer, int> settings) {
  return settings.map((key, value) => MapEntry(key.name, value));
}

/// Converts a JSON map to a map of [Prayer] to [int] iqamah settings.
Map<Prayer, int> iqamahSettingsFromJson(Map<String, dynamic> json) {
  return json.map(
    (key, value) =>
        MapEntry(Prayer.values.firstWhere((e) => e.name == key), value as int),
  );
}

/// Converts a map of [Prayer] to [int] iqamah settings to a JSON map.
Map<String, int> iqamahSettingsToJson(Map<Prayer, int> settings) {
  return settings.map((key, value) => MapEntry(key.name, value));
}

/// Converts a string to a [Location].
Location locationFromJson(String location) {
  return getLocation(location);
}

/// Converts a [Location] to a string.
String locationToJson(Location location) {
  return location.name;
}

/// Converts a [CalculationMethod] to a JSON map.
Map<String, dynamic>? methodToJson(CalculationMethod method) {
  return method.toJson();
}

/// Persisted prayer-time configuration (method, location, iqamah, format).
///
/// Serialized to Hive via the prayer settings notifier and used by adhan
/// calculations across the prayer feature.
@freezed
abstract class PrayerSettings with _$PrayerSettings {
  /// Creates a [PrayerSettings] instance.
  const factory PrayerSettings({
    /// Calculation method (angles, madhab, high-latitude rules, adjustments).
    @JsonKey(
      name: 'calculation_method',
      fromJson: CalculationMethod.fromJson,
      toJson: methodToJson,
    )
    required CalculationMethod method,

    /// Human-readable label for the selected place (city or address).
    required String locationName,

    /// Latitude and longitude used for prayer-time math.
    @JsonKey(
      name: 'coordinates',
      fromJson: Coordinates.fromJson,
      toJson: Coordinates.toJson,
    )
    required Coordinates coordinates,

    /// When true, prayer times are shown in 24-hour format.
    required bool is24Hours,

    /// Minutes after adhan until iqamah, keyed by [Prayer].
    @JsonKey(
      name: 'iqamah_settings',
      fromJson: iqamahSettingsFromJson,
      toJson: iqamahSettingsToJson,
    )
    required Map<Prayer, int> iqamahSettings,

    /// Per-prayer adhan time adjustments in minutes (can be negative).
    @JsonKey(
      name: 'adhan_adjustments',
      fromJson: adhanAdjustmentsFromJson,
      toJson: adhanAdjustmentsToJson,
    )
    required Map<Prayer, int> adhanAdjustments,

    /// IANA timezone used with [coordinates] for local prayer times.
    @JsonKey(
      name: 'location',
      fromJson: locationFromJson,
      toJson: locationToJson,
    )
    required Location location,

    /// When true, GPS auto-updates coordinates and related fields.
    @JsonKey(name: 'auto_location') @Default(false) bool autoLocation,
  }) = _PrayerSettings;

  /// Returns the default prayer settings.
  factory PrayerSettings.defaultSettings() {
    return PrayerSettings(
      method: CalculationMethod.ummAlQura,
      is24Hours: false,
      iqamahSettings: {Prayer.dhuhr: 20},
      adhanAdjustments: {},
      coordinates: const Coordinates(0, 0),
      locationName: LocationConstants.defaultLocationName,
      location: tz.getLocation('Asia/Riyadh'),
    );
  }

  /// Creates a [PrayerSettings] instance from a JSON map.
  factory PrayerSettings.fromJson(Map<String, dynamic> json) =>
      _$PrayerSettingsFromJson(json);
}
