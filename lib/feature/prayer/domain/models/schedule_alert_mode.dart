import 'package:adhan_dart/adhan_dart.dart';

/// How a scheduled prayer event alerts the user.
enum ScheduleAlertMode {
  /// No alert.
  off,

  /// Full audio playback (adhan / iqamah when supported).
  sound,

  /// In-app and/or OS notification without sound.
  notifyOnly,
}

/// Parses a persisted alert mode (legacy int or string).
ScheduleAlertMode scheduleAlertModeFromJson(Object? value) {
  if (value is int) {
    return value == 0 ? ScheduleAlertMode.off : ScheduleAlertMode.sound;
  }
  if (value is String) {
    return switch (value) {
      'sound' => ScheduleAlertMode.sound,
      'notify_only' => ScheduleAlertMode.notifyOnly,
      _ => ScheduleAlertMode.off,
    };
  }
  return ScheduleAlertMode.off;
}

/// Serializes [mode] for persistence.
String scheduleAlertModeToJson(ScheduleAlertMode mode) => switch (mode) {
  ScheduleAlertMode.off => 'off',
  ScheduleAlertMode.sound => 'sound',
  ScheduleAlertMode.notifyOnly => 'notify_only',
};

/// Parses a prayer → mode map from JSON.
Map<Prayer, ScheduleAlertMode> prayerAlertModesFromJson(
  Map<String, dynamic> json,
) {
  return json.map(
    (key, value) => MapEntry(
      Prayer.values.firstWhere((e) => e.name == key),
      scheduleAlertModeFromJson(value),
    ),
  );
}

/// Converts a prayer → mode map to JSON.
Map<String, String> prayerAlertModesToJson(
  Map<Prayer, ScheduleAlertMode> modes,
) {
  return modes.map(
    (key, value) => MapEntry(key.name, scheduleAlertModeToJson(value)),
  );
}
