import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/mouse_click.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_category.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_locale_extensions.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/fortress_a11y.dart';
import 'package:tawaq/theme/theme.dart';

class FortressCategoryListTile extends StatelessWidget {
  const FortressCategoryListTile({
    required this.category,
    required this.isSelected,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFavorite,
    super.key,
  });

  final FortressCategory category;
  final bool isSelected;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    final bgColor = isSelected
        ? theme.colors.primary.withAlpha(20)
        : Colors.transparent;
    final borderColor = isSelected
        ? theme.colors.primary
        : theme.colors.border.withAlpha(80);

    final l10n = context.l10n;

    return MouseClick(
      onClick: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: theme.radii.md,
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                button: true,
                selected: isSelected,
                label: category.title,
                child: ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.title,
                        style: theme.typography.md.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? theme.colors.primary
                              : theme.colors.foreground,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        fortressRecurrenceLabel(category.recurrence, l10n),
                        style: theme.typography.sm.copyWith(
                          color: isSelected
                              ? theme.colors.primary.withAlpha(150)
                              : theme.colors.mutedForeground,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.fortressSupplicationCount(
                          category.supplicationCount,
                        ),
                        style: theme.typography.xs.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Semantics(
              button: true,
              label: l10n.fortressFavorites,
              child: ExcludeSemantics(
                child: MouseClick(
                  onClick: onToggleFavorite,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    child: Icon(
                      FLucideIcons.bookmark,
                      size: 18,
                      color: isFavorite
                          ? theme.colors.primary
                          : theme.colors.mutedForeground,
                      fill: isFavorite ? 1.0 : 0.0,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FortressEmptySidePanelState extends StatelessWidget {
  const FortressEmptySidePanelState({required this.isFavoritesTab, super.key});

  final bool isFavoritesTab;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = context.l10n;

    return Semantics(
      label: FortressA11y.sidebarEmptyLabel(
        l10n,
        favorites: isFavoritesTab,
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isFavoritesTab ? FLucideIcons.bookmark : FLucideIcons.searchX,
                size: 40,
                color: theme.colors.mutedForeground.withAlpha(120),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                isFavoritesTab
                    ? l10n.fortressEmptyFavoritesTitle
                    : l10n.fortressEmptySearchTitle,
                style: theme.typography.md.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colors.foreground,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                isFavoritesTab
                    ? l10n.fortressEmptyFavoritesHint
                    : l10n.fortressEmptySearchHint,
                style: theme.typography.sm.copyWith(
                  color: theme.colors.mutedForeground,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
