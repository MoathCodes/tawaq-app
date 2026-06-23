import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tawaq/core/commentary/commentary_inline_run_builder.dart';
import 'package:tawaq/core/commentary/commentary_inline_spans.dart';
import 'package:tawaq/core/commentary/commentary_text_styles.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_sharh_segment.dart';

/// Renders tokenized sharh segments as inline rich-text runs.
///
/// Adjacent segments share one [ScopedSelectableRichText] so gloss markers
/// (`أي:`), quotes, and prose flow on the same line and selection crosses
/// style boundaries. [Column] breaks appear only at paragraph boundaries
/// (section leads and blank-line pivots).
class HadithSharhCommentaryBody extends HookWidget {
  /// Creates inline commentary from [segments].
  const HadithSharhCommentaryBody({
    required this.segments,
    required this.styles,
    required this.textAlign,
    super.key,
  });

  /// Tokenized commentary segments.
  final List<HadithSharhSegment> segments;

  /// Shared commentary styles.
  final CommentaryTextStyles styles;

  /// Paragraph alignment.
  final TextAlign textAlign;

  static final _paragraphBreak = RegExp(r'^\s*\n\s*\n');

  @override
  Widget build(BuildContext context) {
    if (segments.isEmpty) return const SizedBox.shrink();

    final runs = useMemoized(
      () => CommentaryInlineRunBuilder.collectSpanRuns(
        segments: segments,
        startsNewParagraph: _startsNewParagraph,
        buildSpans: (segments, start, end) => _fragmentsToSpans(
          _buildFragments(segments: segments, start: start, end: end),
          styles,
        ),
      ),
      [
        segments,
        styles.prose,
        styles.quote,
        styles.gloss,
        styles.sectionLead,
        styles.alternateOpinion,
        styles.scholarLead,
        styles.editorialBracket,
        styles.ayah,
        styles.verseRef,
        styles.qawlLead,
      ],
    );

    final body = useMemoized(
      () => CommentaryInlineRunBuilder.columnFromSpanRuns(
        runs: runs,
        styles: styles,
        textAlign: textAlign,
      ),
      [runs, textAlign, styles.selectionStrut],
    );

    return body ?? const SizedBox.shrink();
  }

  static bool _startsNewParagraph(HadithSharhSegment segment, int index) {
    if (index == 0) return false;

    if (segment.kind == HadithSharhSegmentKind.sectionLead) return true;

    if (segment.kind == HadithSharhSegmentKind.prose) {
      return _paragraphBreak.hasMatch(segment.text);
    }

    return false;
  }

  static List<_CommentaryFragment> _buildFragments({
    required List<HadithSharhSegment> segments,
    required int start,
    required int end,
  }) {
    final fragments = <_CommentaryFragment>[];
    HadithSharhSegment? previous;

    for (var i = start; i < end; i++) {
      final segment = segments[i];

      if (previous != null) {
        final gap = _gapBeforeSegment(previous, segment);
        if (gap != null) {
          fragments.add(_CommentaryFragment.gap(gap));
        }
      }

      fragments.addAll(_fragmentsForSegment(segment));
      previous = segment;
    }

    return fragments;
  }

  static List<InlineSpan> _fragmentsToSpans(
    List<_CommentaryFragment> fragments,
    CommentaryTextStyles styles,
  ) {
    return fragments
        .map((fragment) => fragment.toInlineSpan(styles))
        .toList(growable: false);
  }

  /// Inserts a space between adjacent inline segments when prose trimming
  /// or gloss token boundaries would otherwise glue words together.
  static String? _gapBeforeSegment(
    HadithSharhSegment previous,
    HadithSharhSegment current,
  ) {
    final leading = _leadingChar(current);
    final trailing = _trailingChar(previous);
    if (leading == null || trailing == null) return null;
    if (leading == ' ' || leading == '\n') return null;
    if (trailing == ' ' || trailing == '\n') return null;
    return ' ';
  }

  static String? _leadingChar(HadithSharhSegment segment) {
    final text = switch (segment.kind) {
      HadithSharhSegmentKind.prose => segment.text.trim(),
      HadithSharhSegmentKind.glossChain =>
        segment.quotedPhrase ?? segment.text,
      _ => segment.text,
    };
    if (text.isEmpty) return null;
    return text.characters.first;
  }

  static String? _trailingChar(HadithSharhSegment segment) {
    final text = switch (segment.kind) {
      HadithSharhSegmentKind.prose => segment.text.trim(),
      HadithSharhSegmentKind.glossChain => () {
        final gloss = segment.glossText?.trim();
        if (gloss != null && gloss.isNotEmpty) return gloss;
        return segment.quotedPhrase ?? segment.text;
      }(),
      _ => segment.text,
    };
    if (text.isEmpty) return null;
    return text.characters.last;
  }

  static List<_CommentaryFragment> _fragmentsForSegment(
    HadithSharhSegment segment,
  ) {
    return switch (segment.kind) {
      HadithSharhSegmentKind.prose => CommentaryInlineSpans.tokenizeProse(
          segment.text,
        ).map(_CommentaryFragment.proseToken).toList(growable: false),
      HadithSharhSegmentKind.glossChain => [
          _CommentaryFragment.styled(
            text: segment.quotedPhrase,
            kind: _StyledFragmentKind.quote,
          ),
          _CommentaryFragment.styled(
            text: '، أي: ',
            kind: _StyledFragmentKind.gloss,
          ),
          _CommentaryFragment.styled(
            text: segment.glossText,
            kind: _StyledFragmentKind.prose,
          ),
        ],
      HadithSharhSegmentKind.gloss => [
          _CommentaryFragment.styled(
            text: segment.text,
            kind: _StyledFragmentKind.gloss,
          ),
        ],
      HadithSharhSegmentKind.quote => [
          _CommentaryFragment.styled(
            text: segment.text,
            kind: _StyledFragmentKind.quote,
          ),
        ],
      HadithSharhSegmentKind.sectionLead => [
          _CommentaryFragment.styled(
            text: segment.text,
            kind: _StyledFragmentKind.sectionLead,
          ),
        ],
      HadithSharhSegmentKind.alternateOpinion => [
          _CommentaryFragment.styled(
            text: segment.text,
            kind: _StyledFragmentKind.alternateOpinion,
          ),
        ],
      HadithSharhSegmentKind.scholarLead => [
          _CommentaryFragment.styled(
            text: segment.text,
            kind: _StyledFragmentKind.scholarLead,
          ),
        ],
      HadithSharhSegmentKind.editorialBracket => [
          _CommentaryFragment.styled(
            text: segment.text,
            kind: _StyledFragmentKind.editorialBracket,
          ),
        ],
    };
  }
}

enum _StyledFragmentKind {
  prose,
  quote,
  gloss,
  sectionLead,
  alternateOpinion,
  scholarLead,
  editorialBracket,
  ayah,
  verseRef,
  qawlLead,
}

@immutable
class _CommentaryFragment {
  const _CommentaryFragment._({
    this.text,
    this.proseToken,
    this.styledKind,
  });

  factory _CommentaryFragment.gap(String text) {
    return _CommentaryFragment._(
      text: text,
      styledKind: _StyledFragmentKind.prose,
    );
  }

  factory _CommentaryFragment.proseToken(CommentaryProseToken token) {
    return _CommentaryFragment._(proseToken: token);
  }

  factory _CommentaryFragment.styled({
    required String? text,
    required _StyledFragmentKind kind,
  }) {
    return _CommentaryFragment._(text: text, styledKind: kind);
  }

  final String? text;
  final CommentaryProseToken? proseToken;
  final _StyledFragmentKind? styledKind;

  InlineSpan toInlineSpan(CommentaryTextStyles styles) {
    if (proseToken case final token?) {
      return TextSpan(
        text: token.text,
        style: _styleForProseToken(token.kind, styles),
      );
    }

    final resolvedText = text;
    if (resolvedText == null || resolvedText.isEmpty) {
      return const TextSpan();
    }

    return TextSpan(
      text: resolvedText,
      style: _styleFor(styledKind!, styles),
    );
  }

  static TextStyle _styleFor(
    _StyledFragmentKind kind,
    CommentaryTextStyles styles,
  ) {
    return switch (kind) {
      _StyledFragmentKind.prose => styles.prose,
      _StyledFragmentKind.quote => styles.quote,
      _StyledFragmentKind.gloss => styles.gloss,
      _StyledFragmentKind.sectionLead => styles.sectionLead,
      _StyledFragmentKind.alternateOpinion => styles.alternateOpinion,
      _StyledFragmentKind.scholarLead => styles.scholarLead,
      _StyledFragmentKind.editorialBracket => styles.editorialBracket,
      _StyledFragmentKind.ayah => styles.ayah,
      _StyledFragmentKind.verseRef => styles.verseRef,
      _StyledFragmentKind.qawlLead => styles.qawlLead,
    };
  }

  static TextStyle _styleForProseToken(
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
}
