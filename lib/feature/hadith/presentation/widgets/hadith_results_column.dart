import 'dart:async';

import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter/material.dart';
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
class HadithResultsColumn extends ConsumerWidget {
  const HadithResultsColumn({required this.useSplitLayout, super.key});

  final bool useSplitLayout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(hadithSessionControllerProvider);
    final theme = context.theme;
    final visibleResults = ref.hadithVisibleResults(session);
    final visibleCount = switch (visibleResults) {
      AsyncData(:final value) => value.length,
      _ => 0,
    };
    final l10n = context.l10n;

    final content = _buildContent(context, ref, session, visibleResults, theme);
    final showSearchLoadingSemantics =
        session.mode == HadithViewMode.search && session.isLoading;
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
          'results:${session.mode}:${session.query.isEmpty}:'
          '${session.error != null}:$visibleCount',
        ),
        child: Stack(
          children: [
            FSkeletonizer.shimmer(
              enabled:
                  session.mode == HadithViewMode.search &&
                  session.isLoading &&
                  session.results.isEmpty,
              child: semanticsContent,
            ),
            if (session.mode == HadithViewMode.search &&
                session.isLoading &&
                session.results.isNotEmpty)
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
    HadithSessionState session,
    AsyncValue<List<DetailedHadith>> visibleResults,
    FThemeData theme,
  ) {
    final l10n = context.l10n;

    if (session.mode != HadithViewMode.search) {
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
            final emptyMessage = session.mode == HadithViewMode.bookmarks
                ? l10n.hadithNoBookmarks
                : l10n.hadithNoMatchingResults;
            return Center(
              child: EmptyStatePanel(
                icon: session.mode == HadithViewMode.bookmarks
                    ? FLucideIcons.bookmark
                    : FLucideIcons.searchX,
                title: emptyMessage,
              ),
            );
          }

          return _ResultListView(
            session: session,
            hadithList: hadithList,
            useSplitLayout: useSplitLayout,
            enablePagination: false,
          );
        },
      );
    }

    if (session.query.isEmpty) {
      return Center(
        child: EmptyStatePanel(
          icon: FLucideIcons.search,
          title: l10n.hadithStartSearchPrompt,
        ),
      );
    }

    if (session.error != null && session.results.isEmpty) {
      return Center(
        child: EmptyStatePanel(
          icon: FLucideIcons.circleAlert,
          title: session.error!,
        ),
      );
    }

    if (session.results.isEmpty) {
      if (session.isLoading) return const _ResultsSkeletonList();

      return Center(
        child: EmptyStatePanel(
          icon: FLucideIcons.searchX,
          title: l10n.hadithNoMatchingResults,
        ),
      );
    }

    return _ResultListView(
      session: session,
      hadithList: session.results,
      useSplitLayout: useSplitLayout,
      enablePagination: true,
    );
  }
}

class _ResultListView extends ConsumerWidget {
  const _ResultListView({
    required this.session,
    required this.hadithList,
    required this.useSplitLayout,
    required this.enablePagination,
  });

  final HadithSessionState session;
  final List<DetailedHadith> hadithList;
  final bool useSplitLayout;
  final bool enablePagination;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemCount = hadithList.length + (enablePagination ? 1 : 0);

    return ListView.separated(
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        if (enablePagination && index == hadithList.length) {
          if (!session.hasNextPage) {
            return const SizedBox(height: AppSpacing.lg);
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: FButton(
                onPress: session.isLoadingMore
                    ? null
                    : () {
                        unawaited(
                          ref
                              .read(hadithSessionControllerProvider.notifier)
                              .loadMore(),
                        );
                      },
                child: session.isLoadingMore
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

        return _ResultTile(
          hadith: hadithList[index],
          useSplitLayout: useSplitLayout,
        );
      },
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
