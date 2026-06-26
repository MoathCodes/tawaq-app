import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/theme/theme.dart';

/// Muted in-field label used by Quran header navigation selects.
Widget quranInlineSelectPrefix(BuildContext context, String label) {
  final theme = context.theme;
  final colors = theme.colors;

  return Padding(
    padding: const EdgeInsetsDirectional.only(
      start: AppSpacing.sm,
      end: AppSpacing.xs,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.typography.body.xs.copyWith(
            color: colors.mutedForeground,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        SizedBox(
          height: 16,
          child: VerticalDivider(
            width: 1,
            thickness: 1,
            color: colors.border.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
      ],
    ),
  );
}

/// [FSelect] prefix builder for header navigation fields.
FFieldIconBuilder<FTextFieldStyle> quranInlineSelectPrefixBuilder(
  String label,
) {
  return (context, style, states) => quranInlineSelectPrefix(context, label);
}
