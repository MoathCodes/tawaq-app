part of 'hadith_screen.dart';

class _SearchHeader extends HookConsumerWidget {
  const _SearchHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final desktop = isAtLeast(context, FBreakpoint.lg);
    final queryController = useTextEditingController();
    useListenable(queryController);
    final filters = ref.watch(hadithFiltersProvider);
    final viewMode = ref.watch(hadithViewModeProvider);
    final isSearchMode = ref.watch(hadithIsSearchModeProvider);
    final searchBusy = ref.watch(hadithSearchBusyProvider);
    final queryFromState = ref.watch(hadithQueryProvider);
    final isBookmarksMode = viewMode == HadithViewMode.bookmarks;
    final screenController = ref.read(hadithScreenControllerProvider.notifier);
    final visibleResults = ref.watch(hadithVisibleResultsProvider);
    final resultsCount = switch (visibleResults) {
      AsyncData(:final value) => value.length,
      _ => 0,
    };
    final searchFocusNode = useFocusNode();
    final focusSearch = useCallback(
      searchFocusNode.requestFocus,
      [searchFocusNode],
    );

    useRegisterAppSearchFocus(focusSearch, enabled: !isBookmarksMode);

    useEffect(() {
      if (queryController.text != queryFromState) {
        queryController.text = queryFromState;
      }
      return null;
    }, [queryFromState]);

    final theme = context.theme;
    final l10n = context.l10n;
    final activeFilterCount = filters.activeCount;
    final fieldQuery = queryController.text;

    void onQueryChanged(String query) {
      unawaited(
        ref.read(hadithScreenControllerProvider.notifier).setQuery(query),
      );
    }

    void onQuerySubmitted(String query) {
      unawaited(
        ref
            .read(hadithScreenControllerProvider.notifier)
            .setQuery(query, debounced: false),
      );
    }

    return NonSelectable(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isBookmarksMode)
              Row(
                spacing: AppSpacing.sm,
                children: [
                  FButton.icon(
                    variant: FButtonVariant.ghost,
                    onPress: () =>
                        unawaited(screenController.exitSpecificMode()),
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
                    style: theme.typography.lg.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final compactActions =
                      constraints.maxWidth < context.theme.breakpoints.md;

                  return Row(
                    spacing: AppSpacing.sm,
                    children: [
                      Expanded(
                        child: FTextField(
                          focusNode: searchFocusNode,
                          enabled: !searchBusy,
                          control: .managed(
                            controller: queryController,
                            onChange: (value) => onQueryChanged(value.text),
                          ),
                          onSubmit: searchBusy ? null : onQuerySubmitted,
                          hint: l10n.hadithSearchHint,
                          label: Text(l10n.hadithSearchHint),
                          prefixBuilder: (_, _, _) =>
                              HadithDecorExcludeSemantics(
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
                      if (isSearchMode)
                        FButton.icon(
                          onPress: () =>
                              unawaited(screenController.openBookmarks()),
                          semanticsLabel:
                              compactActions ? l10n.bookmarks : null,
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
                      if (desktop && isSearchMode)
                        FButton.icon(
                          onPress: searchBusy
                              ? null
                              : () {
                                  screenController.setActiveTab(
                                    HadithPanelTab.filters,
                                  );
                                },
                          semanticsLabel:
                              compactActions ? l10n.hadithOpenFilters : null,
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
                                      _CountDot(count: activeFilterCount),
                                  ],
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  spacing: AppSpacing.xs,
                                  children: [
                                    const Icon(
                                      FLucideIcons.slidersHorizontal,
                                      size: 16,
                                    ),
                                    Text(l10n.hadithOpenFilters),
                                    if (activeFilterCount > 0) ...[
                                      _CountDot(count: activeFilterCount),
                                    ],
                                  ],
                                ),
                        )
                      else if (isSearchMode)
                        FPopover(
                          groupId: HadithPage._filterPopoverGroupId,
                          popoverAnchor: Alignment.topRight,
                          childAnchor: Alignment.bottomRight,
                          popoverBuilder: (_, controller) => ConstrainedBox(
                            constraints: const BoxConstraints(
                              minWidth: 360,
                              maxWidth: 420,
                              maxHeight: 620,
                            ),
                            child: _FilterPanel(
                              showHeader: true,
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
                              const Icon(
                                FLucideIcons.slidersHorizontal,
                                size: 16,
                              ),
                              Text(l10n.hadithOpenFilters),
                              if (activeFilterCount > 0) ...[
                                _CountDot(count: activeFilterCount),
                              ],
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            if (isSearchMode) ...[
              const SizedBox(height: AppSpacing.xs),
              if (fieldQuery.trim().isNotEmpty || activeFilterCount > 0)
                Semantics(
                  label: l10n.hadithResultsCount(resultsCount),
                  child: HadithDecorExcludeSemantics(
                    child: FBadge(
                      variant: resultsCount > 0 ? .secondary : .outline,
                      child: Text(l10n.hadithResultsCount(resultsCount)),
                    ),
                  ),
                ),
              const _ActiveFiltersSection(),
              if (fieldQuery.trim().isEmpty) ...[
                if (activeFilterCount > 0)
                  const SizedBox(height: AppSpacing.xs),
                const _RecentSearches(),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _CountDot extends StatelessWidget {
  const _CountDot({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return HadithDecorExcludeSemantics(
      child: Container(
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
          style: theme.typography.xs.copyWith(
            color: theme.colors.primaryForeground,
          ),
        ),
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
          style: theme.typography.xs.copyWith(
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

class _RecentSearchChip extends HookConsumerWidget {
  const _RecentSearchChip({required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final l10n = context.l10n;
    final interactionsEnabled = !ref.watch(hadithSearchBusyProvider);
    final screenController = ref.read(hadithScreenControllerProvider.notifier);
    final (:isHovered, :setHovered) = useHoverState();
    final showRemove = isHovered || isLessThan(context, FBreakpoint.lg);

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
            onPress: interactionsEnabled
                ? () {
                    unawaited(
                      screenController.setQuery(query, debounced: false),
                    );
                  }
                : null,
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
              child: showRemove && interactionsEnabled
                  ? FButton.icon(
                        variant: FButtonVariant.ghost,
                        size: FButtonSizeVariant.sm,
                        semanticsLabel: hadithRemoveRecentSearchSemanticsLabel(
                          query,
                          l10n,
                        ),
                        onPress: () {
                          unawaited(screenController.removeRecentSearch(query));
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

class _RecentSearches extends ConsumerWidget {
  const _RecentSearches();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final l10n = context.l10n;
    final recentSearches = ref.watch(hadithVisibleRecentSearchesProvider);
    final interactionsEnabled = !ref.watch(hadithSearchBusyProvider);
    final screenController = ref.read(hadithScreenControllerProvider.notifier);

    return recentSearches.when(
      data: (items) {
        if (items.isEmpty) {
          return Text(
            l10n.hadithNoRecentSearches,
            style: theme.typography.xs.copyWith(
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
                onPress: interactionsEnabled
                    ? () => unawaited(screenController.clearRecentSearches())
                    : null,
                child: Text(l10n.hadithClearAllRecents),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                spacing: AppSpacing.xs,
                children: [
                  for (final query in items)
                    _RecentSearchChip(query: query),
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

class _FilterPanel extends ConsumerWidget {
  const _FilterPanel({
    this.onClose,
    this.showHeader = false,
  });

  final VoidCallback? onClose;
  final bool showHeader;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(hadithFiltersProvider);
    final searchBusy = ref.watch(hadithSearchBusyProvider);
    final panelEnabled = !searchBusy;

    void updateFilters(HadithFilters next) {
      if (!panelEnabled) return;
      unawaited(
        ref.read(hadithScreenControllerProvider.notifier).setFilters(next),
      );
    }

    final theme = context.theme;
    final l10n = context.l10n;
    final scrollableFields = <Widget>[
      Text(
        l10n.hadithSearchMethod,
        style: theme.typography.sm.copyWith(
          color: theme.colors.mutedForeground,
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      FTabs(
        control: FTabControl.lifted(
          index: SearchMethod.values.indexOf(filters.searchMethod),
          onChange: (index) {
            if (!panelEnabled) return;
            updateFilters(
              filters.copyWith(searchMethod: SearchMethod.values[index]),
            );
          },
        ),
        children: [
          for (final method in SearchMethod.values)
            FTabEntry(
              label: Text(method.getLocaleName(l10n)),
              child: const SizedBox.shrink(),
            ),
        ],
      ),
      const SizedBox(height: AppSpacing.lg),
      Text(
        l10n.hadithScope,
        style: theme.typography.sm.copyWith(
          color: theme.colors.mutedForeground,
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      FSelect<SearchZone>.search(
        enabled: panelEnabled,
        hint: l10n.hadithScope,
        items: {
          for (final zone in SearchZone.values) zone.getLocaleName(l10n): zone,
        },
        control: FSelectControl<SearchZone>.lifted(
          value: filters.zone,
          onChange: (value) {
            if (!panelEnabled || value == null) return;
            updateFilters(filters.copyWith(zone: value));
          },
        ),
        filter: (query) {
          final lower = query.trim().toLowerCase();
          if (lower.isEmpty) return SearchZone.values;
          return SearchZone.values.where(
            (zone) => zone.getLocaleName(l10n).toLowerCase().contains(lower),
          );
        },
      ),
      const SizedBox(height: AppSpacing.md),
      FTile(
        title: Text(l10n.hadithSpecialist),
        subtitle: Text(l10n.hadithSpecialistHint),
        suffix: FSwitch(
          enabled: panelEnabled,
          value: filters.specialist,
          onChange: (value) {
            if (!panelEnabled) return;
            updateFilters(filters.copyWith(specialist: value));
          },
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      FMultiSelect<HadithDegree>.search(
        enabled: panelEnabled,
        {
          for (final degree in HadithDegree.values.where(
            (value) => value != HadithDegree.all,
          ))
            degree.getLocaleName(l10n): degree,
        },
        hint: Text(l10n.hadithDegrees),
        control: FMultiValueControl<HadithDegree>.lifted(
          value: filters.degrees.toSet(),
          onChange: (values) {
            if (!panelEnabled) return;
            updateFilters(
              filters.copyWith(degrees: values.toList(growable: false)),
            );
          },
        ),
        filter: (query) {
          final lower = query.trim().toLowerCase();
          final values = HadithDegree.values.where(
            (value) => value != HadithDegree.all,
          );
          if (lower.isEmpty) return values;
          return values.where(
            (value) => value.getLocaleName(l10n).toLowerCase().contains(lower),
          );
        },
      ),
      const SizedBox(height: AppSpacing.lg),
      _LookupSection(
        field: _HadithLookupField.scholars,
        title: l10n.hadithScholars,
        hint: l10n.hadithTypeToSearch,
      ),
      const SizedBox(height: AppSpacing.md),
      _LookupSection(
        field: _HadithLookupField.books,
        title: l10n.hadithBooks,
        hint: l10n.hadithTypeToSearch,
      ),
      const SizedBox(height: AppSpacing.md),
      _LookupSection(
        field: _HadithLookupField.rawi,
        title: l10n.hadithNarrators,
        hint: l10n.hadithTypeToSearch,
      ),
    ];

    final panel = NonSelectable(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showHeader) _FilterHeader(onClose: onClose),
          Expanded(
            child: ListView(
              padding: const EdgeInsetsDirectional.only(
                start: AppSpacing.sm,
                end: AppSpacing.sm,
                bottom: AppSpacing.md,
              ),
              children: scrollableFields,
            ),
          ),
          const Padding(
            padding: EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.sm),
            child: FDivider(),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.md,
            ),
            child: FButton(
              variant: FButtonVariant.outline,
              onPress: panelEnabled
                  ? () {
                      unawaited(
                        ref
                            .read(hadithScreenControllerProvider.notifier)
                            .clearFilters(),
                      );
                    }
                  : null,
              child: Text(l10n.hadithResetFilters),
            ),
          ),
        ],
      ),
    );

    if (showHeader) {
      final fallbackHeight = (MediaQuery.sizeOf(context).height * 0.7).clamp(
        360.0,
        620.0,
      );
      return SizedBox(
        height: fallbackHeight,
        child: panel,
      );
    }

    return panel;
  }
}

class _FilterHeader extends StatelessWidget {
  const _FilterHeader({required this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            context.l10n.hadithFilterTab,
            style: theme.typography.xl,
          ),
          if (onClose != null)
            FButton.icon(
              variant: FButtonVariant.ghost,
              semanticsLabel: hadithCloseFiltersSemanticsLabel(context.l10n),
              onPress: onClose,
              child: const HadithDecorExcludeSemantics(
                child: Icon(FLucideIcons.x, size: 16),
              ),
            ),
        ],
      ),
    );
  }
}

enum _HadithLookupField { scholars, books, rawi }

class _LookupSection extends ConsumerWidget {
  const _LookupSection({
    required this.field,
    required this.title,
    required this.hint,
  });

  final _HadithLookupField field;
  final String title;
  final String hint;

  List<HadithLookupRef> _selected(HadithFilters filters) => switch (field) {
    _HadithLookupField.scholars => filters.scholars,
    _HadithLookupField.books => filters.books,
    _HadithLookupField.rawi => filters.rawi,
  };

  HadithFilters _withSelected(
    HadithFilters filters,
    List<HadithLookupRef> selected,
  ) => switch (field) {
    _HadithLookupField.scholars => filters.copyWith(scholars: selected),
    _HadithLookupField.books => filters.copyWith(books: selected),
    _HadithLookupField.rawi => filters.copyWith(rawi: selected),
  };

  Future<Iterable<HadithLookupRef>> _lookup(WidgetRef ref, String query) =>
      switch (field) {
        _HadithLookupField.scholars =>
          ref.read(hadithScholarsLookupProvider(query).future),
        _HadithLookupField.books =>
          ref.read(hadithBooksLookupProvider(query).future),
        _HadithLookupField.rawi =>
          ref.read(hadithRawiLookupProvider(query).future),
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final filters = ref.watch(hadithFiltersProvider);
    final interactionsEnabled = !ref.watch(hadithSearchBusyProvider);
    final selected = _selected(filters);
    final selectedSet = selected.toSet();

    void updateFilters(HadithFilters next) {
      if (!interactionsEnabled) return;
      unawaited(
        ref.read(hadithScreenControllerProvider.notifier).setFilters(next),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.typography.sm.copyWith(
            color: theme.colors.mutedForeground,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        FMultiSelect<HadithLookupRef>.searchBuilder(
          enabled: interactionsEnabled,
          hint: Text(hint),
          format: (item) => Text(item.name),
          control: FMultiValueControl<HadithLookupRef>.lifted(
            value: selectedSet,
            onChange: (values) {
              if (!interactionsEnabled) return;
              values
                  .where((value) => !selectedSet.contains(value))
                  .forEach((item) {
                    if (selected.any((entry) => entry.id == item.id)) {
                      return;
                    }
                    updateFilters(
                      _withSelected(filters, [...selected, item]),
                    );
                  });

              selected
                  .where((value) => !values.contains(value))
                  .forEach((item) {
                    updateFilters(
                      _withSelected(
                        filters,
                        selected
                            .where((entry) => entry.id != item.id)
                            .toList(growable: false),
                      ),
                    );
                  });
            },
          ),
          filter: (query) => _lookup(ref, query),
          contentBuilder: (_, _, data) => [
            for (final item in data)
              FSelectItem(title: Text(item.name), value: item),
          ],
          contentLoadingBuilder: (_, _) => const FCircularProgress(),
          contentEmptyBuilder: (_, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Text(
              context.l10n.noResults,
              style: theme.typography.sm.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActiveFiltersSection extends ConsumerWidget {
  const _ActiveFiltersSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(hadithFiltersProvider);
    final interactionsEnabled = ref.watch(
      hadithFilterInteractionsEnabledProvider,
    );
    final theme = context.theme;
    final l10n = context.l10n;
    final chips = _buildActiveFilterChips(filters, l10n);

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
                      style: theme.typography.xs.copyWith(
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
                      onPress: interactionsEnabled
                          ? () {
                              unawaited(
                                ref
                                    .read(
                                      hadithScreenControllerProvider.notifier,
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
                      onPress: interactionsEnabled
                          ? () {
                              unawaited(
                                ref
                                    .read(
                                      hadithScreenControllerProvider.notifier,
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
                      onPress: interactionsEnabled
                          ? () {
                              unawaited(
                                ref
                                    .read(
                                      hadithScreenControllerProvider.notifier,
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

List<_FilterActionChip> _buildActiveFilterChips(
  HadithFilters filters,
  AppLocalizations l10n,
) {
  final chips = <_FilterActionChip>[];

  if (filters.searchMethod != SearchMethod.anyWord) {
    chips.add(
      _FilterActionChip(
        label: filters.searchMethod.getLocaleName(l10n),
        nextFilters: filters.copyWith(searchMethod: SearchMethod.anyWord),
      ),
    );
  }

  if (filters.zone != SearchZone.all) {
    chips.add(
      _FilterActionChip(
        label: filters.zone.getLocaleName(l10n),
        nextFilters: filters.copyWith(zone: SearchZone.all),
      ),
    );
  }

  if (filters.specialist) {
    chips.add(
      _FilterActionChip(
        label: l10n.hadithSpecialist,
        nextFilters: filters.copyWith(specialist: false),
      ),
    );
  }

  for (final degree in filters.degrees) {
    chips.add(
      _FilterActionChip(
        label: degree.getLocaleName(l10n),
        nextFilters: filters.copyWith(
          degrees: filters.degrees
              .where((entry) => entry != degree)
              .toList(growable: false),
        ),
      ),
    );
  }

  for (final scholar in filters.scholars) {
    chips.add(
      _FilterActionChip(
        label: scholar.name,
        nextFilters: filters.copyWith(
          scholars: filters.scholars
              .where((entry) => entry.id != scholar.id)
              .toList(growable: false),
        ),
      ),
    );
  }

  for (final book in filters.books) {
    chips.add(
      _FilterActionChip(
        label: book.name,
        nextFilters: filters.copyWith(
          books: filters.books
              .where((entry) => entry.id != book.id)
              .toList(growable: false),
        ),
      ),
    );
  }

  for (final rawi in filters.rawi) {
    chips.add(
      _FilterActionChip(
        label: rawi.name,
        nextFilters: filters.copyWith(
          rawi: filters.rawi
              .where((entry) => entry.id != rawi.id)
              .toList(growable: false),
        ),
      ),
    );
  }

  return chips;
}

class _FilterActionChip {
  const _FilterActionChip({required this.label, required this.nextFilters});

  final String label;
  final HadithFilters nextFilters;
}
