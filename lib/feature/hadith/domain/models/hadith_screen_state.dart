import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tawaq/core/layout/side_panel_ui_state.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_filters.dart';

part 'hadith_screen_state.freezed.dart';
part 'hadith_screen_state.g.dart';

/// The available tabs in the hadith side panel.
enum HadithPanelTab {
  /// Details tab.
  details,

  /// Filters tab.
  filters,
}

/// Persisted UI state for the hadith screen.
@freezed
abstract class HadithScreenState with _$HadithScreenState {
  /// Creates the hadith screen state.
  const factory HadithScreenState({
    @Default(HadithPanelTab.details) HadithPanelTab activeTab,
    @Default(HadithFilters()) HadithFilters filters,
    @Default(SidePanelDefaults.hadithRatio) double sidePanelRatio,
    @Default(SidePanelDefaults.collapsed) bool sidePanelCollapsed,
  }) = _HadithScreenState;

  /// Deserializes the hadith screen state from JSON.
  factory HadithScreenState.fromJson(Map<String, dynamic> json) =>
      _$HadithScreenStateFromJson(
        _migrateHadithScreenJson(Map<String, dynamic>.from(json)),
      );

  /// Returns the default initial screen state.
  factory HadithScreenState.initial() => const HadithScreenState();
}

Map<String, dynamic> _migrateHadithScreenJson(Map<String, dynamic> json) {
  migrateSidePanelJson(json);
  return json;
}
