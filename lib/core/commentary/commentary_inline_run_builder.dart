import 'package:flutter/material.dart';
import 'package:tawaq/core/commentary/commentary_text_styles.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/theme/theme.dart';

/// Shared helpers for grouping inline commentary spans into selectable runs.
abstract final class CommentaryInlineRunBuilder {
  /// Renders [spans] as one [ScopedSelectableRichText] run.
  static Widget richTextRun({
    required List<InlineSpan> spans,
    required CommentaryTextStyles styles,
    TextAlign textAlign = TextAlign.start,
  }) {
    return ScopedSelectableRichText(
      TextSpan(style: styles.prose, children: spans),
      textAlign: textAlign,
      strutStyle: styles.selectionStrut,
    );
  }

  /// Builds a widget tree from pre-grouped span runs.
  static Widget? columnFromSpanRuns({
    required List<List<InlineSpan>> runs,
    required CommentaryTextStyles styles,
    TextAlign textAlign = TextAlign.start,
  }) {
    final children = <Widget>[];

    for (final spans in runs) {
      if (spans.isEmpty) continue;

      if (children.isNotEmpty) {
        children.add(const SizedBox(height: AppSpacing.sm));
      }

      children.add(
        richTextRun(spans: spans, styles: styles, textAlign: textAlign),
      );
    }

    if (children.isEmpty) return null;
    if (children.length == 1) return children.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  /// Groups contiguous segments into inline span runs separated by paragraph
  /// boundaries reported by [startsNewParagraph].
  static List<List<InlineSpan>> collectSpanRuns<S>({
    required List<S> segments,
    required bool Function(S segment, int index) startsNewParagraph,
    required List<InlineSpan> Function(List<S> segments, int start, int end)
    buildSpans,
    bool Function(S segment)? skipSegment,
  }) {
    final runs = <List<InlineSpan>>[];
    var inlineStart = 0;

    void flush(int end) {
      if (inlineStart >= end) return;

      final spans = buildSpans(segments, inlineStart, end);
      if (spans.isNotEmpty) {
        runs.add(spans);
      }
    }

    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      if (skipSegment?.call(segment) ?? false) {
        continue;
      }

      if (startsNewParagraph(segment, i)) {
        flush(i);
        inlineStart = i;
      }
    }

    flush(segments.length);
    return runs;
  }
}
