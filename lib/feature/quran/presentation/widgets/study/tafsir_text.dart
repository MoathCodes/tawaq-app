import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/hooks/hooks.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/quran/domain/models/tafsir_parse_result.dart';
import 'package:tawaq/feature/quran/domain/models/tafsir_source.dart';
import 'package:tawaq/feature/quran/domain/services/tafsir_text_parser.dart';
import 'package:tawaq/feature/quran/presentation/widgets/study/tafsir_commentary_body.dart';
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
