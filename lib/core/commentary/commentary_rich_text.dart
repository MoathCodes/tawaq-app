import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tawaq/core/commentary/commentary_inline_spans.dart';
import 'package:tawaq/core/commentary/commentary_text_styles.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';

/// Rich text renderer for commentary prose with inline pattern styling.
class CommentaryRichText extends HookWidget {
  /// Creates formatted commentary rich text.
  ///
  /// Requires a [CommentaryStyleScope] ancestor, or pass [styles] to supply
  /// one.
  const CommentaryRichText({
    required this.text,
    this.styles,
    this.textAlign = TextAlign.start,
    this.listNumber,
    this.emphasizeQawl = false,
    super.key,
  });

  /// Raw commentary prose.
  final String text;

  /// Optional styles; when omitted, reads from [CommentaryStyleScope].
  final CommentaryTextStyles? styles;

  /// Paragraph alignment.
  final TextAlign textAlign;

  /// Optional numbered-list prefix.
  final int? listNumber;

  /// Whether to emphasize a leading `قوله:` marker.
  final bool emphasizeQawl;

  @override
  Widget build(BuildContext context) {
    final body = _CommentaryRichTextBody(
      text: text,
      textAlign: textAlign,
      listNumber: listNumber,
      emphasizeQawl: emphasizeQawl,
    );

    if (styles case final resolved?) {
      return CommentaryStyleScope(styles: resolved, child: body);
    }
    return body;
  }
}

class _CommentaryRichTextBody extends HookWidget {
  const _CommentaryRichTextBody({
    required this.text,
    required this.textAlign,
    required this.listNumber,
    required this.emphasizeQawl,
  });

  final String text;
  final TextAlign textAlign;
  final int? listNumber;
  final bool emphasizeQawl;

  static final _spanCache = <_SpanCacheKey, List<InlineSpan>>{};
  static const _maxSpanCacheEntries = 256;

  @override
  Widget build(BuildContext context) {
    final styles = CommentaryStyleScope.of(context);
    final spans = useMemoized(
      () => _getOrBuildSpans(
        context,
        text,
        styles: styles,
        emphasizeQawl: emphasizeQawl,
        listNumber: listNumber,
      ),
      [text, styles, emphasizeQawl, listNumber],
    );
    if (spans.isEmpty) return const SizedBox.shrink();

    return ScopedSelectableRichText(
      TextSpan(children: spans),
      textAlign: textAlign,
    );
  }

  static List<InlineSpan> _getOrBuildSpans(
    BuildContext context,
    String input, {
    required CommentaryTextStyles styles,
    required bool emphasizeQawl,
    required int? listNumber,
  }) {
    final key = _SpanCacheKey(
      text: input,
      stylesId: identityHashCode(styles),
      emphasizeQawl: emphasizeQawl,
      listNumber: listNumber,
    );
    final cached = _spanCache[key];
    if (cached != null) return cached;

    final spans = _computeSpans(
      context,
      input,
      emphasizeQawl: emphasizeQawl,
      listNumber: listNumber,
    );
    if (_spanCache.length >= _maxSpanCacheEntries) {
      _spanCache.clear();
    }
    _spanCache[key] = spans;
    return spans;
  }

  static List<InlineSpan> _computeSpans(
    BuildContext context,
    String input, {
    required bool emphasizeQawl,
    required int? listNumber,
  }) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return const [];

    final styles = CommentaryStyleScope.of(context);
    final spans = <InlineSpan>[];

    if (listNumber != null) {
      spans.add(
        TextSpan(
          text: '$listNumber — ',
          style: styles.listMarker,
        ),
      );
    }

    spans.addAll(
      CommentaryInlineSpans.build(
        context,
        trimmed,
        emphasizeQawl: emphasizeQawl,
      ),
    );

    return spans;
  }
}

@immutable
class _SpanCacheKey {
  const _SpanCacheKey({
    required this.text,
    required this.stylesId,
    required this.emphasizeQawl,
    required this.listNumber,
  });

  final String text;
  final int stylesId;
  final bool emphasizeQawl;
  final int? listNumber;

  @override
  bool operator ==(Object other) {
    return other is _SpanCacheKey &&
        other.text == text &&
        other.stylesId == stylesId &&
        other.emphasizeQawl == emphasizeQawl &&
        other.listNumber == listNumber;
  }

  @override
  int get hashCode => Object.hash(text, stylesId, emphasizeQawl, listNumber);
}
