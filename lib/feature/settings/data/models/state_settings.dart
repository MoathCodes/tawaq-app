import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hasanat/feature/quran/domain/models/quran_layouts.dart';

part 'state_settings.freezed.dart';
part 'state_settings.g.dart';

/// Model representing the application settings.
@freezed
abstract class StateSettings with _$StateSettings {
  /// Creates an [StateSettings] instance.
  factory StateSettings({
    required bool sidebarCollapsed,
    required int lastQuranPage,
    required QuranReadingLayout lastLayout,
  }) = _StateSettings;

  /// Creates a [StateSettings] instance from a JSON map.
  factory StateSettings.fromJson(Map<String, dynamic> json) =>
      _$StateSettingsFromJson(json);
}
