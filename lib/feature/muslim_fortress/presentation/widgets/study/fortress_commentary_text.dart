import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/commentary/commentary_rich_text.dart';
import 'package:tawaq/core/commentary/commentary_text_styles.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_commentary_block.dart';
import 'package:tawaq/feature/muslim_fortress/domain/services/fortress_commentary_parser.dart';
import 'package:tawaq/gen/fonts.gen.dart' show FontFamily;
import 'package:tawaq/theme/theme.dart';

/// Renders Hisn sharh/commentary with Uthmanic ayahs and readable prose.
///
/// Numbered explanations flow as plain text; `/55 … /55` source markers become
/// footnote lines; Quranic snippets in `﴿…﴾` use [FontFamily.uthmanicHafs]
/// with a distinct green tone and a muted surah/ayah reference beside them.
class FortressCommentaryText extends HookWidget {
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
    if (text.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final colors = context.theme.colors;
    final isDark = context.theme.isDark;
    final styles = useMemoized(
      () => CommentaryTextStyles.from(
        baseStyle: baseStyle,
        colors: colors,
        isDark: isDark,
      ),
      [baseStyle, colors, isDark],
    );
    final blocks = useMemoized(
      () => FortressCommentaryParser.parse(text),
      [text],
    );

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

class _CommentaryBlockView extends StatelessWidget {
  const _CommentaryBlockView({
    required this.block,
    required this.styles,
    required this.colors,
    required this.textAlign,
  });

  final FortressCommentaryBlock block;
  final CommentaryTextStyles styles;
  final FColors colors;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CommentaryRichText(
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
              text,
              style: style,
              textDirection: TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }
}
