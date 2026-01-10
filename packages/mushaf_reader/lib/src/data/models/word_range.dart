import 'package:freezed_annotation/freezed_annotation.dart';

part 'word_range.freezed.dart';

/// Represents a single word's character range inside an Ayah's glyph string.
///
/// The [start] and [end] indices are offsets into the Ayah's `text` (QCF4 glyph
/// string). This makes it cheap to slice the tapped word and build per-word
/// [TextSpan]s without re-tokenizing.
@freezed
abstract class WordRange with _$WordRange {
  const factory WordRange({
    /// Zero-based word index within the Ayah.
    required int index,

    /// Start offset (inclusive) into the Ayah glyph string.
    required int start,

    /// End offset (exclusive) into the Ayah glyph string.
    required int end,
  }) = _WordRange;
}
