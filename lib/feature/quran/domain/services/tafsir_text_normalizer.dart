/// Applies Arabic typography fixes to parsed tafsir segment text.
///
/// Source databases often insert spaces before punctuation and inside brackets.
/// This normalizes display text without altering semantic markup structure.
abstract final class TafsirTextNormalizer {
  static const ayahOpen = '﴿';
  static const ayahClose = '﴾';

  static final _spaceBeforePunctuation = RegExp(r'\s+([،؛.؟!])');
  static final _redundantEndPunctuation = RegExp(r'([؟!])\s*\.');
  static final _spaceBeforeColon = RegExp(r'\s+:');
  static final _spaceAfterColon = RegExp(r':[ \t]+');

  static final _openParenSpace = RegExp(r'\(\s+');
  static final _closeParenSpace = RegExp(r'\s+\)');
  static final _openBracketSpace = RegExp(r'\[\s+');
  static final _closeBracketSpace = RegExp(r'\s+\]');
  static final _openBraceSpace = RegExp(r'\{\s+');
  static final _closeBraceSpace = RegExp(r'\s+\}');

  static final _strayPunctuationAfterOpenBracket = RegExp(r'\[\s*[.,:،]\s*');
  static final _paddedStraightQuotes = RegExp(r'"\s*(.*?)\s*"', dotAll: true);
  static final _gapBeforeReferenceBracket = RegExp(r'(?:\)|﴾)\s+\[');
  static final _gapBeforePeriodAfterBracket = RegExp(r'\]\s+\.');
  static final _strayQuoteBeforeCloseBracket = RegExp(r'"\s*(?=\])');
  static final _latinComma = RegExp(',');
  static final _orphanLeadingPunctuation = RegExp('^[ ،.]+');
  static final _orphanLineStartPunctuation = RegExp(r'(?<=\n)[.،]+');
  static final _punctuationOnly = RegExp(r'^[ ،.]+$');
  static final _gluedSahihMuslim = RegExp('صحيح(?=مسلم)');
  static final _spacedPrefixBeforeQawl = RegExp(
    r'([لوبفك])\s+(?=ق(?:ول(?:ه|ها|هم)?(?:\s+تعالى)?|ال\s+الله\s+تعالى):)',
  );

  static final _honorificReplacements = <RegExp, String>{
    RegExp(r'صلى\s+الله\s+عليه\s+و(?:آ|ا)له\s+وسلم'): 'ﷺ',
    RegExp(r'صلى\s+الله\s+عليه\s+وسلم'): 'ﷺ',
    RegExp(r'رضي\s+الله\s+عنهما'): 'رضي الله عنهما',
    RegExp(r'رضي\s+الله\s+عنهم'): 'رضي الله عنهم',
    RegExp(r'رضي\s+الله\s+عنه'): 'رضي الله عنه',
    RegExp(r'رحمه\s+الله'): 'رحمه الله',
    RegExp(r'عليه\s+السلام'): 'عليه السلام',
  };

  /// Normalizes [text] for Arabic typographic conventions.
  static String normalize(String text) {
    if (text.isEmpty) return text;

    var result = text;

    for (final entry in _honorificReplacements.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }

    result = result
        .replaceAll(_gluedSahihMuslim, 'صحيح ')
        .replaceAll(_strayQuoteBeforeCloseBracket, '')
        .replaceAll(_latinComma, '،')
        .replaceAllMapped(
          _spacedPrefixBeforeQawl,
          (match) => match.group(1)!,
        );

    result = _stripOrphanLeadingPunctuation(result);

    result = result.replaceAll(_strayPunctuationAfterOpenBracket, '[');

    result = result.replaceAllMapped(
      _paddedStraightQuotes,
      (match) => '«${match.group(1)!}»',
    );

    result = result
        .replaceAll(_openParenSpace, '(')
        .replaceAll(_closeParenSpace, ')')
        .replaceAll(_openBracketSpace, '[')
        .replaceAll(_closeBracketSpace, ']')
        .replaceAll(_openBraceSpace, '{')
        .replaceAll(_closeBraceSpace, '}')
        .replaceAll(_gapBeforeReferenceBracket, ')[')
        .replaceAll(_gapBeforePeriodAfterBracket, '].')
        .replaceAll(_spaceBeforeColon, ':')
        .replaceAllMapped(_spaceAfterColon, (_) => ': ')
        .replaceAllMapped(
          _spaceBeforePunctuation,
          (match) => match.group(1)!,
        )
        .replaceAllMapped(
          _redundantEndPunctuation,
          (match) => match.group(1)!,
        );

    return _trimTrailingColonSpace(result);
  }

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

  static String _stripOrphanLeadingPunctuation(String text) {
    if (_punctuationOnly.hasMatch(text)) return '';

    var result = text.replaceFirst(_orphanLeadingPunctuation, '');
    result = result.replaceAll(_orphanLineStartPunctuation, '\n');
    if (_punctuationOnly.hasMatch(result)) return '';
    return result;
  }

  /// Avoid a trailing colon-space at end of segment text.
  static String _trimTrailingColonSpace(String text) {
    if (text.endsWith(': ')) {
      return text.substring(0, text.length - 1);
    }
    return text;
  }
}
