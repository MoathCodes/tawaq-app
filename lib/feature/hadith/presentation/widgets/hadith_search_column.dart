import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/hooks/hooks.dart';
import 'package:tawaq/core/layout/viewport_dialog_constraints.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/shortcuts/shortcuts.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_filters.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_persisted_settings.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_session_state.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_screen_settings_provider.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/filters/hadith_filter_form.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/hadith_accessibility.dart';
import 'package:tawaq/theme/theme.dart';

/// Search header with query field, bookmarks chrome, filter chips, and recents.
class HadithSearchColumn extends ConsumerWidget {
  const HadithSearchColumn({required this.useSplitLayout, super.key});

  final bool useSplitLayout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBookmarksMode = ref.watch(
      hadithSessionControllerProvider.select(
        (session) => session.mode == HadithViewMode.bookmarks,
      ),
    );

    return NonSelectable(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isBookmarksMode)
              const _BookmarksHeader()
            else ...[
              _QueryField(useSplitLayout: useSplitLayout),
              _SearchMeta(useSplitLayout: useSplitLayout),
            ],
          ],
        ),
      ),
    );
  }
}

class _BookmarksHeader extends ConsumerWidget {
  const _BookmarksHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final l10n = context.l10n;
    final screenController = ref.read(hadithSessionControllerProvider.notifier);

    return Row(
      spacing: AppSpacing.sm,
      children: [
        FButton.icon(
          variant: FButtonVariant.ghost,
          onPress: () => unawaited(screenController.exitSpecificMode()),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.xs,
            children: [
              const Icon(FLucideIcons.chevronLeft, size: 16),
              Text(l10n.hadithBackToSearch),
            ],
          ),
        ),
        Text(
          l10n.bookmarks,
          style: theme.typography.body.lg.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _QueryField extends HookConsumerWidget {
  const _QueryField({required this.useSplitLayout});

  final bool useSplitLayout;

  static const _queryDebounceDuration = Duration(milliseconds: 420);
  static const _filterPopoverGroupId = 'hadith-filter-popover';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(hadithSessionControllerProvider);
    final queryController = useTextEditingController();
    useListenable(queryController);
    final screenController = ref.read(hadithSessionControllerProvider.notifier);
    final searchFocusNode = useFocusNode();
    final focusSearch = useCallback(
      searchFocusNode.requestFocus,
      [searchFocusNode],
    );

    useRegisterAppSearchFocus(focusSearch, enabled: session.isSearchMode);

    useEffect(() {
      if (queryController.text != session.query) {
        queryController.text = session.query;
      }
      return null;
    }, [session.query]);

    final theme = context.theme;
    final l10n = context.l10n;
    final activeFilterCount = session.filters.activeCount;

    void commitQuery(String query) {
      unawaited(screenController.setQuery(query));
    }

    final debouncedCommitQuery = useDebouncedCallback(
      () => commitQuery(queryController.text),
      duration: _queryDebounceDuration,
    );

    void onQueryChanged(String query) {
      debouncedCommitQuery();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final compactActions = constraints.maxWidth < context.theme.breakpoints.md;

        return Row(
          spacing: AppSpacing.sm,
          children: [
            Expanded(
              child: FTextField(
                focusNode: searchFocusNode,
                enabled: !session.searchBusy,
                control: .managed(
                  controller: queryController,
                  onChange: (value) => onQueryChanged(value.text),
                ),
                onSubmit: session.searchBusy ? null : commitQuery,
                hint: l10n.hadithSearchHint,
                prefixBuilder: (_, _, _) => HadithDecorExcludeSemantics(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    child: Icon(
                      FLucideIcons.search,
                      size: 18,
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                ),
              ),
            ),
            if (session.isSearchMode)
              FButton.icon(
                onPress: () => unawaited(screenController.openBookmarks()),
                semanticsLabel: compactActions ? l10n.bookmarks : null,
                child: compactActions
                    ? const HadithDecorExcludeSemantics(
                        child: Icon(FLucideIcons.bookmark, size: 18),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: AppSpacing.xs,
                        children: [
                          const Icon(FLucideIcons.bookmark, size: 16),
                          Text(l10n.bookmarks),
                        ],
                      ),
              ),
            if (useSplitLayout && session.isSearchMode)
              FButton.icon(
                onPress: session.searchBusy
                    ? null
                    : () {
                        ref
                            .read(hadithScreenSettingsProvider.notifier)
                            .setActiveTab(HadithPanelTab.filters);
                      },
                semanticsLabel: compactActions ? l10n.hadithOpenFilters : null,
                child: compactActions
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: AppSpacing.xs,
                        children: [
                          const Icon(
                            FLucideIcons.slidersHorizontal,
                            size: 18,
                          ),
                          if (activeFilterCount > 0)
                            _FilterCountBadge(count: activeFilterCount),
                        ],
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: AppSpacing.xs,
                        children: [
                          const Icon(FLucideIcons.slidersHorizontal, size: 16),
                          Text(l10n.hadithOpenFilters),
                          if (activeFilterCount > 0)
                            _FilterCountBadge(count: activeFilterCount),
                        ],
                      ),
              )
            else if (session.isSearchMode)
              FPopover(
                groupId: _filterPopoverGroupId,
                popoverAnchor: Alignment.topRight,
                childAnchor: Alignment.bottomRight,
                popoverBuilder: (_, controller) => ConstrainedBox(
                  constraints: dialogConstraints(
                    context,
                    preferredWidth: 420,
                    minWidth: 320,
                    preferredHeight: 620,
                  ),
                  child: HadithFilterPanel(
                    onClose: () => unawaited(controller.hide()),
                  ),
                ),
                builder: (_, controller, child) => FButton.icon(
                  onPress: session.searchBusy ? null : controller.toggle,
                  semanticsLabel: l10n.hadithOpenFilters,
                  child: child,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: AppSpacing.xs,
                  children: [
                    const Icon(FLucideIcons.slidersHorizontal, size: 16),
                    Text(l10n.hadithOpenFilters),
                    if (activeFilterCount > 0)
                      _FilterCountBadge(count: activeFilterCount),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _FilterCountBadge extends StatelessWidget {
  const _FilterCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: theme.colors.primary,
        borderRadius: theme.radii.full,
      ),
      child: Text(
        '$count',
        style: theme.typography.body.xs.copyWith(
          color: theme.colors.primaryForeground,
        ),
      ),
    );
  }
}

class _SearchMeta extends ConsumerWidget {
  const _SearchMeta({required this.useSplitLayout});

  final bool useSplitLayout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(hadithSessionControllerProvider);
    if (!session.isSearchMode) return const SizedBox.shrink();

    final visibleResults = ref.hadithVisibleResults(session);
    final resultsCount = switch (visibleResults) {
      AsyncData(:final value) => value.length,
      _ => 0,
    };
    final l10n = context.l10n;
    final activeFilterCount = session.filters.activeCount;
    final showRecents = session.query.trim().isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.xs),
        if (session.query.trim().isNotEmpty || activeFilterCount > 0)
          Semantics(
            label: l10n.hadithResultsCount(resultsCount),
            child: HadithDecorExcludeSemantics(
              child: FBadge(
                variant: resultsCount > 0 ? .secondary : .outline,
                child: Text(l10n.hadithResultsCount(resultsCount)),
              ),
            ),
          ),
        const _ActiveFilterChips(),
        if (showRecents) ...[
          if (activeFilterCount > 0) const SizedBox(height: AppSpacing.xs),
          _RecentSearchesSection(useSplitLayout: useSplitLayout),
        ],
      ],
    );
  }
}

class _ActiveFilterChips extends ConsumerWidget {
  const _ActiveFilterChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(hadithSessionControllerProvider);
    final theme = context.theme;
    final l10n = context.l10n;
    final chips = buildActiveHadithFilterChips(session.filters, l10n);

    if (chips.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < context.theme.breakpoints.md;

        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.xs,
            children: [
              Row(
                spacing: AppSpacing.sm,
                children: [
                  Semantics(
                    label: compact ? l10n.hadithActiveFilters : null,
                    child: Icon(
                      FLucideIcons.slidersHorizontal,
                      size: 12,
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                  if (!compact)
                    Text(
                      l10n.hadithActiveFilters,
                      style: theme.typography.body.xs.copyWith(
                        color: theme.colors.mutedForeground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (!compact) const Spacer(),
                  if (!compact)
                    FButton(
                      variant: FButtonVariant.ghost,
                      size: FButtonSizeVariant.sm,
                      mainAxisSize: MainAxisSize.min,
                      semanticsLabel: l10n.hadithClearAllFilters,
                      onPress: session.filterInteractionsEnabled
                          ? () {
                              unawaited(
                                ref
                                    .read(
                                      hadithSessionControllerProvider.notifier,
                                    )
                                    .clearFilters(),
                              );
                            }
                          : null,
                      child: Text(l10n.hadithClearAllFilters),
                    ),
                ],
              ),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final chip in chips)
                    FButton(
                      variant: FButtonVariant.outline,
                      size: FButtonSizeVariant.sm,
                      mainAxisSize: MainAxisSize.min,
                      semanticsLabel: hadithFilterChipSemanticsLabel(
                        chip.label,
                        l10n,
                      ),
                      onPress: session.filterInteractionsEnabled
                          ? () {
                              unawaited(
                                ref
                                    .read(
                                      hadithSessionControllerProvider.notifier,
                                    )
                                    .setFilters(
                                      chip.nextFilters,
                                      debounced: false,
                                    ),
                              );
                            }
                          : null,
                      suffix: const HadithDecorExcludeSemantics(
                        child: Icon(FLucideIcons.x, size: 11),
                      ),
                      child: HadithDecorExcludeSemantics(
                        child: Text(chip.label),
                      ),
                    ),
                  if (compact)
                    FButton.icon(
                      variant: FButtonVariant.ghost,
                      size: FButtonSizeVariant.sm,
                      semanticsLabel: l10n.hadithClearAllFilters,
                      onPress: session.filterInteractionsEnabled
                          ? () {
                              unawaited(
                                ref
                                    .read(
                                      hadithSessionControllerProvider.notifier,
                                    )
                                    .clearFilters(),
                              );
                            }
                          : null,
                      child: const HadithDecorExcludeSemantics(
                        child: Icon(FLucideIcons.rotateCcw, size: 12),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RecentSearchesSection extends ConsumerWidget {
  const _RecentSearchesSection({required this.useSplitLayout});

  final bool useSplitLayout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final l10n = context.l10n;
    final session = ref.watch(hadithSessionControllerProvider);
    final recentSearches = session.isSearchMode
        ? ref.watch(hadithRecentSearchesProvider)
        : const AsyncData<List<String>>(<String>[]);

    return recentSearches.when(
      data: (items) {
        if (items.isEmpty) {
          return Text(
            l10n.hadithNoRecentSearches,
            style: theme.typography.body.xs.copyWith(
              color: theme.colors.mutedForeground,
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.xs,
          children: [
            _SearchMetaSectionHeader(
              icon: FLucideIcons.history,
              title: l10n.hadithRecentSearches,
              trailing: FButton(
                variant: FButtonVariant.ghost,
                size: FButtonSizeVariant.sm,
                mainAxisSize: MainAxisSize.min,
                onPress: session.searchBusy
                    ? null
                    : () => unawaited(
                        ref
                            .read(hadithRecentSearchesProvider.notifier)
                            .clearAll(),
                      ),
                child: Text(l10n.hadithClearAllRecents),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                spacing: AppSpacing.xs,
                children: [
                  for (final query in items)
                    _RecentSearchChip(
                      query: query,
                      useSplitLayout: useSplitLayout,
                    ),
                ],
              ),
            ),
          ],
        );
      },
      error: (_, _) => const SizedBox.shrink(),
      loading: () => const SizedBox.shrink(),
    );
  }
}

class _RecentSearchChip extends HookConsumerWidget {
  const _RecentSearchChip({
    required this.query,
    required this.useSplitLayout,
  });

  final String query;
  final bool useSplitLayout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final l10n = context.l10n;
    final session = ref.watch(hadithSessionControllerProvider);
    final screenController = ref.read(hadithSessionControllerProvider.notifier);
    final (:isHovered, :setHovered) = useHoverState();
    final showRemove = isHovered || !useSplitLayout;

    return MouseRegion(
      onEnter: (_) => setHovered(value: true),
      onExit: (_) => setHovered(value: false),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FButton(
            variant: FButtonVariant.ghost,
            size: FButtonSizeVariant.sm,
            mainAxisSize: MainAxisSize.min,
            semanticsLabel: hadithRecentSearchChipSemanticsLabel(query, l10n),
            onPress: session.searchBusy
                ? null
                : () {
                    unawaited(screenController.setQuery(query));
                  },
            child: HadithDecorExcludeSemantics(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: AppSpacing.xs,
                children: [
                  Icon(
                    FLucideIcons.search,
                    size: 11,
                    color: theme.colors.mutedForeground,
                  ),
                  Text(query, softWrap: false),
                ],
              ),
            ),
          ),
          ClipRect(
            child: AnimatedSize(
              duration: theme.durations.fast,
              curve: Curves.easeOut,
              alignment: AlignmentDirectional.centerStart,
              child: showRemove && !session.searchBusy
                  ? FButton.icon(
                      variant: FButtonVariant.ghost,
                      size: FButtonSizeVariant.sm,
                      semanticsLabel: hadithRemoveRecentSearchSemanticsLabel(
                        query,
                        l10n,
                      ),
                      onPress: () {
                        unawaited(
                          ref
                              .read(hadithRecentSearchesProvider.notifier)
                              .removeQuery(query),
                        );
                      },
                      child: const HadithDecorExcludeSemantics(
                        child: Icon(FLucideIcons.x, size: 12),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchMetaSectionHeader extends StatelessWidget {
  const _SearchMetaSectionHeader({
    required this.icon,
    required this.title,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Row(
      children: [
        Icon(icon, size: 12, color: theme.colors.mutedForeground),
        const SizedBox(width: AppSpacing.xs),
        Text(
          title,
          style: theme.typography.body.xs.copyWith(
            color: theme.colors.mutedForeground,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (trailing != null) ...[
          const Spacer(),
          trailing!,
        ],
      ],
    );
  }
}
