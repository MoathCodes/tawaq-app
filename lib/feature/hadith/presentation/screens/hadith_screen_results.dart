part of 'hadith_screen.dart';

class _ResultsList extends ConsumerWidget {
  const _ResultsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enableDetailsPopover = !isAtLeast(context, FBreakpoint.lg);
    final mode = ref.watch(hadithViewModeProvider);
    final visibleResults = ref.watch(hadithVisibleResultsProvider);
    final state = ref.watch(
      hadithSearchControllerProvider.select(
        (value) => value.value ?? const HadithSearchState(),
      ),
    );
    final theme = context.theme;
    final visibleCount = switch (visibleResults) {
      AsyncData(:final value) => value.length,
      _ => 0,
    };

    final l10n = context.l10n;
    final content = _buildContent(
      context,
      ref,
      state,
      theme,
      mode,
      visibleResults,
      enableDetailsPopover: enableDetailsPopover,
    );
    final showSearchLoadingSemantics =
        mode == HadithViewMode.search && state.isLoading;
    final semanticsContent = showSearchLoadingSemantics
        ? Semantics(
            label: hadithSearchLoadingSemanticsLabel(l10n),
            child: ExcludeSemantics(child: content),
          )
        : content;

    return AnimatedSwitcher(
      duration: 260.ms,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: child.animate().scale(
            begin: const Offset(0.98, 0.98),
            end: const Offset(1, 1),
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey(
          'results:$mode:${state.query.isEmpty}:'
          '${state.error != null}:$visibleCount:${state.isLoading}',
        ),
        child: FSkeletonizer.shimmer(
          enabled: mode == HadithViewMode.search && state.isLoading,
          child: semanticsContent,
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    HadithSearchState state,
    FThemeData theme,
    HadithViewMode mode,
    AsyncValue<List<DetailedHadith>> visibleResults, {
    required bool enableDetailsPopover,
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
              style: theme.typography.md.copyWith(
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
              child: Text(
                emptyMessage,
                style: theme.typography.md.copyWith(
                  color: theme.colors.mutedForeground,
                ),
              ),
            );
          }

          return _buildResultListView(
            context,
            ref,
            state,
            hadithList,
            enablePagination: false,
            enableDetailsPopover: enableDetailsPopover,
          );
        },
      );
    }

    if (state.query.isEmpty) {
      return Center(
        child: Text(
          l10n.hadithStartSearchPrompt,
          style: theme.typography.lg.copyWith(
            color: theme.colors.mutedForeground,
          ),
        ),
      );
    }

    if (state.error != null && state.results.isEmpty) {
      return Center(
        child: Text(
          state.error!,
          textAlign: TextAlign.center,
          style: theme.typography.md.copyWith(
            color: theme.colors.destructive,
          ),
        ),
      );
    }

    if (state.results.isEmpty) {
      if (state.isLoading) return const _ResultsSkeletonList();

      return Center(
        child: Text(
          l10n.hadithNoMatchingResults,
          style: theme.typography.md.copyWith(
            color: theme.colors.mutedForeground,
          ),
        ),
      );
    }

    return _buildResultListView(
      context,
      ref,
      state,
      state.results,
      enablePagination: true,
      enableDetailsPopover: enableDetailsPopover,
    );
  }

  Widget _buildResultListView(
    BuildContext context,
    WidgetRef ref,
    HadithSearchState state,
    List<DetailedHadith> hadithList, {
    required bool enablePagination,
    required bool enableDetailsPopover,
  }) {
    final itemCount = hadithList.length + (enablePagination ? 1 : 0);

    return ListView.separated(
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        if (enablePagination && index == hadithList.length) {
          if (!state.hasNextPage) {
            return const SizedBox(height: AppSpacing.lg);
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: FButton(
                onPress: state.isLoadingMore
                    ? null
                    : () {
                        unawaited(
                          ref
                              .read(hadithScreenControllerProvider.notifier)
                              .loadMore(),
                        );
                      },
                child: state.isLoadingMore
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: FCircularProgress(),
                      )
                    : Text(context.l10n.hadithLoadMore),
              ),
            ),
          );
        }

        final hadith = hadithList[index];
        final card = HadithResultCard(hadith: hadith);

        if (!enableDetailsPopover) return card;

        return FPopover(
          popoverBuilder: (_, _) => ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620, maxHeight: 620),
            child: HadithSelectedDetailsPane(hadith: hadith),
          ),
          builder: (_, controller, child) => MouseClick(
            onClick: () {
              unawaited(
                ref
                    .read(hadithScreenControllerProvider.notifier)
                    .selectHadith(hadith),
              );
              unawaited(controller.toggle());
            },
            child: child!,
          ),
          child: card,
        );
      },
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
