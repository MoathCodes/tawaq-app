import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/commentary/commentary_inline_spans.dart';
import 'package:tawaq/core/widgets/custom_cards.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_sharh_metadata_fields.dart';
import 'package:tawaq/theme/theme.dart';

/// Compact metadata card for Dorar sharh header fields.
class HadithSharhMetadataCard extends StatelessWidget {
  /// Creates a sharh metadata card.
  const HadithSharhMetadataCard({
    required this.fields,
    required this.baseStyle,
    this.matnPrefix,
    super.key,
  });

  /// Parsed metadata header fields.
  final HadithSharhMetadataFields fields;

  /// Matn text duplicated before the metadata block in Dorar sharh.
  final String? matnPrefix;

  /// Base text style.
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
