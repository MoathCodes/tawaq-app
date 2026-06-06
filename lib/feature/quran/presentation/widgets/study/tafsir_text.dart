import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/feature/quran/domain/models/tafsir_source.dart';
import 'package:tawaq/feature/quran/domain/models/tafsir_text_segment.dart';
import 'package:tawaq/feature/quran/domain/services/tafsir_text_integrity.dart';
import 'package:tawaq/feature/quran/domain/services/tafsir_text_parser.dart';
import 'package:tawaq/gen/fonts.gen.dart';
import 'package:tawaq/theme/theme.dart';

/// Widget that renders tafsir text with proper font styling.
///
/// Supports Mouaser `<span class="aya">` markup and compact-database
/// `t1`–`t4` spans. Quranic snippets use Uthmanic Hafs with a green tone
/// matching Hisn study-sheet commentary styling.
class TafsirText extends StatelessWidget {
  /// Creates a tafsir text widget.
  const TafsirText({
    required this.text,
    required this.baseStyle,
    this.tafsirId,
    super.key,
  });

  /// The raw tafsir text containing potential span tags.
  final String text;

  /// The base text style for the tafsir commentary.
  final TextStyle baseStyle;

  /// Active tafsir source for source-aware span classification.
  final TafsirId? tafsirId;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final isDark = context.theme.isDark;
    final styles = _TafsirTextStyles.from(
      baseStyle: baseStyle,
      colors: colors,
      isDark: isDark,
    );
    final segments = _mergeAttachedPrefixParticles(
      TafsirTextParser.parse(text, tafsirId: tafsirId),
    );
    final truncation = TafsirTextIntegrity.analyze(text);

    if (segments.isEmpty) return const SizedBox.shrink();

    final children = <Widget>[];
    var inlineStart = 0;

    void flushInlineRun(int end) {
      if (inlineStart >= end) return;

      final spans = _buildInlineSpans(
        segments: segments,
        start: inlineStart,
        end: end,
        styles: styles,
      );
      if (spans.isEmpty) return;

      children.add(
        ScopedSelectableRichText(
          TextSpan(style: styles.prose, children: spans),
          textAlign: TextAlign.start,
          strutStyle: styles.selectionStrut,
        ),
      );
    }

    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      if (!_isRenderablePoetry(segment)) continue;

      flushInlineRun(i);

      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: _TafsirPoetryRow(
            hemistichs: segment.poetryHemistichs!,
            style: styles.prose,
          ),
        ),
      );

      inlineStart = i + 1;
    }

    flushInlineRun(segments.length);

    if (children.isEmpty) return const SizedBox.shrink();

    final body = children.length == 1
        ? children.first
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          );

    if (!truncation.isLikelyTruncated) return body;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        body,
        _TruncationFootnote(
          colors: colors,
          typography: context.theme.typography,
        ),
      ],
    );
  }

  static List<InlineSpan> _buildInlineSpans({
    required List<TafsirTextSegment> segments,
    required int start,
    required int end,
    required _TafsirTextStyles styles,
  }) {
    final spans = <InlineSpan>[];
    TafsirTextSegment? previous;

    for (var i = start; i < end; i++) {
      final segment = segments[i];
      if (segment.kind == TafsirSegmentKind.poetry) {
        if (_isRenderablePoetry(segment)) continue;

        final prose = segment.text.trim();
        if (prose.isEmpty) continue;

        if (previous != null) {
          final gap = _gapBeforeSegment(previous, segment);
          if (gap != null) {
            spans.add(TextSpan(text: gap, style: styles.prose));
          }
        }

        spans.addAll(
          _CommentaryInlineSpans.build(prose, styles: styles),
        );
        previous = TafsirTextSegment(
          text: prose,
          kind: TafsirSegmentKind.commentary,
        );
        continue;
      }

      if (previous != null) {
        final gap = _gapBeforeSegment(previous, segment);
        if (gap != null) {
          spans.add(TextSpan(text: gap, style: styles.prose));
        }
      }

      final next = i + 1 < segments.length ? segments[i + 1] : null;
      spans.addAll(_spansForSegment(segment, styles, next: next));
      previous = segment;
    }

    return spans;
  }

  /// Merges a lone Arabic prefix particle into the following qawl-lead segment.
  static List<TafsirTextSegment> _mergeAttachedPrefixParticles(
    List<TafsirTextSegment> segments,
  ) {
    if (segments.length < 2) return segments;

    final merged = <TafsirTextSegment>[];
    for (var i = 0; i < segments.length; i++) {
      final current = segments[i];
      final next = i + 1 < segments.length ? segments[i + 1] : null;

      if (next != null &&
          current.kind == TafsirSegmentKind.commentary &&
          _isArabicPrefixParticle(current.text) &&
          _startsWithQawlLead(next.text)) {
        merged.add(
          TafsirTextSegment(
            text: current.text + next.text,
            kind: TafsirSegmentKind.commentary,
          ),
        );
        i++;
        continue;
      }

      merged.add(current);
    }

    return merged;
  }

  static const _arabicPrefixParticles = 'لوبفك';

  static bool _isArabicPrefixParticle(String text) {
    if (text.characters.length != 1) return false;
    return _arabicPrefixParticles.contains(text);
  }

  static bool _startsWithQawlLead(String text) {
    return _CommentaryInlineSpans.qawlLeadPrefix.hasMatch(text);
  }

  /// Inserts a space between adjacent inline segments when markup omits it.
  static String? _gapBeforeSegment(
    TafsirTextSegment previous,
    TafsirTextSegment current,
  ) {
    final currentText = current.text;
    if (currentText.isEmpty) return null;

    if (_isArabicPrefixParticle(previous.text) &&
        _startsWithQawlLead(currentText)) {
      return null;
    }

    final currentFirst = currentText.characters.first;
    if (currentFirst == ' ' || currentFirst == '\n') return null;

    final previousText = previous.text;
    if (previousText.isNotEmpty) {
      final previousLast = previousText.characters.last;
      if (previousLast == ' ' || previousLast == '\n') return null;

      if (_isArabicPrefixParticle(previousLast) &&
          _startsWithQawlLead(currentText)) {
        return null;
      }
    }

    final needsGap = switch ((previous.kind, current.kind)) {
      (TafsirSegmentKind.commentary, TafsirSegmentKind.ayah) => true,
      (TafsirSegmentKind.commentary, TafsirSegmentKind.reference) => true,
      (TafsirSegmentKind.ayah, TafsirSegmentKind.reference) => true,
      (TafsirSegmentKind.reference, TafsirSegmentKind.commentary) => true,
      (TafsirSegmentKind.reference, TafsirSegmentKind.ayah) => true,
      (TafsirSegmentKind.ayah, TafsirSegmentKind.commentary) => false,
      _ => false,
    };

    return needsGap ? ' ' : null;
  }

  static bool _isRenderablePoetry(TafsirTextSegment segment) {
    if (segment.kind != TafsirSegmentKind.poetry) return false;

    final hemistichs = segment.poetryHemistichs;
    if (hemistichs == null || hemistichs.length < 2) return false;

    return hemistichs.every((hemistich) => hemistich.trim().isNotEmpty);
  }

  static List<InlineSpan> _spansForSegment(
    TafsirTextSegment segment,
    _TafsirTextStyles styles, {
    TafsirTextSegment? next,
  }) {
    return switch (segment.kind) {
      TafsirSegmentKind.commentary => _CommentaryInlineSpans.build(
        segment.text,
        styles: styles,
      ),
      TafsirSegmentKind.ayah => [
        TextSpan(
          text: _ayahDisplayText(segment.text, next: next),
          style: styles.ayah,
        ),
      ],
      TafsirSegmentKind.qiraatQuote => [
        TextSpan(text: segment.text, style: styles.quote),
      ],
      TafsirSegmentKind.reference => [
        TextSpan(text: segment.text, style: styles.reference),
      ],
      TafsirSegmentKind.gloss => [
        TextSpan(text: segment.text, style: styles.gloss),
      ],
      TafsirSegmentKind.crossReference => [
        TextSpan(text: segment.text, style: styles.crossReference),
      ],
      TafsirSegmentKind.poetry => const [],
    };
  }

  /// Inserts a gap before following commentary when the source markup omits it.
  static String _ayahDisplayText(
    String text, {
    TafsirTextSegment? next,
  }) {
    if (next?.kind != TafsirSegmentKind.commentary) return text;

    final following = next!.text;
    if (following.isEmpty) return text;

    final first = following.characters.first;
    if (first == ' ' || first == '\n') {
      return text;
    }

    return '$text ';
  }
}

class _TruncationFootnote extends StatelessWidget {
  const _TruncationFootnote({
    required this.colors,
    required this.typography,
  });

  final FColors colors;
  final FTypography typography;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            FLucideIcons.triangleAlert,
            size: 14,
            color: colors.mutedForeground,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              context.l10n.tafsirTextMayBeIncomplete,
              style: typography.xs.copyWith(
                color: colors.mutedForeground,
                fontStyle: FontStyle.italic,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Two hemistichs laid out in a responsive diwan-style row.
class _TafsirPoetryRow extends StatelessWidget {
  const _TafsirPoetryRow({
    required this.hemistichs,
    required this.style,
  });

  final List<String> hemistichs;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.secondary.withAlpha(theme.isDark ? 40 : 55),
        borderRadius: theme.radii.sm,
        border: Border.all(color: colors.border.withAlpha(90)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ScopedSelectableText(
                hemistichs[0],
                style: style.copyWith(fontStyle: FontStyle.italic),
                textAlign: TextAlign.start,
                textDirection: TextDirection.rtl,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: ScopedSelectableText(
                hemistichs[1],
                style: style.copyWith(fontStyle: FontStyle.italic),
                textAlign: TextAlign.end,
                textDirection: TextDirection.rtl,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

@immutable
class _TafsirTextStyles {
  const _TafsirTextStyles({
    required this.prose,
    required this.ayah,
    required this.quote,
    required this.reference,
    required this.gloss,
    required this.crossReference,
    required this.qawlLead,
    required this.scholarLead,
    required this.selectionStrut,
  });

  factory _TafsirTextStyles.from({
    required TextStyle baseStyle,
    required FColors colors,
    required bool isDark,
  }) {
    final fontSize = baseStyle.fontSize ?? 14;
    final ayahColor = isDark
        ? const Color(0xFF4ADE80)
        : const Color(0xFF15803D);
    const proseHeight = 1.85;

    return _TafsirTextStyles(
      prose: baseStyle.copyWith(
        fontFamily: FontFamily.uthmanTN,
        height: proseHeight,
      ),
      selectionStrut: StrutStyle(
        fontFamily: FontFamily.uthmanTN,
        fontSize: fontSize,
        height: proseHeight,
        forceStrutHeight: true,
        leadingDistribution: TextLeadingDistribution.even,
      ),
      ayah: baseStyle.copyWith(
        fontFamily: FontFamily.uthmanicHafs,
        fontSize: fontSize * 1.08,
        height: 1.9,
        color: ayahColor,
        fontWeight: FontWeight.w500,
      ),
      quote: baseStyle.copyWith(
        fontFamily: FontFamily.uthmanTN,
        fontWeight: FontWeight.w600,
        color: colors.foreground,
        height: 1.85,
      ),
      reference: baseStyle.copyWith(
        fontFamily: FontFamily.iBMPlexSansArabic,
        fontSize: fontSize * 0.88,
        color: colors.mutedForeground,
        height: 1.55,
      ),
      gloss: baseStyle.copyWith(
        fontFamily: FontFamily.uthmanTN,
        fontWeight: FontWeight.w600,
        color: Color.lerp(colors.foreground, colors.primary, 0.25),
        height: 1.85,
      ),
      crossReference: baseStyle.copyWith(
        fontFamily: FontFamily.iBMPlexSansArabic,
        fontSize: fontSize * 0.78,
        color: colors.mutedForeground,
        height: 1.6,
      ),
      qawlLead: baseStyle.copyWith(
        fontFamily: FontFamily.uthmanTN,
        fontWeight: FontWeight.w700,
        color: colors.primary,
        height: 1.85,
      ),
      scholarLead: baseStyle.copyWith(
        fontFamily: FontFamily.uthmanTN,
        fontWeight: FontWeight.w600,
        color: Color.lerp(colors.foreground, colors.primary, 0.35),
        height: 1.85,
      ),
    );
  }

  final TextStyle prose;
  final TextStyle ayah;
  final TextStyle quote;
  final TextStyle reference;
  final TextStyle gloss;
  final TextStyle crossReference;
  final TextStyle qawlLead;
  final TextStyle scholarLead;
  final StrutStyle selectionStrut;
}

abstract final class _CommentaryInlineSpans {
  /// Matches qawl-lead phrases including attached Arabic prefix particles.
  static final qawlLeadPrefix = RegExp(
    r'^(?:[لوبفك]\s+|[لوبفك])?(?:قال\s+الله\s+تعالى|قول(?:ه|ها|هم)?(?:\s+تعالى)?):',
  );

  static final _qawlLeadPattern = RegExp(
    r'(?<=^|\s)(?:[لوبفك]\s+|[لوبفك])?(?:قال\s+الله\s+تعالى|قول(?:ه|ها|هم)?(?:\s+تعالى)?):\s*',
  );
  static final _scholarLeadPattern = RegExp(
    r'(?<![\u0600-\u06FF])(?:'
    r'أي:\s*|'
    r'يقال\s+في\s+[^:]+:\s*|'
    r'قال\s+الشاعر\b|'
    r'قال\s+(?!الله\s+تعالى)[^:]+:\s*'
    ')',
  );

  static List<InlineSpan> build(
    String input, {
    required _TafsirTextStyles styles,
  }) {
    if (input.isEmpty) return const [];

    final spans = <InlineSpan>[];
    var cursor = 0;

    while (cursor < input.length) {
      final next = _nextSpecialMatch(input, cursor);
      if (next == null) {
        final tail = input.substring(cursor);
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

      spans.add(
        TextSpan(
          text: next.text,
          style: switch (next.kind) {
            _InlineKind.qawlLead => styles.qawlLead,
            _InlineKind.scholarLead => styles.scholarLead,
          },
        ),
      );
      cursor = next.end;
    }

    return spans;
  }

  static _InlineMatch? _nextSpecialMatch(String input, int start) {
    _InlineMatch? best;

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

enum _InlineKind { qawlLead, scholarLead }

@immutable
class _InlineMatch {
  const _InlineMatch({
    required this.kind,
    required this.start,
    required this.end,
    required this.text,
  });

  final _InlineKind kind;
  final int start;
  final int end;
  final String text;
}
