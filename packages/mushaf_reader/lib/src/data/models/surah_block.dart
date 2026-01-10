import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mushaf_reader/src/data/models/ayah_fragment.dart';

part 'surah_block.freezed.dart';

/// Represents a Surah's content block within a Mushaf page.
///
/// A Mushaf page may contain one or more Surahs. Each [SurahBlock] represents
/// the portion of a Surah that appears on a specific page, including:
/// - The Surah header glyph for display
/// - Whether to show the Basmalah
/// - All Ayah fragments from this Surah on this page
///
/// ## Basmalah Logic
///
/// The [hasBasmalah] flag indicates whether to display "Bismillah ir-Rahman
/// ir-Raheem" before the Surah's content. This is `true` when:
/// - The Surah starts on this page (first Ayah is verse 1)
/// - The Surah is not At-Tawbah (Surah 9), which has no Basmalah
///
/// Note: Al-Fatiha (Surah 1) has the Basmalah as its first verse, so
/// the widget should handle this appropriately.
///
/// ## Example
///
/// ```dart
/// final page = await controller.getPage(1);
/// for (final block in page.surahs) {
///   if (block.hasBasmalah) {
///     print('Show Surah header and Basmalah');
///   }
///   print('Surah ${block.surahNumber}: ${block.ayahs.length} ayahs');
/// }
/// ```
///
/// See also:
/// - [QuranPageModel], which contains the list of Surah blocks
/// - [SurahHeaderWidget], which displays the Surah header
/// - [BasmalahWidget], which displays the Basmalah
@freezed
abstract class SurahBlock with _$SurahBlock {
  /// Creates a [SurahBlock] with Surah metadata and Ayah fragments.
  const factory SurahBlock({
    /// The Surah number (1-114).
    required int surahNumber,

    /// The QCF4-encoded glyph for the Surah name/header.
    ///
    /// This should be rendered using the Basmalah font family (QCF4_BSML).
    required String glyph,

    /// The start index (inclusive) in the page's glyph text.
    ///
    /// Marks where this Surah's content begins on the page.
    required int start,

    /// The end index (exclusive) in the page's glyph text.
    ///
    /// Marks where this Surah's content ends on the page.
    required int end,

    /// Whether this block starts with the first Ayah of the Surah.
    ///
    /// `true` if the first Ayah in this block is verse 1 of the Surah.
    /// Used to determine whether to show the Surah header and Basmalah.
    required bool hasBasmalah,

    /// The Ayah fragments from this Surah that appear on this page.
    ///
    /// Fragments are ordered by their position in the Surah.
    required List<AyahFragment> ayahs,
  }) = _SurahBlock;
}
