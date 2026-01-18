import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mushaf_reader/src/data/models/ayah_fragment.dart';

part 'page_line.freezed.dart';

/// Represents a single line of text on a Mushaf page.
///
/// Each line contains a portion of the page's glyph text and tracks
/// which Ayah fragments appear on that line. This enables:
/// - Line-by-line text rendering
/// - Mapping tap gestures to specific Ayahs
/// - Highlighting specific lines or Ayahs
///
/// ## Text Extraction
///
/// To get the text for a specific line:
/// ```dart
/// final lineText = page.glyphText.substring(line.start, line.end);
/// ```
///
/// ## Example
///
/// ```dart
/// final page = await controller.getPage(1);
/// for (final line in page.lines) {
///   print('Line ${line.index}: ${line.fragments.length} ayah fragments');
/// }
/// ```
///
/// See also:
/// - [QuranPage], which contains the list of lines
/// - [AyahFragment], for individual Ayah portions within a line
@freezed
abstract class PageLine with _$PageLine {
  /// Creates a [PageLine] with the line index, text boundaries, and
  /// fragments.
  factory PageLine({
    /// The zero-based index of this line on the page.
    ///
    /// Lines are ordered from top to bottom.
    required int index,

    /// The start index (inclusive) in the page's glyph text.
    ///
    /// Use with [end] to extract this line's text.
    required int start,

    /// The end index (exclusive) in the page's glyph text.
    ///
    /// Use with [start] to extract this line's text.
    required int end,

    /// The Ayah fragments that appear on this line.
    ///
    /// A line may contain:
    /// - Part of a single Ayah (fragment spans the entire line)
    /// - Multiple complete Ayahs
    /// - Parts of multiple Ayahs (end of one, start of another)
    required List<AyahFragment> fragments,
  }) = _PageLine;
}
