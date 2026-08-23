import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tawaq/core/layout/side_panel_ui_state.dart';
import 'package:tawaq/feature/quran/domain/models/quran_content_source_converter.dart';
import 'package:tawaq/feature/quran/domain/models/tafsir_source.dart';
import 'package:tawaq/feature/quran/domain/models/translation_source.dart';
import 'package:tawaq/l10n/app_localizations.dart';

part 'quran_ui_models.freezed.dart';
part 'quran_ui_models.g.dart';

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
const double kMushafZoomDefault = 1;

/// Alias for [kMushafZoomDefault]: the fit-page (no-scroll) mark on the slider.
const double kMushafZoomFitPage = kMushafZoomDefault;

/// Maps a mushaf zoom boost onto a display percentage (1.0 → 100%).
int mushafZoomPercent(double zoom) => (zoom * 100).round();

/// Reads the current page checkpoint, including the legacy full `pageInfo`.
Object? quranLastPageRead(Map<dynamic, dynamic> json, String key) {
  final current = json[key];
  if (current is num) return current.toInt();
  final legacy = json['pageInfo'];
  if (legacy is Map) {
    final page = legacy['pageNumber'];
    if (page is num) return page.toInt();
  }
  return 1;
}

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
      _ =>
        double.tryParse(json)?.clamp(kMushafZoomMin, kMushafZoomMax) ??
            kMushafZoomDefault,
    };
  }
  return kMushafZoomDefault;
}

/// Export width for verse share images.
const double kAyahShareCardWidth = 480;

/// Presentation helpers for [QuranReadingLayout].
extension QuranReadingLayoutUi on QuranReadingLayout {
  /// Returns the icon associated with this layout.
  IconData get icon => switch (this) {
    QuranReadingLayout.doublePage => FLucideIcons.columns2,
    QuranReadingLayout.studyMode => FLucideIcons.panelRight,
  };

  /// Returns a localized name for this layout.
  String getLocaleName(AppLocalizations locale) => switch (this) {
    QuranReadingLayout.doublePage => locale.quranLayoutDoublePage,
    QuranReadingLayout.studyMode => locale.quranLayoutStudyMode,
  };
}

/// Persisted state for the Quran reading screen.
@freezed
abstract class QuranScreenState with _$QuranScreenState {
  /// Creates a [QuranScreenState].
  const factory({
    /// Restore-only checkpoint. The route owns the live page.
    @JsonKey(readValue: quranLastPageRead) @Default(1) int lastPageNumber,
    @JsonKey(name: 'quranTextScale', fromJson: mushafZoomFromJson)
    @Default(kMushafZoomDefault)
    double mushafZoom,
    @Default(QuranReadingLayout.studyMode) QuranReadingLayout layout,
    @Default(true) bool tafsirEnabled,
    @Default(true) bool translationEnabled,
    @TranslationIdConverter()
    @Default(TranslationId.saheehInternational)
    TranslationId selectedTranslation,
    @TafsirIdConverter()
    @Default(TafsirId.tafseerMouaser)
    TafsirId selectedTafsir,
    @Default(SidePanelDefaults.quranRatio) double sidePanelRatio,
    @Default(SidePanelDefaults.collapsed) bool sidePanelCollapsed,
    @Default(StudyPanelTab.currentAyah) StudyPanelTab activeStudyTab,
  }) = _QuranScreenState;

  const new _();

  /// Creates state from persisted JSON.
  factory fromJson(Map<String, dynamic> json) =>
      _$QuranScreenStateFromJson(json);

  /// Creates the initial reading state.
  factory initial() => const QuranScreenState();
}
