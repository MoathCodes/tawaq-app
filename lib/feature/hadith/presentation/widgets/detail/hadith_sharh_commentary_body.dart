import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tawaq/core/commentary/commentary_inline_run_builder.dart';
import 'package:tawaq/core/commentary/commentary_inline_spans.dart';
import 'package:tawaq/core/commentary/commentary_text_styles.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_sharh_segment.dart';

/// Renders tokenized sharh segments as inline rich-text runs.
///
/// Adjacent segments share one selectable rich-text run so gloss markers
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
    return CommentaryStyleScope(
      styles: styles,
      child: _HadithSharhCommentaryBodyContent(
        segments: segments,
        textAlign: textAlign,
      ),
    );
  }

  /// Builds the commentary widget tree from [segments].
  ///
  /// [context] must be under a [CommentaryStyleScope].
  static Widget? buildBody(
    BuildContext context, {
    required List<HadithSharhSegment> segments,
    required TextAlign textAlign,
  }) {
    if (segments.isEmpty) return null;

    final styles = CommentaryStyleScope.of(context);
    final runs = CommentaryInlineRunBuilder.collectSpanRuns(
      segments: segments,
      startsNewParagraph: _startsNewParagraph,
      buildSpans: (segments, start, end) => _buildInlineSpans(
        context: context,
        segments: segments,
        start: start,
        end: end,
      ),
    );

    return CommentaryInlineRunBuilder.columnFromSpanRuns(
      runs: runs,
      styles: styles,
      textAlign: textAlign,
    );
  }

  static bool _startsNewParagraph(HadithSharhSegment segment, int index) {
    if (index == 0) return false;

    if (segment.kind == HadithSharhSegmentKind.sectionLead) return true;

    if (segment.kind == HadithSharhSegmentKind.prose) {
      return _paragraphBreak.hasMatch(segment.text);
    }

    return false;
  }

  static List<InlineSpan> _buildInlineSpans({
    required BuildContext context,
    required List<HadithSharhSegment> segments,
    required int start,
    required int end,
  }) {
    final styles = CommentaryStyleScope.of(context);
    final spans = <InlineSpan>[];
    HadithSharhSegment? previous;

    for (var i = start; i < end; i++) {
      final segment = segments[i];

      if (previous != null) {
        final gap = _gapBeforeSegment(previous, segment);
        if (gap != null) {
          spans.add(TextSpan(text: gap, style: styles.prose));
        }
      }

      spans.addAll(_spansForSegment(segment, styles));
      previous = segment;
    }

    return spans;
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

  static List<InlineSpan> _spansForSegment(
    HadithSharhSegment segment,
    CommentaryTextStyles styles,
  ) {
    return switch (segment.kind) {
      HadithSharhSegmentKind.prose => CommentaryInlineSpans.tokenizeProse(
          segment.text,
        ).map(
          (token) => TextSpan(
            text: token.text,
            style: _styleForProseToken(token.kind, styles),
          ),
        ).toList(growable: false),
      HadithSharhSegmentKind.glossChain => [
          if (segment.quotedPhrase case final quote? when quote.isNotEmpty)
            TextSpan(text: quote, style: styles.quote),
          TextSpan(text: '، أي: ', style: styles.gloss),
          if (segment.glossText case final gloss? when gloss.isNotEmpty)
            TextSpan(text: gloss, style: styles.prose),
        ],
      HadithSharhSegmentKind.gloss => [
          TextSpan(text: segment.text, style: styles.gloss),
        ],
      HadithSharhSegmentKind.quote => [
          TextSpan(text: segment.text, style: styles.quote),
        ],
      HadithSharhSegmentKind.sectionLead => [
          TextSpan(text: segment.text, style: styles.sectionLead),
        ],
      HadithSharhSegmentKind.alternateOpinion => [
          TextSpan(text: segment.text, style: styles.alternateOpinion),
        ],
      HadithSharhSegmentKind.scholarLead => [
          TextSpan(text: segment.text, style: styles.scholarLead),
        ],
      HadithSharhSegmentKind.editorialBracket => [
          TextSpan(text: segment.text, style: styles.editorialBracket),
        ],
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

class _HadithSharhCommentaryBodyContent extends HookWidget {
  const _HadithSharhCommentaryBodyContent({
    required this.segments,
    required this.textAlign,
  });

  final List<HadithSharhSegment> segments;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final styles = CommentaryStyleScope.of(context);
    final body = useMemoized(
      () => HadithSharhCommentaryBody.buildBody(
        context,
        segments: segments,
        textAlign: textAlign,
      ),
      [segments, styles, textAlign],
    );

    return body ?? const SizedBox.shrink();
  }
}
