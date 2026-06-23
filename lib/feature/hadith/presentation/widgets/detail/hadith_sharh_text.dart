import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/hooks/hooks.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/hadith/domain/services/hadith_sharh_parser.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/detail/hadith_sharh_commentary_body.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/detail/hadith_sharh_metadata_card.dart';
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
    final parsed = useMemoized(() => HadithSharhParser.parse(text), [text]);

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
          HadithSharhMetadataCard(
            fields: parsed.metadataFields,
            matnPrefix: zones.matnPrefix,
            baseStyle: baseStyle,
          ),
        if (zones.commentary.isNotEmpty)
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow =
                  constraints.maxWidth < context.theme.breakpoints.sm;
              return HadithSharhCommentaryBody(
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
