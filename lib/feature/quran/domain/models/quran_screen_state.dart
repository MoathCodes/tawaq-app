import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/feature/quran/domain/models/quran_content_source_converter.dart';
import 'package:tawaq/feature/quran/domain/models/quran_layouts.dart';
import 'package:tawaq/feature/quran/domain/models/quran_text_scale.dart';
import 'package:tawaq/feature/quran/domain/models/quran_text_scale_converter.dart';
import 'package:tawaq/feature/quran/domain/models/tafsir_source.dart';
import 'package:tawaq/feature/quran/domain/models/translation_source.dart';

part 'quran_screen_state.freezed.dart';
part 'quran_screen_state.g.dart';

/// State model for the Quran screen.
///
/// Contains all reactive state for the Quran reader including page info,
/// font size, layout mode, and currently selected ayah.
@freezed
abstract class QuranScreenState with _$QuranScreenState {
  /// Creates a [QuranScreenState] instance.
  const factory QuranScreenState({
    /// Current page info from MushafReader.
    required MushafPageInfo pageInfo,

    /// Mushaf ayah text size (independent of app UI scale).
    @QuranTextScaleConverter()
    @Default(QuranTextScale.medium)
    QuranTextScale quranTextScale,

    /// Current reading layout mode.
    @Default(QuranReadingLayout.studyMode) QuranReadingLayout layout,

    /// Currently selected ayah for highlighting and search sync.
    /// Not persisted to JSON (ephemeral state).
    @JsonKey(includeFromJson: false, includeToJson: false) Ayah? selectedAyah,

    /// Whether the tafsir accordion section is expanded.
    @Default(true) bool tafsirEnabled,

    /// Whether the translation accordion section is expanded.
    @Default(true) bool translationEnabled,

    /// Selected translation source for the study panel.
    @TranslationIdConverter()
    @Default(TranslationId.saheehInternational)
    TranslationId selectedTranslation,

    /// Selected tafsir source for the study panel.
    @TafsirIdConverter()
    @Default(TafsirId.tafseerMouaser)
    TafsirId selectedTafsir,

    /// Width of the study side panel in logical pixels.
    @Default(350) double sidePanelWidth,
  }) = _QuranScreenState;
  const QuranScreenState._();

  /// Creates a [QuranScreenState] instance from a JSON map.
  factory QuranScreenState.fromJson(Map<String, dynamic> json) =>
      _$QuranScreenStateFromJson(_migrateQuranScreenJson(json));

  /// Creates a default initial state.
  factory QuranScreenState.initial() => QuranScreenState(
    pageInfo: MushafPageInfo(
      pageNumber: 1,
      juzNumber: 1,
      surahNumbers: const [1],
      surahNames: const [''],
      firstAyahId: 1,
      lastAyahId: 7,
      ayahIds: const [1, 2, 3, 4, 5, 6, 7],
    ),
  );
}

Map<String, dynamic> _migrateQuranScreenJson(Map<String, dynamic> json) {
  final migrated = Map<String, dynamic>.from(json);
  if (!migrated.containsKey('quranTextScale') &&
      migrated.containsKey('fontSize')) {
    migrated['quranTextScale'] = migrated.remove('fontSize');
  }
  return migrated;
}
