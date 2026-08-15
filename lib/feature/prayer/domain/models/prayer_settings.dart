// Freezed annotations often target specific fields/getters.
// ignore_for_file: invalid_annotation_target

import 'package:adhan_dart/adhan_dart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tawaq/feature/prayer/domain/models/location_constants.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/timezone.dart';

part 'prayer_settings.freezed.dart';
part 'prayer_settings.g.dart';

/// Converts a JSON map to a map of [Prayer] to [int] adjustments.
///
/// Unknown prayer keys and non-int values are skipped (partial recover).
Map<Prayer, int> adhanAdjustmentsFromJson(Map<String, dynamic> json) {
  return _prayerIntMapFromJson(json);
}

/// Converts a map of [Prayer] to [int] adjustments to a JSON map.
Map<String, int> adhanAdjustmentsToJson(Map<Prayer, int> settings) {
  return settings.map((key, value) => MapEntry(key.name, value));
}

/// Converts a JSON map to a map of [Prayer] to [int] iqamah settings.
///
/// Unknown prayer keys and non-int values are skipped (partial recover).
Map<Prayer, int> iqamahSettingsFromJson(Map<String, dynamic> json) {
  return _prayerIntMapFromJson(json);
}

Map<Prayer, int> _prayerIntMapFromJson(Map<String, dynamic> json) {
  final out = <Prayer, int>{};
  for (final entry in json.entries) {
    final prayer = Prayer.values.where((e) => e.name == entry.key).firstOrNull;
    if (prayer == null) continue;
    final value = entry.value;
    if (value is int) {
      out[prayer] = value;
    } else if (value is num) {
      out[prayer] = value.toInt();
    }
  }
  return out;
}

/// Converts a map of [Prayer] to [int] iqamah settings to a JSON map.
Map<String, int> iqamahSettingsToJson(Map<Prayer, int> settings) {
  return settings.map((key, value) => MapEntry(key.name, value));
}

/// Converts a string to a [Location].
///
/// Invalid IANA names fall back to Asia/Riyadh so one bad field does not wipe
/// the entire [PrayerSettings] hydrate.
Location locationFromJson(String location) {
  try {
    return getLocation(location);
  } on Object {
    return tz.getLocation('Asia/Riyadh');
  }
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

  const PrayerSettings._();

  /// Returns the default prayer settings.
  factory PrayerSettings.defaultSettings() {
    return PrayerSettings(
      method: CalculationMethod.ummAlQura,
      is24Hours: false,
      iqamahSettings: {},
      adhanAdjustments: {},
      coordinates: Coordinates(0, 0),
      locationName: LocationConstants.defaultLocationName,
      location: tz.getLocation('Asia/Riyadh'),
    );
  }

  /// Creates a [PrayerSettings] instance from a JSON map.
  factory PrayerSettings.fromJson(Map<String, dynamic> json) =>
      _$PrayerSettingsFromJson(json);

  /// Whether [coordinates] are set to a real location (not the 0,0 sentinel).
  bool get isLocationReady =>
      !(coordinates.latitude == 0 && coordinates.longitude == 0);
}
