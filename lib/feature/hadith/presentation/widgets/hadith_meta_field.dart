import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/theme/theme.dart';

/// Layout for a hadith metadata label/value pair.
enum HadithMetaFieldLayout {
  /// Label and value on one line (result cards).
  inline,

  /// Label above value (detail pane).
  stacked,
}

/// Shared metadata row for hadith narrator, source, grade, etc.
class HadithMetaField extends StatelessWidget {
  /// Creates a metadata field.
  const new({
    required this.label,
    required this.value,
    this.layout = HadithMetaFieldLayout.stacked,
    super.key,
  });

  /// Field title (e.g. narrator, source).
  final String label;

  /// Field content.
  final String value;

  /// Inline single-line vs stacked multi-line presentation.
  final HadithMetaFieldLayout layout;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return switch (layout) {
      HadithMetaFieldLayout.inline => RichText(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style: theme.typography.body.sm.copyWith(
            color: theme.colors.secondaryForeground,
          ),
          children: [
            TextSpan(
              text: context.l10n.hadithFieldLabel(label),
              style: theme.typography.body.sm.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
      HadithMetaFieldLayout.stacked => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4,
          children: [
            Text(
              label,
              style: theme.typography.body.sm.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
            Text(
              value,
              style: theme.typography.body.md,
            ),
          ],
        ),
      ),
    };
  }
}
