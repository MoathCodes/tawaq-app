import 'package:freezed_annotation/freezed_annotation.dart';

part 'mushaf_page_info.freezed.dart';
part 'mushaf_page_info.g.dart';

/// Lightweight summary of a Mushaf page for quick access to current page state.
///
/// This model provides synchronous access to commonly needed page metadata
/// without requiring async database queries. It's computed from [QuranPage]
/// and cached by [MushafReaderController].
///
/// ## Example
///
/// ```dart
/// final controller = MushafReaderController();
/// await controller.init();
///
/// // Sync access to current page info
/// final info = controller.currentPageInfo;
/// print('Page ${info.pageNumber}, Juz ${info.juzNumber}');
/// print('Surahs on page: ${info.surahNumbers.join(", ")}');
/// print('First ayah: ${info.firstAyahId}, Last: ${info.lastAyahId}');
/// ```
///
/// See also:
/// - [QuranPage], the full page model with glyph text
/// - [MushafReaderController], which provides this via [currentPageInfo]
@freezed
abstract class MushafPageInfo with _$MushafPageInfo {
  /// Creates a [MushafPageInfo] with page summary data.
  factory MushafPageInfo({
    /// The page number in the Mushaf (1-604).
    required int pageNumber,

    /// The Juz (part) number for this page (1-30).
    required int juzNumber,

    /// List of Surah numbers present on this page.
    ///
    /// A page may contain multiple Surahs (e.g., the end of one
    /// and the beginning of another). Ordered by appearance.
    required List<int> surahNumbers,

    /// List of Surah names (Arabic glyphs) present on this page.
    ///
    /// Corresponds to [surahNumbers] in the same order.
    required List<String> surahNames,

    /// The global ID of the first Ayah on this page.
    required int firstAyahId,

    /// The global ID of the last Ayah on this page.
    required int lastAyahId,

    /// All Ayah IDs present on this page, in order.
    required List<int> ayahIds,
  }) = _MushafPageInfo;

  const MushafPageInfo._();

  /// Creates a [MushafPageInfo] from a JSON map.
  factory MushafPageInfo.fromJson(Map<String, dynamic> json) =>
      _$MushafPageInfoFromJson(json);

  /// The total number of Ayahs on this page.
  int get ayahCount => ayahIds.length;

  /// Whether this page contains multiple Surahs.
  bool get hasMultipleSurahs => surahNumbers.length > 1;

  /// The primary (first) Surah name on this page.
  String get primarySurahName => surahNames.first;

  /// The primary (first) Surah number on this page.
  int get primarySurahNumber => surahNumbers.isEmpty ? 0 : surahNumbers.first;
}
