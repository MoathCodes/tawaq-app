import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_commentary_block.dart';
import 'package:tawaq/feature/muslim_fortress/domain/services/fortress_commentary_parser.dart';
import 'package:tawaq/gen/fonts.gen.dart';
import 'package:tawaq/theme/theme.dart';

/// Renders Hisn sharh/commentary with Uthmanic ayahs and readable prose.
///
/// Numbered explanations flow as plain text; `/55 … /55` source markers become
/// footnote lines; Quranic snippets in `﴿…﴾` use [FontFamily.uthmanicHafs]
/// with a distinct green tone and a muted surah/ayah reference beside them.
class FortressCommentaryText extends StatelessWidget {
  /// Creates formatted commentary text.
  const FortressCommentaryText({
    required this.text,
    required this.baseStyle,
    this.textAlign = TextAlign.start,
    super.key,
  });

  /// Raw Arabic commentary from Hisn.
  final String text;

  /// Base style for prose (Naskh / app Arabic).
  final TextStyle baseStyle;

  /// Paragraph alignment.
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final isDark = context.theme.isDark;
    final styles = _CommentaryStyles.from(
      baseStyle: baseStyle,
      colors: colors,
      isDark: isDark,
    );
    final blocks = FortressCommentaryParser.parse(text);

    if (blocks.isEmpty) {
      return _CommentaryRichText(
        text: text,
        styles: styles,
        textAlign: textAlign,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < blocks.length; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Divider(
                height: 1,
                color: colors.border.withAlpha(80),
              ),
            ),
          _CommentaryBlockView(
            block: blocks[i],
            styles: styles,
            colors: colors,
            textAlign: textAlign,
          ),
        ],
      ],
    );
  }
}

@immutable
class _CommentaryStyles {
  const _CommentaryStyles({
    required this.prose,
    required this.ayah,
    required this.qawlLead,
    required this.quote,
    required this.scholarLead,
    required this.citation,
    required this.verseRef,
    required this.listMarker,
  });

  factory _CommentaryStyles.from({
    required TextStyle baseStyle,
    required FColors colors,
    required bool isDark,
  }) {
    final fontSize = baseStyle.fontSize ?? 14;
    final ayahColor = isDark
        ? const Color(0xFF4ADE80)
        : const Color(0xFF15803D);

    return _CommentaryStyles(
      prose: baseStyle.copyWith(height: 1.85),
      ayah: baseStyle.copyWith(
        fontFamily: FontFamily.uthmanicHafs,
        fontSize: fontSize * 1.08,
        height: 1.9,
        color: ayahColor,
        fontWeight: FontWeight.w500,
      ),
      qawlLead: baseStyle.copyWith(
        fontWeight: FontWeight.w700,
        color: colors.primary,
        height: 1.85,
      ),
      quote: baseStyle.copyWith(
        fontWeight: FontWeight.w600,
        color: colors.foreground,
        height: 1.85,
      ),
      scholarLead: baseStyle.copyWith(
        fontWeight: FontWeight.w600,
        color: Color.lerp(colors.foreground, colors.primary, 0.35),
        height: 1.85,
      ),
      citation: baseStyle.copyWith(
        fontSize: fontSize * 0.88,
        color: colors.mutedForeground,
        height: 1.55,
        fontFamily: 'IBMPlexSansArabic',
      ),
      verseRef: baseStyle.copyWith(
        fontSize: fontSize * 0.78,
        color: colors.mutedForeground,
        height: 1.6,
        fontFamily: 'IBMPlexSansArabic',
      ),
      listMarker: baseStyle.copyWith(
        fontWeight: FontWeight.w700,
        color: colors.primary,
        height: 1.85,
      ),
    );
  }

  final TextStyle prose;
  final TextStyle ayah;
  final TextStyle qawlLead;
  final TextStyle quote;
  final TextStyle scholarLead;
  final TextStyle citation;
  final TextStyle verseRef;
  final TextStyle listMarker;
}

class _CommentaryBlockView extends StatelessWidget {
  const _CommentaryBlockView({
    required this.block,
    required this.styles,
    required this.colors,
    required this.textAlign,
  });

  final FortressCommentaryBlock block;
  final _CommentaryStyles styles;
  final FColors colors;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CommentaryRichText(
          text: block.body,
          styles: styles,
          textAlign: textAlign,
          listNumber: block.listNumber,
          emphasizeQawl: block.listNumber != null,
        ),
        if (block.citations.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < block.citations.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.xs),
            _CitationLine(
              text: block.citations[i],
              style: styles.citation,
              colors: colors,
            ),
          ],
        ],
      ],
    );
  }
}

class _CitationLine extends StatelessWidget {
  const _CitationLine({
    required this.text,
    required this.style,
    required this.colors,
  });

  final String text;
  final TextStyle style;
  final FColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: AppSpacing.xl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              FLucideIcons.bookMarked,
              size: 14,
              color: colors.mutedForeground,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: ScopedSelectableText(
              _isolateLtrNumerals(text),
              style: style,
              textDirection: TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentaryRichText extends StatelessWidget {
  const _CommentaryRichText({
    required this.text,
    required this.styles,
    required this.textAlign,
    this.listNumber,
    this.emphasizeQawl = false,
  });

  final String text;
  final _CommentaryStyles styles;
  final TextAlign textAlign;
  final int? listNumber;
  final bool emphasizeQawl;

  static final _ayahWithRefPattern = RegExp(
    r'﴿([^﴾]+)﴾\s*(سورة\s+[^،]+،\s*الآية:\s*\d+)?',
  );
  static final _quotePattern = RegExp('«[^»]+»');
  static final _qawlLeadPattern = RegExp(r'^قوله:\s*');
  static final _scholarLeadPattern = RegExp(r'قال\s+[^:]+:\s*');

  @override
  Widget build(BuildContext context) {
    final spans = _buildSpans(
      text,
      emphasizeQawl: emphasizeQawl,
    );

    if (spans.isEmpty) return const SizedBox.shrink();

    return ScopedSelectableRichText(
      TextSpan(children: spans),
      textAlign: textAlign,
    );
  }

  List<InlineSpan> _buildSpans(
    String input, {
    required bool emphasizeQawl,
  }) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return const [];

    final spans = <InlineSpan>[];
    var cursor = 0;

    if (listNumber != null) {
      spans.add(
        TextSpan(
          text: '$listNumber — ',
          style: styles.listMarker,
        ),
      );
    }

    if (emphasizeQawl) {
      final qawl = _qawlLeadPattern.matchAsPrefix(trimmed);
      if (qawl != null) {
        spans.add(TextSpan(text: qawl.group(0), style: styles.qawlLead));
        cursor = qawl.end;
      }
    }

    spans.addAll(_inlineSpans(trimmed, start: cursor));
    return spans;
  }

  List<InlineSpan> _inlineSpans(String input, {required int start}) {
    final spans = <InlineSpan>[];
    var cursor = start;

    while (cursor < input.length) {
      final next = _nextSpecialMatch(input, cursor);
      if (next == null) {
        final tail = input.substring(cursor).trim();
        if (tail.isNotEmpty) {
          spans.add(TextSpan(text: tail, style: styles.prose));
        }
        break;
      }

      if (next.start > cursor) {
        final plain = input.substring(cursor, next.start);
        if (plain.isNotEmpty) {
          spans.add(TextSpan(text: plain, style: styles.prose));
        }
      }

      switch (next.kind) {
        case _SpecialKind.ayah:
          spans.add(
            TextSpan(
              text: next.ayahText,
              style: styles.ayah,
            ),
          );
          if (next.verseRef != null) {
            spans.add(
              TextSpan(
                text: ' ${next.verseRef}',
                style: styles.verseRef,
              ),
            );
          }
        case _SpecialKind.quote:
          spans.add(TextSpan(text: next.text, style: styles.quote));
        case _SpecialKind.scholarLead:
          spans.add(TextSpan(text: next.text, style: styles.scholarLead));
      }
      cursor = next.end;
    }

    return spans;
  }

  _SpecialMatch? _nextSpecialMatch(String input, int start) {
    _SpecialMatch? best;

    for (final match in _ayahWithRefPattern.allMatches(input, start)) {
      final ref = match.group(2);
      best = _pickBest(
        best,
        _SpecialMatch(
          kind: _SpecialKind.ayah,
          start: match.start,
          end: match.end,
          text: match.group(0)!,
          ayahText: '﴿${match.group(1)}﴾',
          verseRef: ref?.trim(),
        ),
      );
      break;
    }

    for (final match in _quotePattern.allMatches(input, start)) {
      best = _pickBest(
        best,
        _SpecialMatch(
          kind: _SpecialKind.quote,
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
        _SpecialMatch(
          kind: _SpecialKind.scholarLead,
          start: match.start,
          end: match.end,
          text: match.group(0)!,
        ),
      );
      break;
    }

    return best;
  }

  _SpecialMatch? _pickBest(_SpecialMatch? current, _SpecialMatch candidate) {
    if (current == null || candidate.start < current.start) {
      return candidate;
    }
    return current;
  }
}

enum _SpecialKind { ayah, quote, scholarLead }

@immutable
class _SpecialMatch {
  const _SpecialMatch({
    required this.kind,
    required this.start,
    required this.end,
    required this.text,
    this.ayahText,
    this.verseRef,
  });

  final _SpecialKind kind;
  final int start;
  final int end;
  final String text;
  final String? ayahText;
  final String? verseRef;
}

/// Keeps volume/page fractions readable in RTL paragraphs.
String _isolateLtrNumerals(String input) {
  return input.replaceAllMapped(
    RegExp(r'[\d/]+'),
    (match) => '\u2066${match.group(0)}\u2069',
  );
}
