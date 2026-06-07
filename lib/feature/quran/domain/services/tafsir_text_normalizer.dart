/// Applies Arabic typography fixes to parsed tafsir segment text.
///
/// Source databases often insert spaces before punctuation and inside brackets.
/// This normalizes display text without altering semantic markup structure.
abstract final class TafsirTextNormalizer {
  static const ayahOpen = '﴿';
  static const ayahClose = '﴾';

  /// Wraps ayah segment text in Uthmani brackets, like Hisn commentary.
  ///
  /// Strips legacy `{…}`, `(…)`, or `«…»` wrappers from compact DB markup.
  static String formatAyahDisplay(String text) {
    if (text.isEmpty) return text;

    final inner = _stripLegacyAyahWrappers(text);
    if (inner.isEmpty) return text;

    return '$ayahOpen$inner$ayahClose';
  }

  static String _stripLegacyAyahWrappers(String text) {
    var result = text.trim();

    if (result.startsWith(ayahOpen) && result.endsWith(ayahClose)) {
      result = result.substring(ayahOpen.length, result.length - ayahClose.length);
    }

    for (final (:open, :close) in [
      (open: '{', close: '}'),
      (open: '(', close: ')'),
      (open: '«', close: '»'),
    ]) {
      if (result.startsWith(open) && result.endsWith(close)) {
        result = result.substring(open.length, result.length - close.length);
      }
    }

    return result.trim();
  }
}
