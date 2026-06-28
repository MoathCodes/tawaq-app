import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/commentary/commentary_inline_run_builder.dart';
import 'package:tawaq/core/commentary/commentary_inline_spans.dart';
import 'package:tawaq/core/commentary/commentary_text_styles.dart';
import 'package:tawaq/core/hooks/hooks.dart';
import 'package:tawaq/core/layout/responsive.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/feature/quran/domain/models/tafsir_parse_result.dart';
import 'package:tawaq/feature/quran/domain/models/tafsir_source.dart';
import 'package:tawaq/feature/quran/domain/models/tafsir_text_segment.dart';
import 'package:tawaq/feature/quran/domain/services/tafsir_segment_repair.dart';
import 'package:tawaq/feature/quran/domain/services/tafsir_text_parser.dart';
import 'package:tawaq/theme/theme.dart';

/// Widget that renders tafsir text with proper font styling.
///
/// Supports Mouaser `<span class="aya">` markup and compact-database
/// `t1`–`t4` spans. Quranic snippets use Uthmanic Hafs with a green tone
/// matching Hisn study-sheet commentary styling.
class TafsirText extends HookWidget {
  /// Creates a tafsir text widget.
  const TafsirText({
    required this.baseStyle,
    this.parseResult,
    this.text,
    this.tafsirId,
    super.key,
  }) : assert(
         parseResult != null || text != null,
         'Provide either parseResult or text',
       );

  /// Pre-parsed segments from the tafsir parse cache provider.
  final TafsirParseResult? parseResult;

  /// Raw tafsir text for direct rendering (widget tests and fallbacks).
  final String? text;

  /// The base text style for the tafsir commentary.
  final TextStyle baseStyle;

  /// Active tafsir source for source-aware span classification.
  final TafsirId? tafsirId;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final isDark = theme.isDark;

    final styles = useCommentaryTextStyles(
      baseStyle: baseStyle,
      colors: colors,
      isDark: isDark,
      useUthmanTnProse: true,
    );

    final parsed = useMemoized(
      () =>
          parseResult ??
          TafsirTextParser.parse(text!, tafsirId: tafsirId),
      [parseResult, text, tafsirId],
    );

    final body = TafsirCommentaryBody(
      segments: parsed.segments,
      styles: styles,
    );

    if (!parsed.truncationReport.isLikelyTruncated) return body;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        body,
        _TruncationFootnote(
          colors: colors,
          typography: theme.typography,
        ),
      ],
    );
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
              style: typography.body.xs.copyWith(
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

/// Renders parsed tafsir segments as inline rich-text runs and poetry blocks.
class TafsirCommentaryBody extends HookWidget {
  /// Creates inline tafsir commentary from [segments].
  const TafsirCommentaryBody({
    required this.segments,
    required this.styles,
    super.key,
  });

  /// Parsed tafsir segments.
  final List<TafsirTextSegment> segments;

  /// Shared commentary styles (tafsir variant with UthmanTN prose).
  final CommentaryTextStyles styles;

  @override
  Widget build(BuildContext context) {
    return CommentaryStyleScope(
      styles: styles,
      child: _TafsirCommentaryBodyContent(segments: segments),
    );
  }

  /// Builds the commentary widget tree from [segments].
  ///
  /// [context] must be under a [CommentaryStyleScope].
  static Widget? buildBody(
    BuildContext context, {
    required List<TafsirTextSegment> segments,
  }) {
    if (segments.isEmpty) return null;

    final styles = CommentaryStyleScope.of(context);
    final children = <Widget>[];
    var inlineStart = 0;

    void flushInlineRun(int end) {
      if (inlineStart >= end) return;

      final spans = _buildInlineSpans(
        context: context,
        segments: segments,
        start: inlineStart,
        end: end,
      );
      if (spans.isEmpty) return;

      children.add(
        CommentaryInlineRunBuilder.richTextRun(
          spans: spans,
          styles: styles,
        ),
      );
    }

    for (var i = 0; i < segments.length; i++) {
      if (!_isRenderablePoetry(segments[i])) continue;

      flushInlineRun(i);

      final poetryRun = <List<String>>[];
      var j = i;
      while (j < segments.length && _isRenderablePoetry(segments[j])) {
        poetryRun.add(segments[j].poetryHemistichs!);
        j++;
      }

      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: _TafsirPoetryBlock(
            hemistichRuns: poetryRun,
            style: styles.prose,
          ),
        ),
      );

      inlineStart = j;
      i = j - 1;
    }

    flushInlineRun(segments.length);

    if (children.isEmpty) return null;
    if (children.length == 1) return children.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  static List<InlineSpan> _buildInlineSpans({
    required BuildContext context,
    required List<TafsirTextSegment> segments,
    required int start,
    required int end,
  }) {
    final styles = CommentaryStyleScope.of(context);
    final spans = <InlineSpan>[];
    TafsirTextSegment? previous;

    for (var i = start; i < end; i++) {
      final segment = segments[i];
      if (segment.kind == TafsirSegmentKind.poetry) continue;

      if (previous != null) {
        final gap = _gapBeforeSegment(previous, segment);
        if (gap != null) {
          spans.add(TextSpan(text: gap, style: styles.prose));
        }
      }

      final next = i + 1 < segments.length ? segments[i + 1] : null;
      spans.addAll(_spansForSegment(context, segment, next: next));
      previous = segment;
    }

    return spans;
  }

  static String? _gapBeforeSegment(
    TafsirTextSegment previous,
    TafsirTextSegment current,
  ) {
    final currentText = current.text;
    if (currentText.isEmpty) return null;

    if (TafsirSegmentRepair.isArabicPrefixParticle(previous.text) &&
        TafsirSegmentRepair.startsWithQawlLead(currentText)) {
      return null;
    }

    final currentFirst = currentText.characters.first;
    if (currentFirst == ' ' || currentFirst == '\n') return null;

    final previousText = previous.text;
    if (previousText.isNotEmpty) {
      final previousLast = previousText.characters.last;
      if (previousLast == ' ' || previousLast == '\n') return null;

      if (TafsirSegmentRepair.isArabicPrefixParticle(previousLast) &&
          TafsirSegmentRepair.startsWithQawlLead(currentText)) {
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
    BuildContext context,
    TafsirTextSegment segment, {
    TafsirTextSegment? next,
  }) {
    final styles = CommentaryStyleScope.of(context);
    return switch (segment.kind) {
      TafsirSegmentKind.commentary => CommentaryInlineSpans.build(
        context,
        segment.text,
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

class _TafsirPoetryBlock extends StatelessWidget {
  const _TafsirPoetryBlock({
    required this.hemistichRuns,
    required this.style,
  });

  final List<List<String>> hemistichRuns;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final poetryStyle = style.copyWith(fontStyle: FontStyle.italic);

    return LayoutBuilder(
      builder: (context, constraints) {
        final stackVertically =
            !isContainerAtLeast(context, constraints, FBreakpoint.sm);
        final spans = <InlineSpan>[];

        for (var runIndex = 0; runIndex < hemistichRuns.length; runIndex++) {
          if (runIndex > 0) {
            spans.add(const TextSpan(text: '\n\n'));
          }

          final hemistichs = hemistichRuns[runIndex];
          spans.add(TextSpan(text: hemistichs[0], style: poetryStyle));

          if (stackVertically) {
            spans.add(const TextSpan(text: '\n'));
          } else {
            spans.add(const TextSpan(text: '    '));
          }

          spans.add(TextSpan(text: hemistichs[1], style: poetryStyle));
        }

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
            child: ScopedSelectableRichText(
              TextSpan(style: poetryStyle, children: spans),
              textAlign: stackVertically ? TextAlign.start : TextAlign.justify,
            ),
          ),
        );
      },
    );
  }
}

class _TafsirCommentaryBodyContent extends HookWidget {
  const _TafsirCommentaryBodyContent({required this.segments});

  final List<TafsirTextSegment> segments;

  @override
  Widget build(BuildContext context) {
    final styles = CommentaryStyleScope.of(context);
    final body = useMemoized(
      () => TafsirCommentaryBody.buildBody(context, segments: segments),
      [
        segments,
        styles.prose,
        styles.ayah,
        styles.quote,
        styles.reference,
        styles.gloss,
        styles.crossReference,
        styles.selectionStrut,
      ],
    );

    return body ?? const SizedBox.shrink();
  }
}
