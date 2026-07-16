import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/commentary/commentary_inline_spans.dart';
import 'package:tawaq/core/commentary/commentary_text_styles.dart';
import 'package:tawaq/core/hooks/hooks.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/custom_cards.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_sharh_models.dart';
import 'package:tawaq/feature/hadith/domain/services/hadith_sharh_segment_tokenizer.dart';
import 'package:tawaq/theme/theme.dart';

/// Renders Dorar hadith sharh with zone-aware metadata and segment styling.
class HadithSharhText extends HookWidget {
  /// Creates formatted sharh text.
  const HadithSharhText({
    required this.text,
    this.textAlign = TextAlign.justify,
    super.key,
  });

  /// Raw sharh string from Dorar cache/API.
  final String text;

  /// Paragraph alignment.
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final parsed = useMemoized(() => parseHadithSharh(text), [text]);

    final theme = context.theme;
    final colors = theme.colors;
    final isDark = theme.isDark;
    final baseStyle = theme.typography.body.sm.copyWith(height: 1.8);
    final styles = useCommentaryTextStyles(
      baseStyle: baseStyle,
      colors: colors,
      isDark: isDark,
    );

    final zones = parsed.zones;
    if (zones.commentary.isEmpty && !parsed.hasMetadataContent) {
      return Text(
        context.l10n.noDataAvailable,
        style: baseStyle.copyWith(color: colors.mutedForeground),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
        if (parsed.hasMetadataContent)
          _HadithSharhMetadataCard(
            fields: parsed.metadataFields,
            matnPrefix: zones.matnPrefix,
            baseStyle: baseStyle,
          ),
        if (zones.commentary.isNotEmpty)
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow =
                  constraints.maxWidth < context.theme.breakpoints.sm;
              return _HadithSharhCommentaryBody(
                segments: parsed.segments,
                styles: styles,
                textAlign: narrow ? TextAlign.start : textAlign,
              );
            },
          ),
      ],
    );
  }
}

class _HadithSharhMetadataCard extends StatelessWidget {
  const _HadithSharhMetadataCard({
    required this.fields,
    required this.baseStyle,
    this.matnPrefix,
  });

  final HadithSharhMetadataFields fields;
  final String? matnPrefix;
  final TextStyle baseStyle;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final prefix = matnPrefix?.trim();

    if ((prefix == null || prefix.isEmpty) && !fields.hasAny) {
      return const SizedBox.shrink();
    }

    final labelStyle = theme.typography.body.sm.copyWith(
      color: colors.mutedForeground,
    );
    final valueStyle = theme.typography.body.md.copyWith(
      fontFamily: baseStyle.fontFamily,
      height: 1.55,
    );
    final citationStyle = theme.typography.body.sm.copyWith(
      fontFamily: baseStyle.fontFamily,
      color: colors.mutedForeground,
      height: 1.55,
    );

    return StaticCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.md,
        children: [
          if (prefix case final matn? when matn.isNotEmpty)
            _MatnPrefixQuote(
              text: matn,
              colors: colors,
              style: baseStyle.copyWith(
                color: colors.mutedForeground,
                height: 1.7,
              ),
              radii: theme.radii.sm,
            ),
          for (final entry in fields.populatedEntries)
            _MetadataRow(
              label: entry.label.arabicLabel,
              value: entry.value,
              labelStyle: labelStyle,
              valueStyle: entry.label == HadithSharhMetadataLabel.takhrij
                  ? citationStyle
                  : valueStyle,
              isolateNumerals:
                  entry.label == HadithSharhMetadataLabel.takhrij,
            ),
        ],
      ),
    );
  }
}

class _MatnPrefixQuote extends StatelessWidget {
  const _MatnPrefixQuote({
    required this.text,
    required this.colors,
    required this.style,
    required this.radii,
  });

  final String text;
  final FColors colors;
  final TextStyle style;
  final BorderRadius radii;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.md,
        top: AppSpacing.sm,
        bottom: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.secondary.withValues(alpha: 0.45),
        border: BorderDirectional(
          start: BorderSide(
            color: colors.border.withValues(alpha: 0.9),
            width: 3,
          ),
        ),
        borderRadius: BorderRadiusDirectional.only(
          topStart: radii.topLeft,
          bottomStart: radii.bottomLeft,
        ),
      ),
      child: ScopedSelectableText(
        text,
        style: style,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.justify,
      ),
    );
  }
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({
    required this.label,
    required this.value,
    required this.labelStyle,
    required this.valueStyle,
    required this.isolateNumerals,
  });

  final String label;
  final String value;
  final TextStyle labelStyle;
  final TextStyle valueStyle;
  final bool isolateNumerals;

  @override
  Widget build(BuildContext context) {
    final displayValue = isolateNumerals ? isolateLtrNumerals(value) : value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.xs,
      children: [
        Text(label, style: labelStyle),
        ScopedSelectableText(
          displayValue,
          style: valueStyle,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.start,
        ),
      ],
    );
  }
}

/// Renders tokenized sharh segments as inline rich-text runs.
///
/// Adjacent segments share one selectable rich-text run so gloss markers
/// (`أي:`), quotes, and prose flow on the same line and selection crosses
/// style boundaries. [Column] breaks appear only at paragraph boundaries
/// (section leads and blank-line pivots).
class _HadithSharhCommentaryBody extends HookWidget {
  const _HadithSharhCommentaryBody({
    required this.segments,
    required this.styles,
    required this.textAlign,
  });

  final List<HadithSharhSegment> segments;
  final CommentaryTextStyles styles;
  final TextAlign textAlign;

  static final _paragraphBreak = RegExp(r'^\s*\n\s*\n');

  @override
  Widget build(BuildContext context) {
    final body = useMemoized(
      () {
        if (segments.isEmpty) return null;

        final runs = CommentaryInlineRunBuilder.collectSpanRuns(
          segments: segments,
          startsNewParagraph: _startsNewParagraph,
          buildSpans:
              (segments, start, end) =>
                  _buildInlineSpans(
                    segments: segments,
                    start: start,
                    end: end,
                    styles: styles,
                  ),
        );

        return CommentaryInlineRunBuilder.columnFromSpanRuns(
          runs: runs,
          styles: styles,
          textAlign: textAlign,
        );
      },
      [segments, styles, textAlign],
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

  static List<InlineSpan> _buildInlineSpans({
    required List<HadithSharhSegment> segments,
    required int start,
    required int end,
    required CommentaryTextStyles styles,
  }) {
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
