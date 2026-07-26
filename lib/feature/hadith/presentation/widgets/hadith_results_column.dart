import 'dart:async';

import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/layout/viewport_dialog_constraints.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/custom_cards.dart';
import 'package:tawaq/core/widgets/empty_state_panel.dart';
import 'package:tawaq/core/widgets/f_skeletonizer.dart';
import 'package:tawaq/core/widgets/mouse_click.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_session_state.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/detail/hadith_detail_pane.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/hadith_accessibility.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/results/hadith_result_card.dart';
import 'package:tawaq/theme/theme.dart';

/// List of hadith search results with loading, empty, and pagination states.
///
/// Watches search fields only — selection is per-card / side-panel.
class HadithResultsColumn extends ConsumerWidget {
  const HadithResultsColumn({required this.useSplitLayout, super.key});

  final bool useSplitLayout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(
      hadithSessionControllerProvider.select((s) => s.mode),
    );
    final query = ref.watch(
      hadithSessionControllerProvider.select((s) => s.query),
    );
    final searchOutcome = ref.watch(
      hadithSessionControllerProvider.select((s) => s.searchOutcome),
    );
    final specificHadiths = mode == HadithViewMode.specificList
        ? ref.watch(
            hadithSessionControllerProvider.select((s) => s.specificHadiths),
          )
        : const <DetailedHadith>[];

    final theme = context.theme;
    final l10n = context.l10n;
    final visibleResults = switch (mode) {
      HadithViewMode.search => _searchResultsAsync(searchOutcome),
      HadithViewMode.bookmarks => ref.watch(hadithFavoritesProvider),
      HadithViewMode.specificList => AsyncData(specificHadiths),
    };
    final visibleCount = switch (visibleResults) {
      AsyncData(:final value) => value.length,
      _ => 0,
    };
    final hardError = searchOutcome.hasError && !searchOutcome.hasValue
        ? '${searchOutcome.error}'
        : null;
    final isPaginating = ref.watch(
      hadithSessionControllerProvider.select((s) => s.isPaginating),
    );
    final paginationError = ref.watch(
      hadithSessionControllerProvider.select((s) => s.paginationError),
    );
    final isLoading = searchOutcome.isLoading || isPaginating;
    final results = searchOutcome.value?.results ?? const <DetailedHadith>[];
    final page = searchOutcome.value?.page ?? 1;
    final totalPages = searchOutcome.value?.totalPages ?? 0;

    final content = _buildContent(
      context: context,
      ref: ref,
      mode: mode,
      query: query,
      hardError: hardError,
      paginationError: paginationError,
      isLoading: isLoading,
      results: results,
      page: page,
      totalPages: totalPages,
      visibleResults: visibleResults,
      theme: theme,
    );
    final showSearchLoadingSemantics =
        mode == HadithViewMode.search && isLoading;
    final semanticsContent = showSearchLoadingSemantics
        ? Semantics(
            label: hadithSearchLoadingSemanticsLabel(l10n),
            child: ExcludeSemantics(child: content),
          )
        : content;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        // Fade only — avoid scale thrash on page / result-list swaps.
        return FadeTransition(opacity: animation, child: child);
      },
      child: KeyedSubtree(
        key: ValueKey(
          'results:$mode:${query.isEmpty}:'
          '${hardError != null}:$visibleCount',
        ),
        child: Stack(
          children: [
            FSkeletonizer.shimmer(
              enabled:
                  mode == HadithViewMode.search &&
                  isLoading &&
                  results.isEmpty,
              child: semanticsContent,
            ),
            if (mode == HadithViewMode.search &&
                isLoading &&
                results.isNotEmpty)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Semantics(
                  label: hadithSearchLoadingSemanticsLabel(l10n),
                  child: const ExcludeSemantics(
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent({
    required BuildContext context,
    required WidgetRef ref,
    required HadithViewMode mode,
    required String query,
    required String? hardError,
    required String? paginationError,
    required bool isLoading,
    required List<DetailedHadith> results,
    required int page,
    required int totalPages,
    required AsyncValue<List<DetailedHadith>> visibleResults,
    required FThemeData theme,
  }) {
    final l10n = context.l10n;

    if (mode != HadithViewMode.search) {
      return visibleResults.when(
        loading: () => Semantics(
          label: hadithSearchLoadingSemanticsLabel(l10n),
          child: const ExcludeSemantics(
            child: Center(child: FCircularProgress.loader()),
          ),
        ),
        error: (error, _) {
          return Center(
            child: Text(
              '$error',
              textAlign: TextAlign.center,
              style: theme.typography.body.md.copyWith(
                color: theme.colors.destructive,
              ),
            ),
          );
        },
        data: (hadithList) {
          if (hadithList.isEmpty) {
            final emptyMessage = mode == HadithViewMode.bookmarks
                ? l10n.hadithNoBookmarks
                : l10n.hadithNoMatchingResults;
            return Center(
              child: EmptyStatePanel(
                icon: mode == HadithViewMode.bookmarks
                    ? FLucideIcons.bookmark
                    : FLucideIcons.searchX,
                title: emptyMessage,
              ),
            );
          }

          return _ResultListView(
            hadithList: hadithList,
            useSplitLayout: useSplitLayout,
            showPagination: false,
            page: page,
            totalPages: totalPages,
            isLoading: isLoading,
          );
        },
      );
    }

    if (query.isEmpty) {
      return Center(
        child: EmptyStatePanel(
          icon: FLucideIcons.search,
          title: l10n.hadithStartSearchPrompt,
        ),
      );
    }

    if (hardError != null) {
      return Center(
        child: EmptyStatePanel(
          icon: FLucideIcons.circleAlert,
          title: hardError,
        ),
      );
    }

    if (results.isEmpty) {
      if (isLoading) return const _ResultsSkeletonList();

      return Center(
        child: EmptyStatePanel(
          icon: FLucideIcons.searchX,
          title: l10n.hadithNoMatchingResults,
        ),
      );
    }

    final list = _ResultListView(
      hadithList: results,
      useSplitLayout: useSplitLayout,
      showPagination: totalPages > 1,
      page: page,
      totalPages: totalPages,
      isLoading: isLoading,
    );

    if (paginationError == null) return list;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: FAlert(
            liveRegion: true,
            icon: const Icon(FLucideIcons.circleAlert),
            title: Text(l10n.hadithPageLoadFailed),
          ),
        ),
        Expanded(child: list),
      ],
    );
  }
}

AsyncValue<List<DetailedHadith>> _searchResultsAsync(
  AsyncValue<HadithSearchPage> outcome,
) {
  if (outcome.hasValue) {
    return AsyncData(outcome.requireValue.results);
  }
  if (outcome.hasError) {
    return AsyncError(outcome.error!, outcome.stackTrace!);
  }
  return const AsyncLoading();
}

class _ResultListView extends HookConsumerWidget {
  const _ResultListView({
    required this.hadithList,
    required this.useSplitLayout,
    required this.showPagination,
    required this.page,
    required this.totalPages,
    required this.isLoading,
  });

  final List<DetailedHadith> hadithList;
  final bool useSplitLayout;
  final bool showPagination;
  final int page;
  final int totalPages;
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scrollController = useScrollController();
    final scrollDuration = context.theme.durations.fast;

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!scrollController.hasClients) return;
        unawaited(
          scrollController.animateTo(
            0,
            duration: scrollDuration,
            curve: Curves.easeOutCubic,
          ),
        );
      });
      return null;
    }, [page]);

    final list = ListView.separated(
      controller: scrollController,
      itemCount: hadithList.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        return _ResultTile(
          hadith: hadithList[index],
          useSplitLayout: useSplitLayout,
        );
      },
    );

    if (!showPagination || totalPages <= 1) return list;

    final pageIndex = (page - 1).clamp(0, totalPages - 1);

    return Column(
      children: [
        Expanded(child: list),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Center(
            child: FPagination(
              control: .lifted(
                page: pageIndex,
                pages: totalPages,
                onChange: (index) {
                  if (isLoading) return;
                  unawaited(
                    ref
                        .read(hadithSessionControllerProvider.notifier)
                        .goToPage(index + 1),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultTile extends ConsumerWidget {
  const _ResultTile({
    required this.hadith,
    required this.useSplitLayout,
  });

  final DetailedHadith hadith;
  final bool useSplitLayout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = HadithResultCard(hadith: hadith);

    if (useSplitLayout) return card;

    return FPopover(
      popoverBuilder: (_, _) => ConstrainedBox(
        constraints: dialogConstraints(
          context,
          preferredWidth: 620,
          preferredHeight: 620,
        ),
        child: HadithSelectedDetailsPane(hadith: hadith),
      ),
      builder: (_, controller, child) => MouseClick(
        onClick: () {
          unawaited(
            ref
                .read(hadithSessionControllerProvider.notifier)
                .selectHadith(hadith),
          );
          unawaited(controller.toggle());
        },
        child: child!,
      ),
      child: card,
    );
  }
}

class _ResultsSkeletonList extends StatelessWidget {
  const _ResultsSkeletonList();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: hadithSearchLoadingSemanticsLabel(context.l10n),
      child: ExcludeSemantics(
        child: ListView.separated(
          itemCount: 4,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (_, _) {
            return const StaticCard(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.sm,
                children: [
                  SizedBox(height: 20, width: double.infinity),
                  SizedBox(height: 20, width: double.infinity),
                  SizedBox(height: 20, width: 220),
                  SizedBox(height: AppSpacing.md),
                  SizedBox(height: 14, width: 180),
                  SizedBox(height: AppSpacing.xs),
                  SizedBox(height: 14, width: 220),
                  SizedBox(height: AppSpacing.md),
                  SizedBox(height: 30, width: 120),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
