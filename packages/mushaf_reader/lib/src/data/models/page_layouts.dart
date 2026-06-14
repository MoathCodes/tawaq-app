import 'package:freezed_annotation/freezed_annotation.dart';

part 'page_layouts.freezed.dart';

/// Represents the layout information for an Ayah on a specific page.
///
/// This model maps database layout records to the rendering system,
/// storing the line boundaries for each Ayah's appearance on a page.
///
/// Used internally by the repository to construct [QuranPage]
/// with proper line and Ayah fragment information.
///
/// ## Database Mapping
///
/// This corresponds to records in the `PageLayouts` table which tracks:
/// - Which page contains which Ayahs
/// - The line range for each Ayah's text on that page
///
/// See also:
/// - [QuranPage], which is built from these layouts
@freezed
abstract class PageLayouts with _$PageLayouts {
  /// Creates a [PageLayouts] record.
  factory PageLayouts({
    /// The Mushaf page number (1-604).
    required int page,

    /// The global Ayah ID (1-6236).
    required int ayahId,

    /// The first mushaf line (1-based) on which this Ayah appears on [page].
    ///
    /// These are physical line numbers on the printed page, not character
    /// indices into concatenated glyph text.
    required int lineStart,

    /// The last mushaf line (1-based) on which this Ayah appears on [page].
    required int lineEnd,
  }) = _PageLayouts;
}
