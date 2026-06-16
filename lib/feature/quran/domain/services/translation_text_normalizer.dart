/// Repairs corrupted HTML decimal entities in bundled translation databases.
///
/// The Bengali database encodes some letters as `&#2479;`-style entities. A bad
/// import turned those into fragments like `?476;` or `ߦ#2468;`.
abstract final class TranslationTextNormalizer {
  /// Corrupted `&#NNNN;` where `&` became any single character.
  static final _hashEntityPattern = RegExp(r'.#(\d{4});');

  /// Corrupted `&#NNNN;` where `&#` became `?`.
  static final _questionEntityPattern = RegExp(r'\?(\d{3,4});');

  /// Known one-off corruption in the Bengali database (`&#2479;` → `?451;`).
  static final _knownEntityOverrides = <String, String>{
    '451': '\u09CD\u09AF', // ্য
  };

  /// Normalizes [text] for display.
  static String normalize(String text) {
    if (!_hashEntityPattern.hasMatch(text) &&
        !_questionEntityPattern.hasMatch(text)) {
      return text;
    }

    final repaired = text.replaceAllMapped(_hashEntityPattern, _decodeEntity);
    return repaired.replaceAllMapped(
      _questionEntityPattern,
      _decodeQuestionEntity,
    );
  }

  static String _decodeEntity(Match match) =>
      String.fromCharCode(int.parse(match.group(1)!));

  static String _decodeQuestionEntity(Match match) {
    final digits = match.group(1)!;
    final override = _knownEntityOverrides[digits];
    if (override != null) return override;

    if (digits.length == 4) {
      return String.fromCharCode(int.parse(digits));
    }

    // `?476;` → U+2476 — the leading `24` of `&#2476;` was dropped.
    return String.fromCharCode(int.parse('2$digits'));
  }
}
