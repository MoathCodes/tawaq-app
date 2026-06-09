/// Heuristics for detecting truncated or incomplete tafsir rows in bundled DBs.
library;

import 'package:tawaq/feature/quran/domain/models/tafsir_truncation_report.dart';

/// Detects likely database truncation in raw tafsir markup.
abstract final class TafsirTextIntegrity {
  static final _htmlTagPattern = RegExp('<[^>]+>');
  static final _divOpenPattern = RegExp(r'<div[\s>]', caseSensitive: false);
  static final _divClosePattern = RegExp('</div>', caseSensitive: false);
  static final _arabicLetterPattern = RegExp(
    r'[\u0621-\u064A\u0660-\u0669\u0671-\u06D5\u06EE\u06EF\u0750-\u077F]',
  );
  static final _sentenceEnderPattern = RegExp(
    r'[.!?;:\u060C\u061B\u06D4\u2026\u00BB"\x27\)\]\uFD3E0-9\s]$',
  );
  static final _sentenceBreakPattern = RegExp(
    r'[.!?;:\u060C\u061B\u06D4\u2026\n]',
  );

  /// Minimum stripped length before mid-word ending is considered.
  static const int minLengthForMidWordCheck = 10;

  /// Minimum stripped length before abrupt-tail check runs.
  static const int minLengthForAbruptTailCheck = 400;

  /// Maximum tail length (after last sentence break) for abrupt tail.
  static const int abruptTailMaxLength = 30;

  /// Maximum last-token Arabic letter count for mid-word ending.
  static const int midWordMaxLastTokenLength = 2;

  /// Analyzes [rawText] from the database before parser repair/normalization.
  ///
  /// When [strippedHtml] is supplied, HTML tag removal is skipped to avoid a
  /// second full-text strip pass.
  static TafsirTruncationReport analyze(
    String rawText, {
    String? strippedHtml,
  }) {
    if (rawText.trim().isEmpty) {
      return const TafsirTruncationReport(
        isLikelyTruncated: false,
        reasons: [],
      );
    }

    final reasons = <TafsirTruncationReason>[];

    if (_hasOrphanClosingDiv(rawText)) {
      reasons.add(TafsirTruncationReason.orphanClosingDiv);
    }

    final stripped = (strippedHtml ?? _stripHtml(rawText)).trimRight();
    if (stripped.isEmpty) {
      return TafsirTruncationReport(
        isLikelyTruncated: reasons.isNotEmpty,
        reasons: reasons,
      );
    }

    if (_hasUnbalancedDelimiters(stripped)) {
      reasons.add(TafsirTruncationReason.unbalancedDelimiters);
    }

    if (_endsMidWord(stripped)) {
      reasons.add(TafsirTruncationReason.midWordEnding);
    }

    if (_hasAbruptShortTail(stripped)) {
      reasons.add(TafsirTruncationReason.abruptTail);
    }

    return TafsirTruncationReport(
      isLikelyTruncated: reasons.isNotEmpty,
      reasons: reasons,
    );
  }

  static String _stripHtml(String raw) {
    return raw.replaceAll(_htmlTagPattern, '');
  }

  static bool _hasOrphanClosingDiv(String raw) {
    if (!_divClosePattern.hasMatch(raw)) return false;

    final openCount = _divOpenPattern.allMatches(raw).length;
    final closeCount = _divClosePattern.allMatches(raw).length;
    return closeCount > openCount;
  }

  static bool _hasUnbalancedDelimiters(String text) {
    if (!_isBalanced(text, '(', ')')) return true;
    if (!_isBalanced(text, '[', ']')) return true;
    if (!_isBalanced(text, '«', '»')) return true;
    if (_quoteCount(text, '"').isOdd) return true;
    return false;
  }

  static bool _isBalanced(String text, String open, String close) {
    var depth = 0;
    for (var i = 0; i < text.length; i++) {
      final char = text[i];
      if (char == open) {
        depth++;
      } else if (char == close) {
        depth--;
        if (depth < 0) return false;
      }
    }
    return depth == 0;
  }

  static int _quoteCount(String text, String quote) {
    return quote.allMatches(text).length;
  }

  static bool _endsMidWord(String text) {
    final trimmed = _trimTrailingEllipsis(text);
    if (trimmed.isEmpty) return false;

    final lastChar = trimmed[trimmed.length - 1];
    if (_sentenceEnderPattern.hasMatch(lastChar)) return false;

    if (lastChar == '(' || lastChar == '«' || lastChar == '[') {
      return true;
    }

    if (!_arabicLetterPattern.hasMatch(lastChar)) return false;

    final lastToken = trimmed.split(RegExp(r'\s+')).last;
    final arabicLettersInToken = lastToken
        .split('')
        .where(_arabicLetterPattern.hasMatch)
        .length;

    if (arabicLettersInToken == 0 ||
        arabicLettersInToken > midWordMaxLastTokenLength) {
      return false;
    }

    if (text.length < minLengthForMidWordCheck) {
      return arabicLettersInToken == 1;
    }

    return true;
  }

  static bool _hasAbruptShortTail(String text) {
    if (text.length < minLengthForAbruptTailCheck) return false;

    final lastBreak = text.lastIndexOf(_sentenceBreakPattern);
    if (lastBreak < 0) return false;

    final tail = text.substring(lastBreak + 1).trim();
    if (tail.isEmpty || tail.length > abruptTailMaxLength) return false;

    final trimmed = _trimTrailingEllipsis(tail);
    if (trimmed.isEmpty) return true;

    final lastChar = trimmed[trimmed.length - 1];
    return !_sentenceEnderPattern.hasMatch(lastChar);
  }

  static String _trimTrailingEllipsis(String text) {
    var trimmed = text.trimRight();
    while (trimmed.isNotEmpty) {
      if (trimmed.endsWith('...')) {
        trimmed = trimmed.substring(0, trimmed.length - 3).trimRight();
        continue;
      }
      if (trimmed.endsWith('…')) {
        trimmed = trimmed.substring(0, trimmed.length - 1).trimRight();
        continue;
      }
      break;
    }
    return trimmed;
  }
}
