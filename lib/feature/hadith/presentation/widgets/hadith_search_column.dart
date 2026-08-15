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
    final mode = ref.watch(
      hadithSessionControllerProvider.select((session) => session.mode),
    );

    return NonSelectable(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (mode == HadithViewMode.bookmarks)
              const _SpecificModeHeader(mode: HadithViewMode.bookmarks)
            else if (mode == HadithViewMode.specificList)
              const _SpecificModeHeader(mode: HadithViewMode.specificList)
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

class _SpecificModeHeader extends ConsumerWidget {
  const _SpecificModeHeader({required this.mode});

  final HadithViewMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final l10n = context.l10n;
    final screenController = ref.read(hadithSessionControllerProvider.notifier);
    final title = switch (mode) {
      HadithViewMode.bookmarks => l10n.bookmarks,
      HadithViewMode.specificList => l10n.hadithSimilar,
      HadithViewMode.search => l10n.hadithBackToSearch,
    };

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
          title,
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

  static const _filterPopoverGroupId = 'hadith-filter-popover';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSearchMode = ref.watch(
      hadithSessionControllerProvider.select((s) => s.isSearchMode),
    );
    final sessionQuery = ref.watch(
      hadithSessionControllerProvider.select((s) => s.query),
    );
    final activeFilterCount = ref.watch(
      hadithSessionControllerProvider.select((s) => s.filters.activeCount),
    );
    final searchBusy = ref.watch(
      hadithSessionControllerProvider.select((s) => s.searchBusy),
    );
    final queryController = useTextEditingController();
    useListenable(queryController);
    final screenController = ref.read(hadithSessionControllerProvider.notifier);
    final searchFocusNode = useFocusNode();
    final focusSearch = useCallback(
      searchFocusNode.requestFocus,
      [searchFocusNode],
    );

    useRegisterAppSearchFocus(focusSearch, enabled: isSearchMode);

    final l10n = context.l10n;
    final canSearch = queryController.text.trim().isNotEmpty;

    void commitQuery(String query) {
      final value = query.trim();
      if (value.isEmpty) return;
      unawaited(screenController.setQuery(value));
    }

    useEffect(() {
      if (queryController.text != sessionQuery) {
        queryController.text = sessionQuery;
      }
      return null;
    }, [sessionQuery]);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compactActions =
            constraints.maxWidth < context.theme.breakpoints.md;

        final searchButton = FButton.icon(
          semanticsTooltip: l10n.hadithSearchAction,
          onPress: canSearch ? () => commitQuery(queryController.text) : null,
          semanticsLabel: compactActions ? l10n.hadithSearchAction : null,
          child: compactActions
              ? const HadithDecorExcludeSemantics(
                  child: Icon(FLucideIcons.search, size: 18),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: AppSpacing.xs,
                  children: [
                    const Icon(FLucideIcons.search, size: 16),
                    Text(l10n.hadithSearchAction),
                  ],
                ),
        );

        return Row(
          spacing: AppSpacing.sm,
          children: [
            Expanded(
              child: FTextField(
                focusNode: searchFocusNode,
                // Stay editable while a Dorar request is in flight so the
                // user can revise the draft and submit a newer query.
                control: .managed(controller: queryController),
                onSubmit: commitQuery,
                hint: l10n.hadithSearchHint,
              ),
            ),
            if (compactActions)
              FTooltip(
                tipBuilder: (_, _) => Text(l10n.hadithSearchAction),
                child: searchButton,
              )
            else
              searchButton,
            if (isSearchMode)
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
            if (useSplitLayout && isSearchMode)
              FButton.icon(
                onPress: searchBusy
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
            else if (isSearchMode)
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
                  onPress: searchBusy ? null : controller.toggle,
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
    final isSearchMode = ref.watch(
      hadithSessionControllerProvider.select((s) => s.isSearchMode),
    );
    if (!isSearchMode) return const SizedBox.shrink();

    final sessionQuery = ref.watch(
      hadithSessionControllerProvider.select((s) => s.query),
    );
    final activeFilterCount = ref.watch(
      hadithSessionControllerProvider.select((s) => s.filters.activeCount),
    );
    final resultsCount = ref.watch(
      hadithSessionControllerProvider.select(
        (s) => s.searchOutcome.value?.results.length ?? 0,
      ),
    );
    final l10n = context.l10n;
    final showRecents = sessionQuery.trim().isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.xs),
        if (sessionQuery.trim().isNotEmpty || activeFilterCount > 0)
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
    final filters = ref.watch(
      hadithSessionControllerProvider.select((s) => s.filters),
    );
    final filterInteractionsEnabled = ref.watch(
      hadithSessionControllerProvider.select(
        (s) => s.filterInteractionsEnabled,
      ),
    );
    final theme = context.theme;
    final l10n = context.l10n;
    final chips = buildActiveHadithFilterChips(filters, l10n);

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
                      onPress: filterInteractionsEnabled
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
                      onPress: filterInteractionsEnabled
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
                      onPress: filterInteractionsEnabled
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
    final searchBusy = ref.watch(
      hadithSessionControllerProvider.select((s) => s.searchBusy),
    );
    final recentSearches = ref.watch(hadithRecentSearchesStoreProvider);

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
                onPress: searchBusy
                    ? null
                    : () => unawaited(
                        ref
                            .read(hadithRecentSearchesStoreProvider.notifier)
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
    final searchBusy = ref.watch(
      hadithSessionControllerProvider.select((s) => s.searchBusy),
    );
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
            onPress: searchBusy
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
              child: showRemove && !searchBusy
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
                              .read(hadithRecentSearchesStoreProvider.notifier)
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
