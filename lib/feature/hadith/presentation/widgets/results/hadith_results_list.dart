import 'dart:async';

import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/empty_state_panel.dart';
import 'package:tawaq/core/widgets/f_skeletonizer.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_screen_ui.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_session_state.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/hadith_accessibility.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/results/hadith_result_tile.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/results/hadith_results_skeleton.dart';
import 'package:tawaq/theme/theme.dart';

/// List of hadith search results with loading, empty, and pagination states.
class HadithResultsList extends ConsumerWidget {
  /// Creates the results list.
  const HadithResultsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ui = ref.watch(hadithScreenUiProvider);
    final theme = context.theme;
    final visibleCount = switch (ui.visibleResults) {
      AsyncData(:final value) => value.length,
      _ => 0,
    };
    final l10n = context.l10n;

    final content = _buildContent(context, ref, ui, theme);
    final showSearchLoadingSemantics =
        ui.viewMode == HadithViewMode.search && ui.searchLoading;
    final semanticsContent = showSearchLoadingSemantics
        ? Semantics(
            label: hadithSearchLoadingSemanticsLabel(l10n),
            child: ExcludeSemantics(child: content),
          )
        : content;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1).animate(animation),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey(
          'results:${ui.viewMode}:${ui.query.isEmpty}:'
          '${ui.searchError != null}:$visibleCount',
        ),
        child: Stack(
          children: [
            FSkeletonizer.shimmer(
              enabled:
                  ui.viewMode == HadithViewMode.search &&
                  ui.searchLoading &&
                  ui.searchResults.isEmpty,
              child: semanticsContent,
            ),
            if (ui.viewMode == HadithViewMode.search &&
                ui.searchLoading &&
                ui.searchResults.isNotEmpty)
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

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    HadithScreenUi ui,
    FThemeData theme,
  ) {
    final l10n = context.l10n;

    if (ui.viewMode != HadithViewMode.search) {
      return ui.visibleResults.when(
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
            final emptyMessage = ui.viewMode == HadithViewMode.bookmarks
                ? l10n.hadithNoBookmarks
                : l10n.hadithNoMatchingResults;
            return Center(
              child: EmptyStatePanel(
                icon: ui.viewMode == HadithViewMode.bookmarks
                    ? FLucideIcons.bookmark
                    : FLucideIcons.searchX,
                title: emptyMessage,
              ),
            );
          }

          return _buildResultListView(
            context,
            ref,
            ui,
            hadithList,
            enablePagination: false,
          );
        },
      );
    }

    if (ui.query.isEmpty) {
      return Center(
        child: EmptyStatePanel(
          icon: FLucideIcons.search,
          title: l10n.hadithStartSearchPrompt,
        ),
      );
    }

    if (ui.searchError != null && ui.searchResults.isEmpty) {
      return Center(
        child: EmptyStatePanel(
          icon: FLucideIcons.circleAlert,
          title: ui.searchError!,
        ),
      );
    }

    if (ui.searchResults.isEmpty) {
      if (ui.searchLoading) return const HadithResultsSkeletonList();

      return Center(
        child: EmptyStatePanel(
          icon: FLucideIcons.searchX,
          title: l10n.hadithNoMatchingResults,
        ),
      );
    }

    return _buildResultListView(
      context,
      ref,
      ui,
      ui.searchResults,
      enablePagination: true,
    );
  }

  Widget _buildResultListView(
    BuildContext context,
    WidgetRef ref,
    HadithScreenUi ui,
    List<DetailedHadith> hadithList, {
    required bool enablePagination,
  }) {
    final itemCount = hadithList.length + (enablePagination ? 1 : 0);

    return ListView.separated(
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        if (enablePagination && index == hadithList.length) {
          if (!ui.searchHasNextPage) {
            return const SizedBox(height: AppSpacing.lg);
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: FButton(
                onPress: ui.searchLoadingMore
                    ? null
                    : () {
                        unawaited(
                          ref
                              .read(hadithSessionControllerProvider.notifier)
                              .loadMore(),
                        );
                      },
                child: ui.searchLoadingMore
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

        return HadithResultTile(hadith: hadithList[index]);
      },
    );
  }
}
