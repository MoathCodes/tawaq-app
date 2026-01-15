import 'package:freezed_annotation/freezed_annotation.dart';

part 'ayah_fragment.freezed.dart';

/// Represents a fragment of an Ayah within a page's glyph text.
///
/// Since an Ayah may span multiple lines or a line may contain
/// multiple Ayahs, this model maps portions of the page's concatenated
/// glyph text back to their source Ayahs.
///
/// The [start] and [end] indices are character positions within
/// the [QuranPageModel.glyphText] string, allowing extraction of
/// the specific text segment for this Ayah fragment.
///
/// ## Usage
///
/// ```dart
/// final page = await controller.getPage(1);
/// for (final surah in page.surahs) {
///   for (final fragment in surah.ayahs) {
///     final text = page.glyphText.substring(fragment.start, fragment.end);
///     print('Ayah ${fragment.ayahId}: $text');
///   }
/// }
/// ```
///
/// See also:
/// - [QuranPageModel], which contains the full glyph text
/// - [LineModel], which groups fragments by line
/// - [SurahBlock], which groups fragments by Surah
@freezed
abstract class AyahFragment with _$AyahFragment {
  /// Creates an [AyahFragment] with the Ayah ID and text boundaries.
  factory AyahFragment({
    /// The global unique identifier of the Ayah this fragment belongs to.
    ///
    /// Range: 1-6236 (Al-Fatiha:1 to An-Nas:6)
    required int ayahId,

    /// The start index (inclusive) in the page's glyph text.
    ///
    /// Use with [end] to extract this fragment: `glyphText.substring(start, end)`
    required int start,

    /// The end index (exclusive) in the page's glyph text.
    ///
    /// Use with [start] to extract this fragment: `glyphText.substring(start, end)`
    required int end,
  }) = _AyahFragment;
}
