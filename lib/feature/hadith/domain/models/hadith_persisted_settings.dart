import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tawaq/core/layout/side_panel_ui_state.dart';

part 'hadith_persisted_settings.freezed.dart';
part 'hadith_persisted_settings.g.dart';

/// The available tabs in the hadith side panel.
enum HadithPanelTab {
  /// Details tab.
  details,

  /// Filters tab.
  filters,
}

/// Persisted UI settings for the hadith screen (tab and side panel only).
@freezed
abstract class HadithPersistedSettings with _$HadithPersistedSettings {
  /// Creates the hadith persisted settings.
  const factory({
    @Default(HadithPanelTab.details) HadithPanelTab activeTab,
    @Default(SidePanelDefaults.hadithRatio) double sidePanelRatio,
    @Default(SidePanelDefaults.collapsed) bool sidePanelCollapsed,
  }) = _HadithPersistedSettings;

  /// Deserializes from JSON.
  factory fromJson(Map<String, dynamic> json) =>
      _$HadithPersistedSettingsFromJson(json);

  /// Returns the default initial settings.
  factory initial() => const HadithPersistedSettings();

  const new _();
}
