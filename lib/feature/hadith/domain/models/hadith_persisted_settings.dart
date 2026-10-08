import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tawaq/core/layout/side_panel_ui_state.dart';

part 'hadith_persisted_settings.freezed.dart';
part 'hadith_persisted_settings.g.dart';

/// Durable desk preferences with compatible legacy layout fields.
@freezed
abstract class HadithPersistedSettings with _$HadithPersistedSettings {
  /// Creates the hadith persisted settings.
  const factory({
    @JsonKey(name: 'activeTab') @Default('details') String legacyActiveTab,
    @Default(true) bool filtersVisible,
    @Default(280.0) double filtersWidth,
    @Default(0.5) double readerRatio,
    @Default(false) bool readerCollapsed,
    @Default(SidePanelDefaults.hadithRatio) double sidePanelRatio,
    @Default(SidePanelDefaults.collapsed) bool sidePanelCollapsed,
  }) = _HadithPersistedSettings;

  /// Deserializes from JSON.
  factory fromJson(Map<String, dynamic> json) =>
      _$HadithPersistedSettingsFromJson({
        ...json,
        'readerRatio': json['readerRatio'] ?? json['sidePanelRatio'] ?? 0.5,
        'readerCollapsed':
            json['readerCollapsed'] ?? json['sidePanelCollapsed'] ?? false,
        'filtersVisible': json['filtersVisible'] ?? true,
      });

  /// Returns the default initial settings.
  factory initial() => const HadithPersistedSettings();

  const new _();
}
