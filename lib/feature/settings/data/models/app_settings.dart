import 'dart:ui';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hasanat/core/theme/theme.dart';
import 'package:hasanat/feature/settings/data/models/prayer_settings_model.dart';

part 'app_settings.freezed.dart';

@freezed
abstract class AppSettings with _$AppSettings {
  factory AppSettings({
    required ThemeSettings themeSettings,
    required Locale locale,
    required PrayerSettings prayerSettings,
  }) = _AppSettings;
}
