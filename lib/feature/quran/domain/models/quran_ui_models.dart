/// Layout modes for reading Quran.
enum QuranReadingLayout {
  /// Double page view.
  doublePage,

  /// Study mode with translation/tafsir.
  studyMode,
}

/// Tabs inside the study side panel.
enum StudyPanelTab {
  /// Tafsir, translation, and per-ayah reflection editor.
  currentAyah,

  /// Browse all saved reflections.
  reflections,
}

/// Lower bound for [QuranScreenState.mushafZoom] (matches package
/// `MushafScale.minReadingBoost`).
const double kMushafZoomMin = 0.85;

/// Upper bound for [QuranScreenState.mushafZoom] (matches package
/// `MushafScale.maxReadingBoost` / fill-width).
const double kMushafZoomMax = 1.15;

/// Default / fit-page zoom — largest size that never needs vertical scroll.
const double kMushafZoomDefault = 1.0;

/// Alias for [kMushafZoomDefault]: the fit-page (no-scroll) mark on the slider.
const double kMushafZoomFitPage = kMushafZoomDefault;

/// Maps a mushaf zoom boost onto a display percentage (1.0 → 100%).
int mushafZoomPercent(double zoom) => (zoom * 100).round();

/// Preview font size for settings / popover Uthmanic sample text.
double mushafZoomPreviewFontSize(double zoom) => 26 * zoom;

/// Clamps [zoom] into `[kMushafZoomMin, kMushafZoomMax]`.
double clampMushafZoom(double zoom) =>
    zoom.clamp(kMushafZoomMin, kMushafZoomMax);

/// Migrates persisted `quranTextScale` JSON into a continuous zoom double.
///
/// Accepts:
/// - `num` (new continuous zoom)
/// - legacy enum name (`small` / `medium` / `large` / `extraLarge`)
/// - legacy integer index (0–3)
double mushafZoomFromJson(Object? json) {
  if (json == null) return kMushafZoomDefault;
  // Legacy font-size index was a small int 0–3; continuous zoom is a double
  // in [kMushafZoomMin, kMushafZoomMax]. Check the index shape first so
  // `json is num` does not swallow it.
  if (json is int && json >= 0 && json <= 3) {
    return switch (json) {
      0 => 0.9,
      1 => kMushafZoomDefault,
      2 => 1.08,
      3 => 1.12,
      _ => kMushafZoomDefault,
    };
  }
  if (json is num) {
    return clampMushafZoom(json.toDouble());
  }
  if (json is String) {
    return switch (json) {
      'small' => 0.9,
      'medium' => kMushafZoomDefault,
      'large' => 1.08,
      'extraLarge' => 1.12,
      _ => double.tryParse(json)?.clamp(kMushafZoomMin, kMushafZoomMax) ??
          kMushafZoomDefault,
    };
  }
  return kMushafZoomDefault;
}
