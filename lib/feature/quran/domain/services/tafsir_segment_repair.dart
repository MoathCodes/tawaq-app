import 'package:tawaq/feature/quran/domain/models/tafsir_text_segment.dart';

/// Repairs common markup gaps in parsed tafsir segments before normalization.
abstract final class TafsirSegmentRepair {
  static const _maxAyahQuoteLength = 200;

  static final _surahNameCrossRef = RegExp(
    r'^\(\s*سورة\s+.+\s*[،,]\s*\d+\s*\)$',
  );

  static final _unclosedAyahWithQawl = RegExp(
    r'^(.*?)(?:ك\s*)?قول(?:ه|ها|هم)?(?:\s+تعالى)?:\s*\(\s*(.+?\S)\s+الآية\s*$',
    dotAll: true,
  );

  static final _unclosedAyahPlain = RegExp(
    r'^(.*?)\(\s*(.+?\S)\s+الآية\s*$',
    dotAll: true,
  );

  static final _orphanCloseParen = RegExp(
    r'^(.*?)(?:^|\n)\s*([^(\n]{5,}?)\)\s*$',
    dotAll: true,
    multiLine: true,
  );

  static final _unclosedOpenParen = RegExp(
    r'^(.*?)\(\s*(.+?\S)\s*[،,]?\s*$',
    dotAll: true,
  );

  static final _partialVerseFragment = RegExp(
    r'^(?:الرحمن\s+الرحيم|صراط\s+الذين|بسم\s+الله(?:\s+الرحمن\s+الرحيم)?)$',
    caseSensitive: false,
  );

  static final _bareAyahIntro = RegExp(
    r'^(.*?)(?:ق(?:ال|ول)(?:\s+تعالى)?|ق(?:ال|ول)\s+الله(?:\s+تعالى)?|'
    r'ك(?:ما)?\s+ق(?:ول(?:ه|ها|هم))?(?:\s+تعالى)?)\s*:?\s*(.+?\S)\s*$',
    dotAll: true,
  );

  static final _hadithDialogueMarker = RegExp(r'قال\s*:');

  static final _revelationAyahLead = RegExp(
    r'فيما أوحى(?:\s+الله)?(?:\s+(?:إلي|إly|الي))?\s*(.+?\S)\s*$',
    dotAll: true,
  );

  /// Unclosed ayah fragments after qawl leads inside long IK editorial `t2`
  /// blocks (e.g. IK 1:4: `ولقوله: (لمن الملك اليوم وقوله: (قوله الحق…`).
  static final _chainedBareAyahAfterQawl = RegExp(
    r'(?:^|(?<=\s))'
    r'((?:[لوبفك]\s*)*(?:قول(?:ه|ها|هم)?)\s*:\s*)'
    r'\(\s*'
    '([^)(]+?)'
    r'(?=\s+(?:[لوبفك]\s*)*(?:و)?قول(?:ه|ها|هم)?\s*:\s*\(|\s+وحكي|\s+وقد|\s+وحكى|\s+وكذلك|\]|$)',
  );

  /// Applies segment-level repairs to [segments].
  static List<TafsirTextSegment> repair(List<TafsirTextSegment> segments) {
    return _splitChainedBareAyahQuotes(_repairAyahBoundaries(segments));
  }

  /// Whether [content] is a surah/ayah cross-reference rather than ayah text.
  static bool isSurahCrossReference(String content) {
    final trimmed = content.trim();
    if (RegExp(r'^\(\s*\d+\s*-\s*.+\s*\)$').hasMatch(trimmed)) {
      return true;
    }
    return _surahNameCrossRef.hasMatch(trimmed);
  }

  static List<TafsirTextSegment> _repairAyahBoundaries(
    List<TafsirTextSegment> segments,
  ) {
    final repaired = <TafsirTextSegment>[];

    for (var i = 0; i < segments.length; i++) {
      final current = segments[i];
      final next = i + 1 < segments.length ? segments[i + 1] : null;

      if (current.kind == TafsirSegmentKind.commentary &&
          next?.kind == TafsirSegmentKind.reference) {
        final split = _splitAyahBeforeReference(current.text);
        if (split != null) {
          if (split.prefix.trim().isNotEmpty) {
            repaired.add(
              TafsirTextSegment(
                text: split.prefix.trimRight(),
                kind: TafsirSegmentKind.commentary,
              ),
            );
          }
          repaired.add(
            TafsirTextSegment(
              text: '(${split.quote})',
              kind: TafsirSegmentKind.ayah,
            ),
          );
          repaired.add(next!);
          i++;
          continue;
        }
      }

      repaired.add(current);
    }

    return repaired;
  }

  static List<TafsirTextSegment> _splitChainedBareAyahQuotes(
    List<TafsirTextSegment> segments,
  ) {
    final repaired = <TafsirTextSegment>[];

    for (final segment in segments) {
      if (segment.kind != TafsirSegmentKind.commentary) {
        repaired.add(segment);
        continue;
      }

      final split = _splitChainedBareAyahInCommentary(segment.text);
      if (split == null) {
        repaired.add(segment);
        continue;
      }

      repaired.addAll(split);
    }

    return repaired;
  }

  static List<TafsirTextSegment>? _splitChainedBareAyahInCommentary(String text) {
    final matches = _chainedBareAyahAfterQawl.allMatches(text).toList();
    if (matches.isEmpty) return null;

    final segments = <TafsirTextSegment>[];
    var cursor = 0;

    for (final match in matches) {
      final quote = match.group(2)?.trim();
      if (quote == null ||
          quote.isEmpty ||
          quote.length < 5 ||
          quote.length > _maxAyahQuoteLength) {
        continue;
      }

      if (match.start > cursor) {
        segments.add(
          TafsirTextSegment(
            text: text.substring(cursor, match.start),
            kind: TafsirSegmentKind.commentary,
          ),
        );
      }

      segments.add(
        TafsirTextSegment(
          text: match.group(1)!,
          kind: TafsirSegmentKind.commentary,
        ),
      );
      segments.add(
        TafsirTextSegment(
          text: '($quote)',
          kind: TafsirSegmentKind.ayah,
        ),
      );
      cursor = match.end;
    }

    if (segments.isEmpty) return null;

    if (cursor < text.length) {
      segments.add(
        TafsirTextSegment(
          text: text.substring(cursor),
          kind: TafsirSegmentKind.commentary,
        ),
      );
    }

    return segments.length > 1 ? segments : null;
  }

  static ({String prefix, String quote})? _splitAyahBeforeReference(String text) {
    for (final splitter in [
      _splitOrphanCloseParen,
      _splitUnclosedOpenParen,
      _splitBareAyahText,
      _splitUnclosedAyahQuote,
    ]) {
      final split = splitter(text);
      if (split != null) {
        return split;
      }
    }
    return null;
  }

  static ({String prefix, String quote})? _splitOrphanCloseParen(String text) {
    final match = _orphanCloseParen.firstMatch(text);
    if (match == null) return null;

    final prefix = match.group(1) ?? '';
    final quote = match.group(2)?.trim();
    if (quote == null || quote.isEmpty || quote.contains('(')) {
      return null;
    }
    if (quote.length > _maxAyahQuoteLength) {
      return null;
    }

    final embeddedAyah = _splitHadithEmbeddedAyah(prefix, quote);
    if (embeddedAyah != null) {
      return embeddedAyah;
    }

    if (_hadithDialogueMarker.hasMatch(quote) || quote.contains('۞')) {
      return null;
    }

    return (prefix: prefix, quote: quote);
  }

  /// When a trailing `)` closes hadith dialogue, keep the narrative in
  /// commentary and promote only the embedded Quranic phrase.
  static ({String prefix, String quote})? _splitHadithEmbeddedAyah(
    String prefix,
    String quote,
  ) {
    if (!_hadithDialogueMarker.hasMatch(quote)) {
      return null;
    }

    final revelationMatch = _revelationAyahLead.firstMatch(quote);
    if (revelationMatch != null) {
      final ayahPart = revelationMatch.group(1)?.trim();
      if (ayahPart != null &&
          ayahPart.length >= 10 &&
          ayahPart.length <= _maxAyahQuoteLength) {
        final hadithPart = quote.substring(0, revelationMatch.start).trimRight();
        if (hadithPart.isNotEmpty) {
          return (prefix: '$prefix$hadithPart ', quote: ayahPart);
        }
      }
    }

    final lastQalIndex = quote.lastIndexOf('قال:');
    if (lastQalIndex < 0) return null;

    final afterQal = quote.substring(lastQalIndex + 'قال:'.length).trimLeft();
    if (afterQal.length < 10 ||
        afterQal.length > _maxAyahQuoteLength ||
        afterQal.contains('۞') ||
        _hadithDialogueMarker.hasMatch(afterQal)) {
      return null;
    }

    final hadithPart = quote.substring(0, lastQalIndex + 'قال:'.length).trimRight();
    if (hadithPart.isEmpty) return null;

    return (prefix: '$prefix$hadithPart ', quote: afterQal);
  }

  static ({String prefix, String quote})? _splitUnclosedOpenParen(String text) {
    if (text.contains('الآية')) {
      return null;
    }

    final match = _unclosedOpenParen.firstMatch(text);
    if (match == null) return null;

    final quote = match.group(2)?.trim();
    if (quote == null || quote.isEmpty) return null;
    if (quote.contains('(') || quote.contains(')')) return null;
    if (quote.length < 5 || quote.length > _maxAyahQuoteLength) return null;
    if (_partialVerseFragment.hasMatch(quote)) return null;

    return (prefix: match.group(1) ?? '', quote: quote);
  }

  static ({String prefix, String quote})? _splitBareAyahText(String text) {
    if (text.contains('(') || text.contains(')')) {
      return null;
    }

    final match = _bareAyahIntro.firstMatch(text);
    if (match == null) return null;

    final quote = match.group(2)?.trim();
    if (quote == null || quote.isEmpty) return null;
    if (quote.length < 15 || quote.length > _maxAyahQuoteLength) return null;
    if (!RegExp(r'[\u0621-\u064A]').hasMatch(quote)) return null;

    return (prefix: match.group(1) ?? '', quote: quote);
  }

  static ({String prefix, String quote})? _splitUnclosedAyahQuote(String text) {
    final anchored = _splitUnclosedAyahQuoteAnchored(text);
    if (anchored != null) {
      return anchored;
    }

    for (final pattern in [_unclosedAyahWithQawl, _unclosedAyahPlain]) {
      final match = pattern.firstMatch(text);
      if (match == null) continue;

      final quote = match.group(2)?.trim();
      if (quote == null || quote.isEmpty) continue;
      if (quote.length > _maxAyahQuoteLength) continue;

      return (prefix: match.group(1) ?? '', quote: quote);
    }

    return null;
  }

  static ({String prefix, String quote})? _splitUnclosedAyahQuoteAnchored(
    String text,
  ) {
    final ayahSuffix = RegExp(r'الآية\s*$');
    if (!ayahSuffix.hasMatch(text.trimRight())) {
      return null;
    }

    final trimmed = text.trimRight();
    final ayahIndex = trimmed.lastIndexOf('الآية');
    if (ayahIndex == -1) return null;

    final beforeAyah = trimmed.substring(0, ayahIndex);
    final openIndex = beforeAyah.lastIndexOf('(');
    if (openIndex == -1) return null;

    final prefix = trimmed.substring(0, openIndex);
    final quote = trimmed.substring(openIndex + 1, ayahIndex).trim();
    if (quote.isEmpty || quote.length > _maxAyahQuoteLength) {
      return null;
    }

    return (prefix: prefix, quote: quote);
  }
}
