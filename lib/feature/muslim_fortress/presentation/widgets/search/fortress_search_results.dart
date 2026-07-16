import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/custom_cards.dart';
import 'package:tawaq/core/widgets/empty_state_panel.dart';
import 'package:tawaq/core/widgets/mouse_click.dart';
import 'package:tawaq/feature/muslim_fortress/data/repository/fortress_repository.dart';
import 'package:tawaq/feature/muslim_fortress/domain/fortress_models.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_search_results.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/fortress_layout.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/provider/muslim_fortress_provider.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/fortress_a11y.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/fortress_category_row.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/theme.dart';

/// Displays global Hisn search results for titles and dhikr contents.
class FortressSearchResultsPane extends ConsumerWidget {
  /// Creates a search results pane.
  const FortressSearchResultsPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(muslimFortressSearchQueryProvider);
    final repositoryAsync = ref.watch(fortressRepositoryProvider);

    final l10n = context.l10n;

    return repositoryAsync.when(
      data: (repository) => _FortressSearchResultsBody(
        results: repository.search(query),
        query: query,
      ),
      loading: () => const Center(child: FCircularProgress.loader()),
      error: (error, _) => Center(
        child: ErrorStatePanel(
          message: l10n.fortressLoadError,
          detail: '$error',
          retryLabel: l10n.fortressRetry,
          onRetry: () => ref.invalidate(fortressRepositoryProvider),
        ),
      ),
    );
  }
}

class _FortressSearchResultsBody extends StatelessWidget {
  const _FortressSearchResultsBody({
    required this.results,
    required this.query,
  });

  final FortressSearchResults results;
  final String query;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (results.isEmpty) {
      return EmptyStatePanel(
        icon: FLucideIcons.searchX,
        title: l10n.fortressNoSearchResults,
        hint: '"$query"',
        iconSize: 48,
        padding: const EdgeInsets.all(AppSpacing.xl),
        semanticsLabel: FortressA11y.searchEmptyLabel(l10n, query),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kFortressReadingMaxWidth),
        child: _FortressSearchResultsList(
          results: results,
          l10n: l10n,
        ),
      ),
    );
  }
}

class _FortressSearchResultsList extends StatelessWidget {
  const _FortressSearchResultsList({
    required this.results,
    required this.l10n,
  });

  final FortressSearchResults results;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      children: [
        if (results.titles.isNotEmpty) ...[
          _SectionHeader(
            icon: FLucideIcons.folderOpen,
            title: l10n.fortressSearchTitles,
            count: results.totalTitles,
          ),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < results.titles.length; i++) ...[
            _TitleResultTile(category: results.titles[i]),
            SizedBox(
              height: i == results.titles.length - 1
                  ? AppSpacing.xl
                  : AppSpacing.sm,
            ),
          ],
        ],
        if (results.contents.isNotEmpty) ...[
          _SectionHeader(
            icon: FLucideIcons.textSearch,
            title: l10n.fortressSearchContents,
            count: results.totalContents,
          ),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < results.contents.length; i++)
            Padding(
              padding: EdgeInsets.only(
                bottom: i == results.contents.length - 1
                    ? 0
                    : AppSpacing.sm,
              ),
              child: _ContentResultTile(hit: results.contents[i]),
            ),
        ],
      ],
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
          Expanded(
            child: Text(
              title,
              style: theme.typography.body.lg.copyWith(
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          FBadge(child: Text('$count')),
        ],
      ),
    );
  }
}

class _TitleResultTile extends ConsumerWidget {
  const _TitleResultTile({required this.category});

  final FortressCategory category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final l10n = context.l10n;

    return MouseClick(
      onClick: () => ref
          .read(fortressScreenControllerProvider.notifier)
          .selectSearchTitle(category),
      semanticsLabel: category.title,
      child: ExcludeSemantics(
          child: StaticCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          borderRadius: theme.radii.md,
          backgroundColor: theme.colors.secondary.withAlpha(80),
          borderColor: theme.colors.border,
          child: FortressCategoryRow(
            category: category,
            l10n: l10n,
            trailing: Icon(
              FLucideIcons.chevronLeft,
              size: 16,
              color: theme.colors.mutedForeground,
            ),
          ),
        ),
      ),
    );
  }
}

class _ContentResultTile extends ConsumerWidget {
  const _ContentResultTile({required this.hit});

  final FortressSearchContentHit hit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final l10n = context.l10n;
    final item = hit.item;

    return MouseClick(
      onClick: () => ref
          .read(fortressScreenControllerProvider.notifier)
          .selectSearchContent(hit),
      semanticsLabel: '${hit.categoryTitle}. ${item.text}',
      child: ExcludeSemantics(
        child: StaticCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          borderRadius: theme.radii.md,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      hit.categoryTitle,
                      style: theme.typography.body.xs.copyWith(
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
                style: theme.typography.body.sm.copyWith(height: 1.6),
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
