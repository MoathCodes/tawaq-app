import 'dart:async';

import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/shortcuts/shortcuts.dart';
import 'package:tawaq/core/utils/external_link_provider.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/hadith_loading_cards.dart';
import 'package:tawaq/core/widgets/dialog_shell.dart';
import 'package:tawaq/feature/hadith/data/database/hadith_local_database.dart';
import 'package:tawaq/feature/hadith/presentation/models/hadith_session_state.dart';
import 'package:tawaq/feature/hadith/presentation/models/hadith_failure_message.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_identity.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_screen_settings_provider.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/hadith_topics.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/hadith_accessibility.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/results/hadith_result_card.dart';
import 'package:tawaq/theme/theme.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/hadith_help.dart';

/// Typed collections with one scroll/pager path and no modal detail destination.
class HadithResultsColumn extends HookConsumerWidget {
  const HadithResultsColumn({this.focusNodes, super.key});
  final Map<String, FocusNode>? focusNodes;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(
      hadithSessionControllerProvider.select(
        (s) => (
          s.context,
          s.target,
          s.query,
          s.filters,
          s.searchOutcome,
          s.selectedHadithKey,
          s.selectedSharhId,
          s.isPaginating,
          s.paginationError,
          s.emptyNextPage,
        ),
      ),
    );
    final session = ref.read(hadithSessionControllerProvider);
    final controller = ref.read(hadithSessionControllerProvider.notifier);
    final scroll = useScrollController(
      initialScrollOffset: session.resultsOffset,
    );
    final focus = useFocusNode();
    final localNodes = useMemoized(() => <String, FocusNode>{});
    final nodes = focusNodes ?? localNodes;
    useEffect(
      () => () {
        for (final node in localNodes.values) {
          node.dispose();
        }
      },
      [localNodes],
    );
    FocusNode nodeFor(String key) => nodes.putIfAbsent(key, FocusNode.new);
    useEffect(() {
      void changed() => controller.setResultsOffset(scroll.offset);
      scroll.addListener(changed);
      return () => scroll.removeListener(changed);
    }, [scroll]);
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scroll.hasClients)
          scroll.jumpTo(
            session.resultsOffset.clamp(0, scroll.position.maxScrollExtent),
          );
      });
      return null;
    }, [session.context, session.searchPage]);
    final l10n = context.l10n;
    void select(DetailedHadith record) {
      ref.read(hadithScreenSettingsProvider.notifier).setReaderCollapsed(false);
      unawaited(controller.selectHadith(record));
    }

    Widget records(List<DetailedHadith> items) => items.isEmpty
        ? Center(child: Text(l10n.noResults))
        : ListView.separated(
            controller: scroll,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (_, index) => HadithResultCard(
              key: ValueKey('record:${hadithStableKey(items[index])}'),
              focusNode: nodeFor(hadithStableKey(items[index])),
              hadith: items[index],
              query: session.isSearchMode
                  ? (session.committedQuery ?? session.query)
                  : '',
              resultOrdinal: index + 1,
              onSelect: () => select(items[index]),
            ),
          );
    Widget saved(Map<String, SavedHadithEntry> entries) => entries.isEmpty
        ? Center(child: Text(l10n.noResults))
        : ListView.separated(
            controller: scroll,
            itemCount: entries.length,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (_, index) {
              final entry = entries.values.elementAt(index);
              if (entry.hadith case final record?)
                return Column(
                  key: ValueKey('saved:${entry.key}'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    HadithResultCard(
                      hadith: record,
                      resultOrdinal: index + 1,
                      isFavorite: true,
                      isSelected: session.selectedHadithKey == entry.key,
                      focusNode: nodeFor(entry.key),
                      onSelect: () {
                        ref
                            .read(hadithScreenSettingsProvider.notifier)
                            .setReaderCollapsed(false);
                        controller.selectSavedEntry(entry.key);
                      },
                      onToggleFavorite: () async {
                        try {
                          await controller.removeSavedEntry(entry.key);
                        } catch (_) {
                          if (context.mounted)
                            showFToast(
                              context: context,
                              title: Text(l10n.hadithBookmarkFailed),
                            );
                        }
                      },
                    ),
                    if (entry.richContentUnavailable)
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: Text(l10n.hadithRichContentUnavailable),
                      ),
                  ],
                );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.hadithUnreadableSaved),
                  FButton(
                    variant: .outline,
                    onPress: () async {
                      try {
                        await ref
                            .read(hadithFavoritesStoreProvider.notifier)
                            .remove(entry.key);
                      } catch (_) {
                        if (context.mounted)
                          showFToast(
                            context: context,
                            title: Text(l10n.hadithBookmarkFailed),
                          );
                      }
                    },
                    child: Text(l10n.menuRemoveBookmark),
                  ),
                ],
              );
            },
          );
    Widget renderPage(HadithSearchPage page) => switch (page) {
      HadithProsePage(:final snippets) =>
        snippets.isEmpty
            ? Center(child: Text(l10n.noResults))
            : ListView.separated(
                controller: scroll,
                itemCount: snippets.length,
                separatorBuilder: (_, _) => const FDivider(),
                itemBuilder: (_, index) {
                  final snippet = snippets[index];
                  return Column(
                    key: ValueKey('prose:${snippet.id}'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FButton(
                        variant: session.selectedSharhId == snippet.id
                            ? .secondary
                            : .ghost,
                        onPress: () {
                          ref
                              .read(hadithScreenSettingsProvider.notifier)
                              .setReaderCollapsed(false);
                          controller.selectSharh(snippet);
                        },
                        child: Flexible(
                          child: Text(
                            snippet.text,
                            style: context.theme.typography.body.lg.copyWith(
                              height: 1.8,
                            ),
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                            textDirection: TextDirection.rtl,
                          ),
                        ),
                      ),
                      FButton(
                        variant: .ghost,
                        mainAxisSize: MainAxisSize.min,
                        onPress: () =>
                            ref.read(externalLinkLauncherProvider)(snippet.uri),
                        child: Text(l10n.hadithSource),
                      ),
                    ],
                  );
                },
              ),
      _ => records(page.results),
    };
    Widget body;
    if (session.context is SavedCollection) {
      body = ref
          .watch(hadithFavoritesStoreProvider)
          .when(
            data: saved,
            loading: () => const Center(child: FCircularProgress.loader()),
            error: (_, _) => _Retry(
              onRetry: () => ref.invalidate(hadithFavoritesStoreProvider),
            ),
          );
    } else if (session.context is TopicsCollection) {
      body = SingleChildScrollView(
        controller: scroll,
        child: const HadithTopics(),
      );
    } else {
      body = session.searchPage != null
          ? renderPage(session.searchPage!)
          : session.searchOutcome.when(
              skipLoadingOnRefresh: true,
              skipError: session.searchPage != null,
              loading: () => session.target == HadithSearchTarget.prose
                  ? const HadithProseLoading()
                  : const HadithLoadingCards(),
              error: (error, _) => _Retry(
                message: hadithFailureMessage(error, l10n),
                onRetry: controller.search,
              ),
              data: renderPage,
            );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (session.context case CategoryCollection(:final category))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(category.name, style: context.theme.typography.body.lg),
          ),
        if (session.context is SearchCollection ||
            session.context is CategoryCollection)
          const _ResultTools(),
        if (session.context is SavedCollection)
          Text(
            l10n.hadithResultsCount(
              ref.watch(hadithFavoritesStoreProvider).value?.length ?? 0,
            ),
          ),
        if (session.searchOutcome.hasError && session.searchPage != null)
          _Retry(
            message: hadithFailureMessage(session.searchOutcome.error, l10n),
            onRetry: controller.search,
          ),
        Expanded(
          key: const ValueKey('hadith-collection-body'),
          child: AppShortcutScope(
            shortcuts: {
              AppShortcut.hadithResultNext,
              AppShortcut.hadithResultPrev,
            },
            handlers: {
              AppShortcut.hadithResultNext: () =>
                  unawaited(controller.selectAdjacentResult(1)),
              AppShortcut.hadithResultPrev: () =>
                  unawaited(controller.selectAdjacentResult(-1)),
            },
            child: Focus(
              focusNode: focus,
              child: Listener(
                onPointerDown: (_) => focus.requestFocus(),
                child: body,
              ),
            ),
          ),
        ),
        if (session.paginationError != null)
          _Retry(
            message: hadithFailureMessage(session.paginationError, l10n),
            onRetry: () => controller.goToPage(
              session.paginationRequestedPage ?? session.page + 1,
            ),
          ),
        if (session.context is SearchCollection ||
            session.context is CategoryCollection)
          _Pager(),
      ],
    );
  }
}

class _ResultTools extends ConsumerWidget {
  const _ResultTools();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(
      hadithSessionControllerProvider.select(
        (s) => (s.context, s.target, s.filters, s.searchPage, s.searchBusy),
      ),
    );
    final session = ref.read(hadithSessionControllerProvider);
    final controller = ref.read(hadithSessionControllerProvider.notifier);
    final l10n = context.l10n;
    final specialist = switch (session.context) {
      CategoryCollection(:final specialist) => specialist,
      _ => session.filters.specialist,
    };
    final supported =
        session.supportsFilters || session.context is CategoryCollection;
    final refreshing = session.searchBusy && session.searchPage != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: session.searchPage == null
                    ? const SizedBox.shrink()
                    : Semantics(
                        liveRegion: refreshing,
                        child: Text(
                          refreshing
                              ? l10n.hadithUpdating
                              : l10n.hadithResultsCount(
                                  session.searchPage!.results.length +
                                      session.searchPage!.snippets.length,
                                ),
                          style: context.theme.typography.body.sm.copyWith(
                            fontWeight: refreshing ? FontWeight.w600 : null,
                          ),
                        ),
                      ),
              ),
              if (supported)
                FPopoverMenu(
                  menuBuilder: (_, popover, _) => [
                    FItemGroup(
                      children: [
                        if (session.supportsFilters)
                          for (final degreeOrder in [false, true])
                            FItem(
                              prefix: Icon(
                                session.filters.sort ==
                                        (degreeOrder ? HadithSort.degree : null)
                                    ? FLucideIcons.check
                                    : FLucideIcons.arrowDownWideNarrow,
                                size: 16,
                              ),
                              title: HadithHelpLabel(
                                label: degreeOrder
                                    ? l10n.hadithDegreeOrder
                                    : l10n.hadithDorarOrder,
                                help: l10n.hadithDegreeOrderHelp,
                              ),
                              onPress: () {
                                popover.hide();
                                controller.setFilters(
                                  session.filters.copyWith(
                                    sort: degreeOrder
                                        ? HadithSort.degree
                                        : null,
                                  ),
                                );
                              },
                            ),
                        FItem(
                          prefix: Icon(
                            specialist ? FLucideIcons.check : FLucideIcons.link,
                            size: 16,
                          ),
                          title: HadithHelpLabel(
                            label: l10n.hadithSpecialist,
                            help: l10n.hadithSpecialistHelp,
                          ),
                          onPress: () {
                            popover.hide();
                            if (session.context is CategoryCollection) {
                              controller.setCategorySpecialist(!specialist);
                            } else {
                              controller.setFilters(
                                session.filters.copyWith(
                                  specialist: !specialist,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                  builder: (_, popover, _) => FButton(
                    variant: .ghost,
                    size: .sm,
                    mainAxisSize: MainAxisSize.min,
                    prefix: const Icon(
                      FLucideIcons.arrowDownWideNarrow,
                      size: 16,
                    ),
                    onPress: popover.toggle,
                    child: Text(
                      session.supportsFilters &&
                              session.filters.sort == HadithSort.degree
                          ? l10n.hadithDegreeOrder
                          : specialist
                          ? l10n.hadithSpecialist
                          : l10n.hadithDorarOrder,
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 4,
          child: refreshing
              ? ExcludeSemantics(
                  child: FProgress(
                    key: const ValueKey('hadith-refresh-progress'),
                    style: .delta(
                      constraints: const BoxConstraints.tightFor(height: 2),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _Pager extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(
      hadithSessionControllerProvider.select(
        (s) => (
          s.context,
          s.target,
          s.query,
          s.filters,
          s.searchOutcome,
          s.selectedHadithKey,
          s.selectedSharhId,
          s.isPaginating,
          s.paginationError,
          s.emptyNextPage,
        ),
      ),
    );
    final session = ref.read(hadithSessionControllerProvider);
    final pages = session.searchPage?.reachablePages;
    if (session.page == 1 &&
        !session.canGoNext &&
        (pages == null || pages <= 1))
      return const SizedBox.shrink();
    final controller = ref.read(hadithSessionControllerProvider.notifier);
    if (pages != null)
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: ExcludeFocus(
          excluding: session.searchBusy,
          child: IgnorePointer(
            ignoring: session.searchBusy,
            child: Opacity(
              opacity: session.searchBusy ? .5 : 1,
              child: FPagination(
                control: FPaginationControl.lifted(
                  pages: pages,
                  page: session.page - 1,
                  onChange: (value) {
                    if (!session.searchBusy)
                      unawaited(controller.goToPage(value + 1));
                  },
                ),
              ),
            ),
          ),
        ),
      );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        FButton.icon(
          variant: .outline,
          semanticsTooltip: context.l10n.fortressPrevious,
          onPress: !session.searchBusy && session.page > 1
              ? () => controller.goToPage(session.page - 1)
              : null,
          child: const Icon(FLucideIcons.chevronLeft),
        ),
        Text('${session.page}'),
        FButton.icon(
          variant: .outline,
          semanticsTooltip: context.l10n.next,
          onPress: !session.searchBusy && session.canGoNext
              ? () => controller.goToPage(session.page + 1)
              : null,
          child: const Icon(FLucideIcons.chevronRight),
        ),
      ],
    );
  }
}

class _Retry extends StatelessWidget {
  const _Retry({required this.onRetry, this.message});
  final String? message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.sm,
      children: [
        Text(message ?? context.l10n.hadithRequestFailed),
        FButton(
          variant: .secondary,
          onPress: onRetry,
          child: Text(context.l10n.retryAction),
        ),
      ],
    ),
  );
}

class HadithRecentQueries extends ConsumerWidget {
  const HadithRecentQueries({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(hadithRecentSearchesStoreProvider)
      .when(
        loading: () => Text(context.l10n.loading),
        error: (_, _) => _Retry(
          message: context.l10n.hadithRecentsLoadFailed,
          onRetry: () => ref.invalidate(hadithRecentSearchesStoreProvider),
        ),
        data: (items) => items.isEmpty
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 12,
                children: [
                  Text(
                    context.l10n.hadithRecentSearches,
                    style: context.theme.typography.body.sm.copyWith(
                      color: context.theme.colors.mutedForeground,
                    ),
                  ),
                  Text(
                    context.l10n.hadithNoRecentSearches,
                    style: context.theme.typography.body.sm.copyWith(
                      color: context.theme.colors.mutedForeground,
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.sm,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(context.l10n.hadithRecentSearches)),
                      FButton(
                        variant: .ghost,
                        size: .sm,
                        mainAxisSize: MainAxisSize.min,
                        onPress: () => _clearRecents(context, ref),
                        child: Text(context.l10n.hadithClearAllRecents),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final query in items.take(5))
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Expanded(
                              child: FButton(
                                variant: .ghost,
                                size: .sm,
                                onPress: () => ref
                                    .read(
                                      hadithSessionControllerProvider.notifier,
                                    )
                                    .setQuery(query),
                                child: Flexible(
                                  child: Row(
                                    children: [
                                      Icon(
                                        FLucideIcons.history,
                                        size: 14,
                                        color: context
                                            .theme
                                            .colors
                                            .mutedForeground,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          query,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: context
                                              .theme
                                              .typography
                                              .body
                                              .sm
                                              .copyWith(
                                                color: context
                                                    .theme
                                                    .colors
                                                    .mutedForeground,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            FButton.icon(
                              variant: .ghost,
                              semanticsLabel:
                                  hadithRemoveRecentSearchSemanticsLabel(
                                    query,
                                    context.l10n,
                                  ),
                              semanticsTooltip:
                                  hadithRemoveRecentSearchSemanticsLabel(
                                    query,
                                    context.l10n,
                                  ),
                              onPress: () async {
                                try {
                                  await ref
                                      .read(
                                        hadithRecentSearchesStoreProvider
                                            .notifier,
                                      )
                                      .removeQuery(query);
                                } catch (_) {
                                  if (context.mounted)
                                    showFToast(
                                      context: context,
                                      title: Text(
                                        context.l10n.hadithRecentsUpdateFailed,
                                      ),
                                    );
                                }
                              },
                              child: const Icon(FLucideIcons.x, size: 14),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
      );
}

Future<void> _clearRecents(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final confirmed = await showFDialog<bool>(
    context: context,
    builder: (dialogContext, style, animation) => FDialog(
      style: style,
      animation: animation,
      builder: (context, dialogStyle) => ForuiDialogLayout(
        style: dialogStyle,
        expandActions: true,
        title: Text(l10n.hadithClearRecentsConfirm),
        body: const SizedBox.shrink(),
        actions: [
          FButton(
            variant: .secondary,
            onPress: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FButton(
            variant: .destructive,
            onPress: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.hadithClearAllRecents),
          ),
        ],
      ),
    ),
  );
  if (confirmed != true || !context.mounted) return;
  try {
    await ref.read(hadithRecentSearchesStoreProvider.notifier).clearAll();
  } catch (_) {
    if (context.mounted)
      showFToast(context: context, title: Text(l10n.hadithRecentsUpdateFailed));
  }
}
