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

/// Converts a string to a [CalculationMethod].
CalculationMethod calculationMethodFromJson(String method) {
  return CalculationMethod.values.firstWhere((e) => e.name == method);
}

/// Converts a [CalculationMethod] to a string.
String calculationMethodToJson(CalculationMethod method) {
  return method.name;
}

/// Converts a JSON map to [CalculationParameters].
CalculationParameters? customParametersFromJson(Map<String, dynamic>? json) {
  if (json == null) return null;
  return CalculationParameters(
    method: CalculationMethod.values.firstWhere(
      (e) => e.name == json['method'],
      orElse: () => CalculationMethod.other,
    ),
    fajrAngle: (json['fajr_angle'] as double?) ?? 18.0,
    ishaAngle: (json['isha_angle'] as double?) ?? 18.0,
    ishaInterval: json['isha_interval'] as int?,
    maghribAngle: json['maghrib_angle'] as double?,
    madhab: json['madhab'] != null
        ? Madhab.values.firstWhere((e) => e.name == json['madhab'])
        : Madhab.shafi,
    highLatitudeRule: json['high_latitude_rule'] != null
        ? HighLatitudeRule.values.firstWhere(
            (e) => e.name == json['high_latitude_rule'],
          )
        : HighLatitudeRule.middleOfTheNight,
    adjustments: json['adjustments'] != null
        ? Map<Prayer, int>.from(
            (json['adjustments'] as Map<String, int>).map(
              (key, value) => MapEntry(
                Prayer.values.firstWhere((e) => e.name == key),
                value,
              ),
            ),
          )
        : const {
            Prayer.fajr: 0,
            Prayer.sunrise: 0,
            Prayer.dhuhr: 0,
            Prayer.asr: 0,
            Prayer.maghrib: 0,
            Prayer.isha: 0,
          },
    methodAdjustments: json['method_adjustments'] != null
        ? Map<Prayer, int>.from(
            (json['method_adjustments'] as Map<String, int>).map(
              (key, value) => MapEntry(
                Prayer.values.firstWhere((e) => e.name == key),
                value,
              ),
            ),
          )
        : const {
            Prayer.fajr: 0,
            Prayer.sunrise: 0,
            Prayer.dhuhr: 0,
            Prayer.asr: 0,
            Prayer.maghrib: 0,
            Prayer.isha: 0,
          },
  );
}

/// Converts [CalculationParameters] to a JSON map.
Map<String, dynamic>? customParametersToJson(CalculationParameters? params) {
  if (params == null) return null;
  return {
    'method': params.method.name,
    'fajr_angle': params.fajrAngle,
    'isha_angle': params.ishaAngle,
    'isha_interval': params.ishaInterval,
    'maghrib_angle': params.maghribAngle,
    'madhab': params.madhab.name,
    'high_latitude_rule': params.highLatitudeRule.name,
    'adjustments': params.adjustments.map(
      (key, value) => MapEntry(key.name, value),
    ),
    'method_adjustments': params.methodAdjustments.map(
      (key, value) => MapEntry(key.name, value),
    ),
  };
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

/// Model representing prayer settings.
@freezed
abstract class PrayerSettings with _$PrayerSettings {
  /// Creates a [PrayerSettings] instance.
  const factory PrayerSettings({
    @JsonKey(
      name: 'calculation_method',
      fromJson: calculationMethodFromJson,
      toJson: calculationMethodToJson,
    )
    required CalculationMethod method,

    /// This will be used if and only if the calculation method is set to other.
    @JsonKey(
      name: 'custom_parameters',
      fromJson: customParametersFromJson,
      toJson: customParametersToJson,
    )
    required CalculationParameters? customParameters,
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
  }) = _PrayerSettings;

  /// Returns the default prayer settings.
  factory PrayerSettings.defaultSettings() {
    return PrayerSettings(
      method: CalculationMethod.ummAlQura,
      customParameters: null,
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
