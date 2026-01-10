import 'package:freezed_annotation/freezed_annotation.dart';

part 'selected_word.freezed.dart';

/// Represents the currently selected word in the reader.
@freezed
abstract class SelectedWord with _$SelectedWord {
  const factory SelectedWord({
    /// Global Ayah ID (1-6236).
    required int ayahId,

    /// Zero-based word index within the Ayah.
    required int wordIndex,
  }) = _SelectedWord;
}
