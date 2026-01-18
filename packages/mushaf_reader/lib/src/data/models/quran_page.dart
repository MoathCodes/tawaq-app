import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mushaf_reader/src/data/models/page_line.dart';
import 'package:mushaf_reader/src/data/models/surah_block.dart';

part 'quran_page.freezed.dart';

/// Represents a complete Quran page with all its content and layout
/// information.
///
/// This model contains everything needed to render a Mushaf page, including:
/// - The concatenated glyph text for all Ayahs on the page
/// - Line-by-line layout information for text positioning
/// - Surah blocks with their headers and Ayah fragments
/// - Metadata like page number and Juz number
///
/// The glyph text uses QCF4 encoding which requires the corresponding
/// page-specific font (e.g., QCF4_001 for page 1) to render correctly.
///
/// ## Layout Structure
///
/// A page consists of:
/// 1. **Lines**: Horizontal divisions of text with start/end character indices
/// 2. **Surah Blocks**: Groups of Ayahs belonging to the same Surah, which may
///    include a header and Basmalah if the Surah starts on this page
///
/// ## Example
///
/// ```dart
/// final page = await MushafController.instance.getPage(1);
///
/// print('Page ${page.pageNumber} has ${page.surahs.length} surah(s)');
/// print('Juz: ${page.juzNumber}');
///
/// for (final surah in page.surahs) {
///   print('Surah ${surah.surahNumber}: ${surah.ayahs.length} ayahs');
/// }
/// ```
///
/// See also:
/// - [PageLine], for line layout details
/// - [SurahBlock], for Surah-level organization
/// - [MushafPage], the widget that renders this model
@freezed
abstract class QuranPage with _$QuranPage {
  /// Creates a [QuranPage] with all page content and layout data.
  factory QuranPage({
    /// The page number in the Mushaf (1-604).
    ///
    /// Based on the Madinah Mushaf standard which has 604 pages total.
    required int pageNumber,

    /// The complete QCF4-encoded glyph text for all content on this page.
    ///
    /// This is a concatenation of all Ayah texts on the page, in order.
    /// Use this with [lines] and [surahs] to extract specific portions.
    ///
    /// Render this text using the font returned by
    /// `MushafFonts.forPage(pageNumber)`.
    required String glyphText,

    /// Line-by-line layout information for the page.
    ///
    /// Each [PageLine] contains:
    /// - Character start/end indices into [glyphText]
    /// - Ayah fragments that appear on that line
    ///
    /// Lines are ordered from top to bottom of the page.
    required List<PageLine> lines,

    /// Surah blocks present on this page.
    ///
    /// A page may contain one or more Surahs. Each [SurahBlock] contains:
    /// - Surah identification and header glyph
    /// - Whether to show the Basmalah
    /// - All Ayah fragments for that Surah on this page
    ///
    /// Surahs are ordered by their appearance on the page.
    required List<SurahBlock> surahs,

    /// The Juz (part) number for this page (1-30).
    ///
    /// Determined by the first Ayah on the page. Note that Juz boundaries
    /// may occur mid-page, but this represents the primary Juz.
    required int juzNumber,
  }) = _QuranPage;
}
