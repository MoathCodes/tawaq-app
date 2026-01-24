import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hasanat/feature/quran/domain/models/font_sizes.dart';
import 'package:hasanat/feature/quran/domain/models/quran_layouts.dart';
import 'package:mushaf_reader/mushaf_reader.dart';

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

    /// Currently selected font size for ayah text.
    @Default(FontSizes.medium) FontSizes fontSize,

    /// Current reading layout mode.
    @Default(QuranReadingLayout.studyMode) QuranReadingLayout layout,

    /// Currently selected ayah for highlighting and search sync.
    /// Not persisted to JSON (ephemeral state).
    @JsonKey(includeFromJson: false, includeToJson: false) Ayah? selectedAyah,

    /// The state of the tafsir according.
    @Default(true) bool tafsirEnabled,

    /// The state of the translation according.
    @Default(true) bool translationEnabled,
  }) = _QuranScreenState;
  const QuranScreenState._();

  /// Creates a [QuranScreenState] instance from a JSON map.
  factory QuranScreenState.fromJson(Map<String, dynamic> json) =>
      _$QuranScreenStateFromJson(json);

  /// Creates a default initial state.
  factory QuranScreenState.initial() => QuranScreenState(
    pageInfo: MushafPageInfo(
      pageNumber: 1,
      juzNumber: 1,
      surahNumbers: const [1],
      surahNames: const ['الفاتحة'],
      firstAyahId: 1,
      lastAyahId: 7,
      ayahIds: const [1, 2, 3, 4, 5, 6, 7],
    ),
  );
}
