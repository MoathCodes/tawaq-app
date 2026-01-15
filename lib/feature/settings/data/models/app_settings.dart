import 'dart:ui';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hasanat/core/theme/theme.dart';
import 'package:hasanat/feature/settings/data/models/prayer_settings_model.dart';
import 'package:hasanat/feature/settings/data/models/state_settings.dart';

part 'app_settings.freezed.dart';

/// Model representing the application settings.
@freezed
abstract class AppSettings with _$AppSettings {
  /// Creates an [AppSettings] instance.
  factory AppSettings({
    required ThemeSettings themeSettings,
    required Locale locale,
    required PrayerSettings prayerSettings,
    required StateSettings stateSettings,
  }) = _AppSettings;
}
