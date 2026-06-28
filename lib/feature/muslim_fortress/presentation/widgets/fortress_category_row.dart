import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_category.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_locale_extensions.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/fortress_category_ui.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/theme.dart';

/// Shared category row content: icon, title, meta, optional trailing widget.
class FortressCategoryRow extends StatelessWidget {
  /// Creates a category row.
  const FortressCategoryRow({
    required this.category,
    required this.l10n,
    this.compact = false,
    this.selected = false,
    this.trailing,
    this.icon,
    super.key,
  });

  final FortressCategory category;
  final AppLocalizations l10n;
  final bool compact;
  final bool selected;
  final Widget? trailing;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final rowIcon = icon ?? category.icon;
    final accent = selected ? colors.primary : colors.mutedForeground;

    return Row(
      children: [
        Icon(
          rowIcon,
          size: compact ? 18 : 20,
          color: selected ? colors.primary : accent,
        ),
        SizedBox(width: compact ? AppSpacing.sm : AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category.title,
                style: theme.typography.body.md.copyWith(
                  fontWeight: FontWeight.w600,
                  color: selected ? colors.primary : colors.foreground,
                ),
                maxLines: compact ? 2 : null,
                overflow: compact ? TextOverflow.ellipsis : null,
              ),
              const SizedBox(height: 2),
              Text(
                fortressRecurrenceLabel(category.recurrence, l10n),
                style: theme.typography.body.sm.copyWith(
                  color: selected
                      ? colors.primary.withAlpha(150)
                      : colors.mutedForeground,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (!compact) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.fortressSupplicationCount(category.supplicationCount),
                  style: theme.typography.body.xs.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.sm),
          trailing!,
        ],
      ],
    );
  }
}
