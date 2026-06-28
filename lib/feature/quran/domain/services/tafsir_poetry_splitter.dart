import 'package:tawaq/feature/quran/domain/models/tafsir_models.dart';

/// Splits commentary prose that contains Arabic poetry layout gaps.
abstract final class TafsirPoetrySplitter {
  static final _poetryGap = RegExp(r'\s{4,}');

  static final _htmlTagPattern = RegExp('<[^>]+>');

  static final _proseLeadPattern = RegExp(
    r'^(?:وقال|قال|روى|حدث|ذكر|وفي|وقد|وهذا|أما[\s:،]|ثم|لما|فإ|فقد|وكذلك|حدثنا|أخبرنا)',
  );

  static final _arabicLetterPattern = RegExp(r'[\u0621-\u064A]');

  static final _parallelHemistichLead = RegExp('^و(?:لا|إذا|ما|من)');

  static final _prosePrefixMarker = RegExp(
    r'(?:[.:،؟!]|قال\s|وقال\s|يعني\s|روي\s)',
  );

  static final _poetryIntroMarker = RegExp(
    '(?:'
    r'قال\s+(?:ال)?شاعر'
    r'|(?:^|[\s،])الشاعر'
    r'|استشهد(?:\s+ب(?:قول\s+)?(?:\S+\s+){0,6}\S+)?'
    r'|\bبيت\b'
    r'|(?:^|[\s،])(?:قال|وقال|كما\s+قال|قول)(?:\s+[^\n:]{0,100})?\s*:'
    r')\s*$',
  );

  /// Expands [segments], turning wide-gap lines into [TafsirSegmentKind.poetry].
  static List<TafsirTextSegment> expand(List<TafsirTextSegment> segments) {
    final expanded = <TafsirTextSegment>[];

    for (final segment in segments) {
      if (segment.kind != TafsirSegmentKind.commentary) {
        expanded.add(segment);
        continue;
      }
      expanded.addAll(_splitCommentary(segment.text));
    }

    return expanded;
  }

  static List<TafsirTextSegment> _splitCommentary(String text) {
    final lines = text.split('\n');
    final result = <TafsirTextSegment>[];
    final proseBuffer = StringBuffer();
    var pendingAfterMarker = false;
    var proseEndsWithNewline = false;

    void flushProse() {
      final prose = proseBuffer.toString().trimRight();
      if (prose.isNotEmpty) {
        result.add(
          TafsirTextSegment(
            text: prose,
            kind: TafsirSegmentKind.commentary,
          ),
        );
      }
      proseBuffer.clear();
      proseEndsWithNewline = false;
    }

    void appendProseLine(String line) {
      if (proseBuffer.isNotEmpty && !proseEndsWithNewline) {
        proseBuffer.write('\n');
        proseEndsWithNewline = true;
      }
      proseBuffer.write(line);
      proseEndsWithNewline = false;
    }

    void appendProseNewline() {
      proseBuffer.write('\n');
      proseEndsWithNewline = true;
    }

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.isEmpty) {
        appendProseNewline();
        pendingAfterMarker = false;
        continue;
      }

      if (_lineEndsWithPoetryMarker(line)) {
        if (proseBuffer.isNotEmpty && !proseEndsWithNewline) {
          appendProseNewline();
        }
        proseBuffer.write(line);
        proseEndsWithNewline = false;
        pendingAfterMarker = true;
        continue;
      }

      if (_poetryGap.hasMatch(line)) {
        flushProse();
        final nextLine = i + 1 < lines.length ? lines[i + 1] : null;
        final wideGapSplit = _splitWideGapLine(line, nextLine: nextLine);
        result.addAll(wideGapSplit.segments);
        i += wideGapSplit.extraLinesConsumed;
        pendingAfterMarker = false;
        continue;
      }

      if (pendingAfterMarker && _looksLikePoetryLine(line)) {
        flushProse();
        final nextLine = i + 1 < lines.length ? lines[i + 1] : null;
        if (nextLine != null &&
            _looksLikePoetryLine(nextLine) &&
            !_lineEndsWithPoetryMarker(line) &&
            !_poetryGap.hasMatch(nextLine)) {
          result.add(_poetrySegment(line, nextLine));
          i++;
        } else {
          result.add(_singleLinePoetrySegment(line));
        }
        pendingAfterMarker = false;
        continue;
      }

      pendingAfterMarker = false;

      final lineSegments = _splitLine(line);
      if (lineSegments.any(
        (segment) => segment.kind == TafsirSegmentKind.poetry,
      )) {
        flushProse();
        result.addAll(lineSegments);
      } else {
        appendProseLine(line);
      }
    }

    flushProse();

    if (result.isEmpty) {
      return [
        TafsirTextSegment(
          text: text,
          kind: TafsirSegmentKind.commentary,
        ),
      ];
    }

    return result;
  }

  static bool _lineEndsWithPoetryMarker(String line) {
    return _poetryIntroMarker.hasMatch(line.trimRight());
  }

  static bool _looksLikePoetryLine(String line) {
    final trimmed = line.trim();
    if (trimmed.length < 10 || trimmed.length > 220) {
      return false;
    }
    if (_htmlTagPattern.hasMatch(trimmed)) {
      return false;
    }
    if (_proseLeadPattern.hasMatch(trimmed)) {
      return false;
    }
    return _arabicLetterPattern.hasMatch(trimmed);
  }

  static bool _isContinuationHemistich(String line) {
    if (_poetryGap.hasMatch(line) || _lineEndsWithPoetryMarker(line)) {
      return false;
    }
    if (_isParallelHemistichLine(line)) {
      return false;
    }
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.length > 80) {
      return false;
    }
    return _looksLikePoetryLine(line);
  }

  static bool _isParallelHemistichLine(String line) {
    final trimmed = line.trim();
    if (!_looksLikePoetryLine(line)) {
      return false;
    }
    return _parallelHemistichLead.hasMatch(trimmed);
  }

  static TafsirTextSegment _poetrySegment(String first, String second) {
    final firstTrimmed = first.trim();
    final secondTrimmed = second.trim();
    return TafsirTextSegment(
      text: '$firstTrimmed    $secondTrimmed',
      kind: TafsirSegmentKind.poetry,
      poetryHemistichs: [firstTrimmed, secondTrimmed],
    );
  }

  static TafsirTextSegment _singleLinePoetrySegment(String line) {
    final trimmed = line.trim();
    final gapParts = trimmed.split(_poetryGap);
    if (gapParts.length == 2 &&
        gapParts[0].trim().isNotEmpty &&
        gapParts[1].trim().isNotEmpty) {
      return _poetrySegment(gapParts[0].trim(), gapParts[1].trim());
    }

    return TafsirTextSegment(
      text: trimmed,
      kind: TafsirSegmentKind.commentary,
    );
  }

  static ({List<TafsirTextSegment> segments, int extraLinesConsumed})
  _splitWideGapLine(
    String line, {
    String? nextLine,
  }) {
    final lineSegments = _splitLine(line);
    final poetrySegments = lineSegments
        .where((segment) => segment.kind == TafsirSegmentKind.poetry)
        .toList();
    if (poetrySegments.length != 1) {
      return (segments: lineSegments, extraLinesConsumed: 0);
    }

    final poetry = poetrySegments.single;
    final hemistichs = poetry.poetryHemistichs;
    if (hemistichs == null || hemistichs.length < 2) {
      return (segments: lineSegments, extraLinesConsumed: 0);
    }

    final prefixSegments = lineSegments
        .where((segment) => segment.kind != TafsirSegmentKind.poetry)
        .toList();

    if (nextLine != null && _isContinuationHemistich(nextLine)) {
      final mergedSecond = '${hemistichs[1]} ${nextLine.trim()}'.trim();
      return (
        segments: [
          ...prefixSegments,
          TafsirTextSegment(
            text: '${hemistichs[0]}    $mergedSecond',
            kind: TafsirSegmentKind.poetry,
            poetryHemistichs: [hemistichs[0], mergedSecond],
          ),
        ],
        extraLinesConsumed: 1,
      );
    }

    if (nextLine != null && _isParallelHemistichLine(nextLine)) {
      return (
        segments: [
          ...lineSegments,
          _singleLinePoetrySegment(nextLine),
        ],
        extraLinesConsumed: 1,
      );
    }

    return (segments: lineSegments, extraLinesConsumed: 0);
  }

  static List<TafsirTextSegment> _splitLine(String line) {
    if (!_poetryGap.hasMatch(line)) {
      return [
        TafsirTextSegment(
          text: line,
          kind: TafsirSegmentKind.commentary,
        ),
      ];
    }

    final parts = line.split(_poetryGap);
    if (parts.length != 2) {
      return [
        TafsirTextSegment(
          text: line,
          kind: TafsirSegmentKind.commentary,
        ),
      ];
    }

    final first = parts[0].trimRight();
    final second = parts[1].trimLeft();
    if (first.isEmpty || second.isEmpty) {
      return [
        TafsirTextSegment(
          text: line,
          kind: TafsirSegmentKind.commentary,
        ),
      ];
    }

    final result = <TafsirTextSegment>[];

    final prosePrefix = _prosePrefixBeforePoetry(first);
    final firstHemistich = prosePrefix == null
        ? first
        : first.substring(prosePrefix.length);

    if (prosePrefix != null && prosePrefix.trim().isNotEmpty) {
      result.add(
        TafsirTextSegment(
          text: prosePrefix.trimRight(),
          kind: TafsirSegmentKind.commentary,
        ),
      );
    }

    if (firstHemistich.trim().isEmpty) {
      return [
        TafsirTextSegment(
          text: line,
          kind: TafsirSegmentKind.commentary,
        ),
      ];
    }

    result.add(
      TafsirTextSegment(
        text: '$firstHemistich    $second',
        kind: TafsirSegmentKind.poetry,
        poetryHemistichs: [firstHemistich.trim(), second.trim()],
      ),
    );

    return result;
  }

  /// Returns prose before an embedded poetry hemistich, when present.
  static String? _prosePrefixBeforePoetry(String leftPart) {
    final marker = _prosePrefixMarker.allMatches(leftPart).lastOrNull;
    if (marker == null) return null;

    final prefix = leftPart.substring(0, marker.end);
    final hemistichCandidate = leftPart.substring(marker.end).trimLeft();
    if (hemistichCandidate.isEmpty || prefix.trim().isEmpty) {
      return null;
    }

    return prefix;
  }
}

extension _LastOrNull<E> on Iterable<E> {
  E? get lastOrNull {
    if (isEmpty) return null;
    return last;
  }
}
