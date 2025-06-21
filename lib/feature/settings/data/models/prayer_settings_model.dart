// ignore_for_file: invalid_annotation_target

import 'package:adhan_dart/adhan_dart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/timezone.dart';

part 'prayer_settings_model.freezed.dart';
part 'prayer_settings_model.g.dart';

CalculationMethod calculationMethodFromJson(String method) {
  return CalculationMethod.values.firstWhere((e) => e.name == method);
}

String calculationMethodToJson(CalculationMethod method) {
  return method.name;
}

Coordinates coordinatesFromJson(Map<String, dynamic> json) {
  return Coordinates(json['latitude'] as double, json['longitude'] as double);
}

Map<String, dynamic> coordinatesToJson(Coordinates coords) {
  return {
    'latitude': coords.latitude,
    'longitude': coords.longitude,
  };
}

Map<Prayer, int> iqamahSettingsFromJson(Map<String, dynamic> json) {
  return json.map((key, value) =>
      MapEntry(Prayer.values.firstWhere((e) => e.name == key), value as int));
}

Map<String, int> iqamahSettingsToJson(Map<Prayer, int> settings) {
  return settings.map((key, value) => MapEntry(key.name, value));
}

Location locationFromJson(String location) {
  return getLocation(location);
}

String locationToJson(Location location) {
  return location.name;
}

@freezed
abstract class PrayerSettings with _$PrayerSettings {
  const factory PrayerSettings(
      {@JsonKey(
          name: 'calculation_method',
          fromJson: calculationMethodFromJson,
          toJson: calculationMethodToJson)
      required CalculationMethod method,
      required bool is24Hours,
      @JsonKey(
          name: 'iqamah_settings',
          fromJson: iqamahSettingsFromJson,
          toJson: iqamahSettingsToJson)
      required Map<Prayer, int> iqamahSettings,
      @JsonKey(
          name: 'coordinates',
          fromJson: coordinatesFromJson,
          toJson: coordinatesToJson)
      required Coordinates coordinates,
      @JsonKey(
          name: 'location', fromJson: locationFromJson, toJson: locationToJson)
      required Location location}) = _PrayerSettings;

  factory PrayerSettings.defaultSettings() {
    return PrayerSettings(
      method: CalculationMethod.ummAlQura,
      is24Hours: false,
      iqamahSettings: {Prayer.dhuhr: 20},
      coordinates: Coordinates(21.556126, 39.216189),
      location: tz.getLocation('Asia/Riyadh'),
    );
  }

  factory PrayerSettings.fromJson(Map<String, dynamic> json) =>
      _$PrayerSettingsFromJson(json);
}
