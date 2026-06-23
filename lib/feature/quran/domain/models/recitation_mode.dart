/// What happens when the current recitation selection finishes playing.
enum RecitationMode {
  /// Stop at the end of the selection (single ayah, range, or surah).
  stopAtEnd,

  /// Repeat the current selection.
  repeatSelection,

  /// Continue into the next surah (whole-surah playback).
  continueToNextSurah,
}
