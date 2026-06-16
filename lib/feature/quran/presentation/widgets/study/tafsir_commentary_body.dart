import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/commentary/commentary_inline_spans.dart';
import 'package:tawaq/core/commentary/commentary_text_styles.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/feature/quran/domain/models/tafsir_text_segment.dart';
import 'package:tawaq/feature/quran/domain/services/tafsir_segment_repair.dart';
import 'package:tawaq/theme/theme.dart';

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

  /// Inserts a space between adjacent inline segments when markup omits it.
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final stackVertically = constraints.maxWidth < theme.breakpoints.sm;

        Widget buildHemistich(String text, TextAlign align) {
          return ScopedSelectableText(
            text,
            style: style.copyWith(fontStyle: FontStyle.italic),
            textAlign: align,
            textDirection: TextDirection.rtl,
          );
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
            child: stackVertically
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      buildHemistich(hemistichs[0], TextAlign.start),
                      const SizedBox(height: AppSpacing.sm),
                      buildHemistich(hemistichs[1], TextAlign.end),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: buildHemistich(hemistichs[0], TextAlign.start),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: buildHemistich(hemistichs[1], TextAlign.end),
                      ),
                    ],
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
