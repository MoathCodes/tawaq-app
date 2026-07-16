/// Applies Arabic typography fixes to parsed tafsir segment text.
///
/// Source databases often insert spaces before punctuation and inside brackets.
/// This normalizes display text without altering semantic markup structure.
abstract final class TafsirTextNormalizer {
  static const ayahOpen = '﴿';
  static const ayahClose = '﴾';

  /// Mouaser DB ayah spans use font-specific PUA glyphs (U+FD61/U+FD60) from
  /// `hafs_tafseerMouaser_v3_fonts`, not standard Uthmani brackets.
  static const mouaserAyahOpen = '\uFD61';
  static const mouaserAyahClose = '\uFD60';

  /// Wraps ayah segment text in Uthmani brackets, like Hisn commentary.
  ///
  /// Strips legacy `{…}`, `(…)`, `«…»`, Mouaser PUA, or existing `﴿…﴾`
  /// wrappers from source markup before applying display brackets.
  static String formatAyahDisplay(String text) {
    if (text.isEmpty) return text;

    final inner = _stripLegacyAyahWrappers(text);
    if (inner.isEmpty) return text;

    return '$ayahOpen$inner$ayahClose';
  }

  static String _stripLegacyAyahWrappers(String text) {
    var result = text.trim();

    for (final (:open, :close) in [
      (open: ayahOpen, close: ayahClose),
      (open: mouaserAyahOpen, close: mouaserAyahClose),
      (open: '{', close: '}'),
      (open: '(', close: ')'),
      (open: '«', close: '»'),
    ]) {
      if (result.startsWith(open) && result.endsWith(close)) {
        result = result.substring(open.length, result.length - close.length);
        result = result.trim();
      }
    }

    return result;
  }
}
