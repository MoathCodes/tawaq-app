import 'package:tawaq/core/layout/split_pane_constraints.dart';

/// Default persisted side-panel fields shared by feature screen settings.
abstract final class SidePanelDefaults {
  /// Default side-panel width ratio for the Hadith screen.
  static const double hadithRatio = 0.33;

  /// Default side-panel width ratio for the Quran study layout.
  static const double quranRatio = 0.27;

  /// Default side-panel width ratio for the Muslim Fortress browse sidebar.
  static const double fortressRatio = 0.23;

  /// Default collapsed state for all feature side panels.
  static const bool collapsed = false;
}

/// Shared JSON migration for persisted side-panel width fields.
void migrateSidePanelJson(Map<String, dynamic> json) {
  migrateSidePanelWidthToRatio(json);
}

/// Copies side-panel fields on feature screen settings state objects.
S copySidePanelFields<S>(
  S state, {
  double? sidePanelRatio,
  bool? sidePanelCollapsed,
}) {
  return (state as dynamic).copyWith(
    sidePanelRatio: sidePanelRatio,
    sidePanelCollapsed: sidePanelCollapsed,
  ) as S;
}
