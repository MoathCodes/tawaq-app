// Freezed annotations often target specific fields/getters.
// ignore_for_file: invalid_annotation_target

import 'package:adhan_dart/adhan_dart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
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

/// Model representing prayer settings.
@freezed
abstract class PrayerSettings with _$PrayerSettings {
  /// Creates a [PrayerSettings] instance.
  const factory PrayerSettings({
    @JsonKey(
      name: 'calculation_method',
      fromJson: CalculationMethod.fromJson,
      toJson: methodToJson,
    )
    required CalculationMethod method,
    required String locationName,
    @JsonKey(
      name: 'coordinates',
      fromJson: Coordinates.fromJson,
      toJson: Coordinates.toJson,
    )
    required Coordinates coordinates,
    required bool is24Hours,
    @JsonKey(
      name: 'iqamah_settings',
      fromJson: iqamahSettingsFromJson,
      toJson: iqamahSettingsToJson,
    )
    required Map<Prayer, int> iqamahSettings,
    @JsonKey(
      name: 'adhan_adjustments',
      fromJson: adhanAdjustmentsFromJson,
      toJson: adhanAdjustmentsToJson,
    )
    required Map<Prayer, int> adhanAdjustments,
    @JsonKey(
      name: 'location',
      fromJson: locationFromJson,
      toJson: locationToJson,
    )
    required Location location,
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
      locationName: 'Default Location',
      location: tz.getLocation('Asia/Riyadh'),
    );
  }

  /// Creates a [PrayerSettings] instance from a JSON map.
  factory PrayerSettings.fromJson(Map<String, dynamic> json) =>
      _$PrayerSettingsFromJson(json);
}
