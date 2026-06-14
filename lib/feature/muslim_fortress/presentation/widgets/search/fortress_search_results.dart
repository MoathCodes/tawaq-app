import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/mouse_click.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_category.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_locale_extensions.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_search_results.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/fortress_category_ui.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/fortress_a11y.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/reading/fortress_focus_reading.dart';
import 'package:tawaq/theme/theme.dart';

/// Called when the user selects a title (chapter) search result.
typedef FortressSearchTitleSelected =
    void Function(
      FortressCategory category,
    );

/// Called when the user selects a content search result.
typedef FortressSearchContentSelected =
    void Function(
      FortressSearchContentHit hit,
    );

/// Displays global Hisn search results for titles and dhikr contents.
class FortressSearchResultsPane extends StatelessWidget {
  /// Creates a search results pane.
  const FortressSearchResultsPane({
    required this.results,
    required this.query,
    required this.onSelectTitle,
    required this.onSelectContent,
    super.key,
  });

  /// Search payload from the fortress search-results provider.
  final FortressSearchResults results;

  /// Active query string (for empty-state copy).
  final String query;

  /// Opens the selected chapter.
  final FortressSearchTitleSelected onSelectTitle;

  /// Opens the chapter and focuses the selected dhikr.
  final FortressSearchContentSelected onSelectContent;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final l10n = context.l10n;

    if (results.isEmpty) {
      return Semantics(
        label: FortressA11y.searchEmptyLabel(l10n, query),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                FLucideIcons.searchX,
                size: 48,
                color: colors.mutedForeground.withAlpha(120),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.fortressNoSearchResults,
                style: theme.typography.lg.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '"$query"',
                style: theme.typography.sm.copyWith(
                  color: colors.mutedForeground,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kFortressReadingMaxWidth),
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
          children: [
        if (results.titles.isNotEmpty) ...[
          _SectionHeader(
            icon: FLucideIcons.folderOpen,
            title: l10n.fortressSearchTitles,
            count: results.totalTitles,
          ),
          const SizedBox(height: AppSpacing.md),
          for (final category in results.titles) ...[
            _TitleResultTile(
              category: category,
              onTap: () => onSelectTitle(category),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.xl),
        ],
        if (results.contents.isNotEmpty) ...[
          _SectionHeader(
            icon: FLucideIcons.textSearch,
            title: l10n.fortressSearchContents,
            count: results.totalContents,
          ),
          const SizedBox(height: AppSpacing.md),
          for (final hit in results.contents) ...[
            _ContentResultTile(
              hit: hit,
              onTap: () => onSelectContent(hit),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.count,
  });

  final IconData icon;
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Semantics(
      header: true,
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colors.primary),
          const SizedBox(width: AppSpacing.sm),
          Text(
            title,
            style: theme.typography.lg.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: AppSpacing.sm),
          FBadge(child: Text('$count')),
        ],
      ),
    );
  }
}

class _TitleResultTile extends StatelessWidget {
  const _TitleResultTile({
    required this.category,
    required this.onTap,
  });

  final FortressCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = context.l10n;

    return MouseClick(
      onClick: onTap,
      semanticsLabel: category.title,
      child: FortressExcludeDecorative(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: theme.colors.secondary.withAlpha(80),
            borderRadius: theme.radii.md,
            border: Border.all(color: theme.colors.border),
          ),
          child: Row(
            children: [
              Icon(category.icon, color: theme.colors.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.title,
                      style: theme.typography.md.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${fortressRecurrenceLabel(category.recurrence, l10n)} · ${l10n.fortressSupplicationCount(category.supplicationCount)}',
                      style: theme.typography.xs.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                FLucideIcons.chevronLeft,
                size: 16,
                color: theme.colors.mutedForeground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContentResultTile extends StatelessWidget {
  const _ContentResultTile({
    required this.hit,
    required this.onTap,
  });

  final FortressSearchContentHit hit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = context.l10n;
    final item = hit.item;

    return MouseClick(
      onClick: onTap,
      semanticsLabel: '${hit.categoryTitle}. ${item.text}',
      child: FortressExcludeDecorative(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: theme.radii.md,
            border: Border.all(color: theme.colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      hit.categoryTitle,
                      style: theme.typography.xs.copyWith(
                        color: theme.colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (item.hasCommentary)
                    FBadge(
                      variant: .secondary,
                      child: Text(l10n.fortressSharh),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                item.text,
                style: theme.typography.sm.copyWith(height: 1.6),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
