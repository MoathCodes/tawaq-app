import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_session_state.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_filters.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/filters/hadith_filter_form.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/hadith_accessibility.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/search/hadith_bookmarks_header.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/search/hadith_query_field.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/search/hadith_recent_searches.dart';
import 'package:tawaq/theme/theme.dart';

/// Search header with query field, bookmarks chrome, and result meta.
class HadithSearchHeader extends ConsumerWidget {
  /// Creates the search header.
  const HadithSearchHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBookmarksMode = ref.watch(
      hadithScreenUiProvider.select(
        (ui) => ui.viewMode == HadithViewMode.bookmarks,
      ),
    );

    return NonSelectable(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isBookmarksMode)
              const HadithBookmarksHeader()
            else ...[
              const HadithQueryField(),
              const _HadithSearchMeta(),
            ],
          ],
        ),
      ),
    );
  }
}

class _HadithSearchMeta extends ConsumerWidget {
  const _HadithSearchMeta();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ui = ref.watch(hadithScreenUiProvider);
    if (!ui.isSearchMode) return const SizedBox.shrink();

    final resultsCount = switch (ui.visibleResults) {
      AsyncData(:final value) => value.length,
      _ => 0,
    };
    final l10n = context.l10n;
    final activeFilterCount = ui.filters.activeCount;
    final showRecents = ui.query.trim().isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.xs),
        if (ui.query.trim().isNotEmpty || activeFilterCount > 0)
          Semantics(
            label: l10n.hadithResultsCount(resultsCount),
            child: HadithDecorExcludeSemantics(
              child: FBadge(
                variant: resultsCount > 0 ? .secondary : .outline,
                child: Text(l10n.hadithResultsCount(resultsCount)),
              ),
            ),
          ),
        const HadithActiveFilterChips(),
        if (showRecents) ...[
          if (activeFilterCount > 0) const SizedBox(height: AppSpacing.xs),
          const HadithRecentSearchesSection(),
        ],
      ],
    );
  }
}
