import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/custom_cards.dart';
import 'package:tawaq/core/widgets/empty_state_panel.dart';
import 'package:tawaq/core/widgets/mouse_click.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_category.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_locale_extensions.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_search_results.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/fortress_category_ui.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/provider/muslim_fortress_provider.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/fortress_a11y.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/reading/fortress_focus_reading.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/theme.dart';

/// Displays global Hisn search results for titles and dhikr contents.
class FortressSearchResultsPane extends ConsumerWidget {
  /// Creates a search results pane.
  const FortressSearchResultsPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(muslimFortressSearchQueryProvider);
    final resultsAsync = ref.watch(muslimFortressSearchResultsProvider);

    final l10n = context.l10n;

    return resultsAsync.when(
      data: (results) => _FortressSearchResultsBody(
        results: results,
        query: query,
      ),
      loading: () => const Center(child: FCircularProgress.loader()),
      error: (error, _) => Center(
        child: ErrorStatePanel(
          message: l10n.fortressLoadError,
          detail: '$error',
          retryLabel: l10n.fortressRetry,
          onRetry: () => ref.invalidate(muslimFortressSearchResultsProvider),
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

enum _SearchListEntryKind { titleHeader, title, contentHeader, content }

class _SearchListEntry {
  const _SearchListEntry._(this.kind, {this.category, this.hit});

  const _SearchListEntry.titleHeader() : this._(_SearchListEntryKind.titleHeader);

  const _SearchListEntry.title(FortressCategory category)
    : this._(_SearchListEntryKind.title, category: category);

  const _SearchListEntry.contentHeader()
    : this._(_SearchListEntryKind.contentHeader);

  const _SearchListEntry.content(FortressSearchContentHit hit)
    : this._(_SearchListEntryKind.content, hit: hit);

  final _SearchListEntryKind kind;
  final FortressCategory? category;
  final FortressSearchContentHit? hit;
}

class _FortressSearchResultsList extends StatelessWidget {
  const _FortressSearchResultsList({
    required this.results,
    required this.l10n,
  });

  final FortressSearchResults results;
  final AppLocalizations l10n;

  List<_SearchListEntry> _buildEntries() {
    final entries = <_SearchListEntry>[];

    if (results.titles.isNotEmpty) {
      entries.add(const _SearchListEntry.titleHeader());
      for (final category in results.titles) {
        entries.add(_SearchListEntry.title(category));
      }
    }

    if (results.contents.isNotEmpty) {
      entries.add(const _SearchListEntry.contentHeader());
      for (final hit in results.contents) {
        entries.add(_SearchListEntry.content(hit));
      }
    }

    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final entries = _buildEntries();

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final isLast = index == entries.length - 1;
        final nextKind = isLast ? null : entries[index + 1].kind;

        final child = switch (entry.kind) {
          _SearchListEntryKind.titleHeader => _SectionHeader(
            icon: FLucideIcons.folderOpen,
            title: l10n.fortressSearchTitles,
            count: results.totalTitles,
          ),
          _SearchListEntryKind.title => _TitleResultTile(
            category: entry.category!,
          ),
          _SearchListEntryKind.contentHeader => _SectionHeader(
            icon: FLucideIcons.textSearch,
            title: l10n.fortressSearchContents,
            count: results.totalContents,
          ),
          _SearchListEntryKind.content => _ContentResultTile(hit: entry.hit!),
        };

        final trailingGap = switch (entry.kind) {
          _SearchListEntryKind.titleHeader ||
          _SearchListEntryKind.contentHeader =>
            AppSpacing.md,
          _SearchListEntryKind.title || _SearchListEntryKind.content =>
            nextKind == _SearchListEntryKind.contentHeader ||
                    nextKind == _SearchListEntryKind.titleHeader ||
                    nextKind == null
                ? AppSpacing.xl
                : AppSpacing.sm,
        };

        return Padding(
          padding: EdgeInsets.only(bottom: trailingGap),
          child: child,
        );
      },
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
      child: FortressExcludeDecorative(
        child: StaticCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          borderRadius: theme.radii.md,
          backgroundColor: theme.colors.secondary.withAlpha(80),
          borderColor: theme.colors.border,
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
                      style: theme.typography.body.md.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${fortressRecurrenceLabel(category.recurrence, l10n)} · ${l10n.fortressSupplicationCount(category.supplicationCount)}',
                      style: theme.typography.body.xs.copyWith(
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
      child: FortressExcludeDecorative(
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
