import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_judgment.dart';
import 'package:tawaq/theme/theme.dart';

/// Layout for a hadith metadata label/value pair.
enum HadithMetaFieldLayout {
  /// Label and value on one line (result cards).
  inline,

  /// Label above value (detail pane).
  stacked,

  /// A compact reader row with distinct label and value.
  row,
}

/// Shared metadata row for hadith narrator, source, grade, etc.
class HadithMetaField extends StatelessWidget {
  /// Creates a metadata field.
  const new({
    required this.label,
    required this.value,
    this.layout = HadithMetaFieldLayout.stacked,
    this.fontSize,
    super.key,
  });

  /// Field title (e.g. narrator, source).
  final String label;

  /// Field content.
  final String value;

  /// Inline single-line vs stacked multi-line presentation.
  final HadithMetaFieldLayout layout;

  /// Export size independent of screen typography.
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    if (!hasHadithMetadata(value)) return const SizedBox.shrink();

    return switch (layout) {
      HadithMetaFieldLayout.inline => RichText(
        text: TextSpan(
          style: theme.typography.body.sm.copyWith(
            fontSize: fontSize,
            color: theme.colors.secondaryForeground,
          ),
          children: [
            TextSpan(
              text: '${context.l10n.hadithFieldLabel(label)} ',
              style: theme.typography.body.sm.copyWith(
                fontSize: fontSize,
                color: theme.colors.mutedForeground,
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
      HadithMetaFieldLayout.row => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.typography.body.sm.copyWith(
                fontSize: fontSize,
                color: theme.colors.mutedForeground,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: theme.typography.body.sm.copyWith(fontSize: fontSize),
              ),
            ),
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
                fontSize: fontSize,
                color: theme.colors.mutedForeground,
              ),
            ),
            Text(
              value,
              style: theme.typography.body.md.copyWith(fontSize: fontSize),
            ),
          ],
        ),
      ),
    };
  }
}
