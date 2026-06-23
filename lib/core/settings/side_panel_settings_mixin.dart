import 'package:tawaq/core/layout/side_panel_ui_state.dart';

/// Mixin for persisted screen settings notifiers with a resizable side panel.
mixin SidePanelSettingsMixin<S> {
  /// Applies [transform] and logs [logField] when the state actually changes.
  void updateSidePanelSetting(S Function(S) transform, String logField);

  /// Sets the side panel width ratio (0..1).
  void setSidePanelRatio(double ratio) => updateSidePanelSetting(
    (s) => copySidePanelFields(s, sidePanelRatio: ratio),
    'Side panel ratio',
  );

  /// Sets whether the side panel is collapsed.
  void setSidePanelCollapsed({required bool collapsed}) =>
      updateSidePanelSetting(
        (s) => copySidePanelFields(s, sidePanelCollapsed: collapsed),
        'Side panel collapsed',
      );
}
