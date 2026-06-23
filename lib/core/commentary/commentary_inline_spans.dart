import 'package:flutter/material.dart';
import 'package:tawaq/core/commentary/commentary_text_styles.dart';
import 'package:tawaq/core/text/qawl_patterns.dart';
import 'package:tawaq/core/utils/lru_map.dart';

/// Shared inline span builders for Arabic commentary prose.
abstract final class CommentaryInlineSpans {
  /// Matches qawl-lead phrases including attached Arabic prefix particles.
  static final RegExp qawlLeadPrefix = QawlPatterns.qawlLeadPrefix;

  static final _ltrNumeralPattern = RegExp(r'[\d/]+');
  static final RegExp _qawlLeadPattern = QawlPatterns.qawlLeadInline;
  static final _scholarLeadPattern = RegExp(
    r'(?<![\u0600-\u06FF])(?:'
    r'أي:\s*|'
    r'يقال\s+في\s+[^:]+:\s*|'
    r'قال\s+الشاعر\b|'
    r'(?:فقال(?:ت)?|قال)\s+(?!الله\s+تعالى)[^:]+:\s*'
    ')',
  );
  static final _quotePattern = RegExp('«[^»]+»');
  static final _ayahWithRefPattern = RegExp(
    r'﴿([^﴾]+)﴾\s*(سورة\s+[^،]+،\s*الآية:\s*\d+)?',
  );

  static final _buildCache = LruMap<_BuildCacheKey, List<InlineSpan>>(256);

  /// Builds inline spans for commentary prose with quote/scholar/qawl styling.
  static List<InlineSpan> build(
    BuildContext context,
    String input, {
    bool emphasizeQawl = false,
  }) {
    if (input.isEmpty) return const [];

    final styles = CommentaryStyleScope.of(context);
    final key = _BuildCacheKey(
      input: input,
      stylesId: identityHashCode(styles),
      emphasizeQawl: emphasizeQawl,
    );
    final cached = _buildCache[key];
    if (cached != null) return cached;

    final spans = _computeBuild(
      context,
      input,
      emphasizeQawl: emphasizeQawl,
    );
    _buildCache[key] = spans;
    return spans;
  }

  /// Tokenizes commentary prose without applying theme styles.
  static List<CommentaryProseToken> tokenizeProse(
    String input, {
    bool emphasizeQawl = false,
  }) {
    if (input.isEmpty) return const [];

    final tokens = <CommentaryProseToken>[];
    var cursor = 0;
    final trimmed = input.trim();

    if (emphasizeQawl) {
      final qawl = _qawlLeadPattern.matchAsPrefix(trimmed);
      if (qawl != null) {
        tokens.add(
          CommentaryProseToken(
            text: qawl.group(0)!,
            kind: CommentaryProseTokenKind.qawlLead,
          ),
        );
        cursor = qawl.end;
      }
    }

    tokens.addAll(_proseTokens(trimmed, start: cursor));
    return tokens;
  }

  static List<CommentaryProseToken> _proseTokens(
    String input, {
    required int start,
  }) {
    final tokens = <CommentaryProseToken>[];
    var cursor = start;

    while (cursor < input.length) {
      final next = _nextSpecialMatch(input, cursor);
      if (next == null) {
        final tail = input.substring(cursor);
        if (tail.isNotEmpty) {
          tokens.add(
            CommentaryProseToken(
              text: tail,
              kind: CommentaryProseTokenKind.prose,
            ),
          );
        }
        break;
      }

      if (next.start > cursor) {
        final plain = input.substring(cursor, next.start);
        if (plain.isNotEmpty) {
          tokens.add(
            CommentaryProseToken(
              text: plain,
              kind: CommentaryProseTokenKind.prose,
            ),
          );
        }
      }

      switch (next.kind) {
        case _InlineKind.ayah:
          tokens.add(
            CommentaryProseToken(
              text: next.ayahText!,
              kind: CommentaryProseTokenKind.ayah,
            ),
          );
          if (next.verseRef != null) {
            tokens.add(
              CommentaryProseToken(
                text: ' ${next.verseRef}',
                kind: CommentaryProseTokenKind.verseRef,
              ),
            );
          }
        case _InlineKind.quote:
          tokens.add(
            CommentaryProseToken(
              text: next.text,
              kind: CommentaryProseTokenKind.quote,
            ),
          );
        case _InlineKind.scholarLead:
          tokens.add(
            CommentaryProseToken(
              text: next.text,
              kind: CommentaryProseTokenKind.scholarLead,
            ),
          );
        case _InlineKind.qawlLead:
          tokens.add(
            CommentaryProseToken(
              text: next.text,
              kind: CommentaryProseTokenKind.qawlLead,
            ),
          );
      }

      cursor = next.end;
    }

    return tokens;
  }

  static TextStyle _styleFor(
    CommentaryProseTokenKind kind,
    CommentaryTextStyles styles,
  ) {
    return switch (kind) {
      CommentaryProseTokenKind.prose => styles.prose,
      CommentaryProseTokenKind.ayah => styles.ayah,
      CommentaryProseTokenKind.verseRef => styles.verseRef,
      CommentaryProseTokenKind.quote => styles.quote,
      CommentaryProseTokenKind.scholarLead => styles.scholarLead,
      CommentaryProseTokenKind.qawlLead => styles.qawlLead,
    };
  }

  static List<InlineSpan> _computeBuild(
    BuildContext context,
    String input, {
    required bool emphasizeQawl,
  }) {
    final styles = CommentaryStyleScope.of(context);
    return tokenizeProse(input, emphasizeQawl: emphasizeQawl)
        .map(
          (token) => TextSpan(
            text: token.text,
            style: _styleFor(token.kind, styles),
          ),
        )
        .toList(growable: false);
  }

  static _InlineMatch? _nextSpecialMatch(String input, int start) {
    _InlineMatch? best;

    for (final match in _ayahWithRefPattern.allMatches(input, start)) {
      best = _pickBest(
        best,
        _InlineMatch(
          kind: _InlineKind.ayah,
          start: match.start,
          end: match.end,
          text: match.group(0)!,
          ayahText: '﴿${match.group(1)}﴾',
          verseRef: match.group(2)?.trim(),
        ),
      );
      break;
    }

    for (final match in _quotePattern.allMatches(input, start)) {
      best = _pickBest(
        best,
        _InlineMatch(
          kind: _InlineKind.quote,
          start: match.start,
          end: match.end,
          text: match.group(0)!,
        ),
      );
      break;
    }

    for (final match in _qawlLeadPattern.allMatches(input, start)) {
      best = _pickBest(
        best,
        _InlineMatch(
          kind: _InlineKind.qawlLead,
          start: match.start,
          end: match.end,
          text: match.group(0)!,
        ),
      );
      break;
    }

    for (final match in _scholarLeadPattern.allMatches(input, start)) {
      best = _pickBest(
        best,
        _InlineMatch(
          kind: _InlineKind.scholarLead,
          start: match.start,
          end: match.end,
          text: match.group(0)!,
        ),
      );
      break;
    }

    return best;
  }

  static _InlineMatch? _pickBest(
    _InlineMatch? current,
    _InlineMatch candidate,
  ) {
    if (current == null || candidate.start < current.start) {
      return candidate;
    }
    return current;
  }
}

@immutable
class _BuildCacheKey {
  const _BuildCacheKey({
    required this.input,
    required this.stylesId,
    required this.emphasizeQawl,
  });

  final String input;
  final int stylesId;
  final bool emphasizeQawl;

  @override
  bool operator ==(Object other) {
    return other is _BuildCacheKey &&
        other.input == input &&
        other.stylesId == stylesId &&
        other.emphasizeQawl == emphasizeQawl;
  }

  @override
  int get hashCode => Object.hash(input, stylesId, emphasizeQawl);
}

/// Style slot for a tokenized commentary prose fragment.
enum CommentaryProseTokenKind {
  /// Default body text.
  prose,

  /// Quranic ayah snippet.
  ayah,

  /// Verse reference following an ayah.
  verseRef,

  /// Guillemet or similar quoted phrase.
  quote,

  /// Scholar or poet attribution lead.
  scholarLead,

  /// Qawl-lead phrase (`قال الله تعالى:`).
  qawlLead,
}

/// Tokenized commentary prose fragment without theme styling.
@immutable
class CommentaryProseToken {
  /// Creates a prose token.
  const CommentaryProseToken({
    required this.text,
    required this.kind,
  });

  /// Fragment text.
  final String text;

  /// Style slot applied when rendering.
  final CommentaryProseTokenKind kind;
}

enum _InlineKind { ayah, quote, scholarLead, qawlLead }

@immutable
class _InlineMatch {
  const _InlineMatch({
    required this.kind,
    required this.start,
    required this.end,
    required this.text,
    this.ayahText,
    this.verseRef,
  });

  final _InlineKind kind;
  final int start;
  final int end;
  final String text;
  final String? ayahText;
  final String? verseRef;
}

/// Keeps volume/page fractions readable in RTL paragraphs.
String isolateLtrNumerals(String input) {
  return input.replaceAllMapped(
    CommentaryInlineSpans._ltrNumeralPattern,
    (match) => '\u2066${match.group(0)}\u2069',
  );
}
