import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/shortcuts/use_register_app_search_focus.dart';
import 'package:tawaq/core/widgets/animation_entry.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/core/widgets/f_skeletonizer.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_category.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_locale_extensions.dart';
import 'package:tawaq/feature/muslim_fortress/domain/services/fortress_time_recommendations.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/fortress_category_ui.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/provider/muslim_fortress_provider.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/browse/fortress_browse_sidebar.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/browse/fortress_category_detail.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/browse/muslim_fortress_welcome_pane.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/fortress_fake_hadith_dialog.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/reading/fortress_focus_reading.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/search/fortress_search_results.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_data_providers.dart';
import 'package:tawaq/theme/theme.dart';

/// Muslim Fortress screen — sidebar browse, welcome home, and focus reading.
class MuslimFortressScreen extends HookConsumerWidget {
  /// Creates a Muslim Fortress screen.
  const MuslimFortressScreen({super.key});

  static const _maxContentWidth = 1100.0;
  static const _sidebarWidth = 300.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final l10n = context.l10n;
    final chaptersAsync = ref.watch(muslimFortressChaptersProvider);
    final day = ref.watch(prayerDayProvider).value;

    final selectedCategory = useState<FortressCategory?>(null);
    final sidePanelTabIndex = useState(0);
    final favoriteTitles = useState(<String>[]);
    final animatedSidebarChapterIds = useRef(<int>{});
    final isFocusMode = useState(false);
    final focusStartIndex = useState(0);

    final searchController = useTextEditingController();
    useListenable(searchController);
    final searchFocusNode = useFocusNode();
    final focusSearch = useCallback(
      searchFocusNode.requestFocus,
      [searchFocusNode],
    );

    useRegisterAppSearchFocus(focusSearch, enabled: !isFocusMode.value);
    final sidebarQuery = searchController.text.toLowerCase();
    final globalSearchQuery = ref.watch(muslimFortressSearchQueryProvider);
    final isGlobalSearch = globalSearchQuery.length >= 2;
    final searchResultsAsync = isGlobalSearch
        ? ref.watch(muslimFortressSearchResultsProvider)
        : null;

    useEffect(() {
      final timer = Timer(const Duration(milliseconds: 300), () {
        ref
            .read(muslimFortressSearchQueryProvider.notifier)
            .setQuery(searchController.text);
      });
      return timer.cancel;
    }, [searchController.text]);

    final allCategories = chaptersAsync.when(
      data: (value) => value,
      loading: () => fortressCategoryPlaceholders(l10n: l10n),
      error: (_, _) => const <FortressCategory>[],
    );

    final sourceCategories = sidePanelTabIndex.value == 0
        ? allCategories
        : allCategories
              .where((c) => favoriteTitles.value.contains(c.title))
              .toList();

    final filteredCategories = sourceCategories.where((category) {
      if (sidebarQuery.isEmpty) return true;
      return category.title.toLowerCase().contains(sidebarQuery) ||
          fortressRecurrenceLabel(category.recurrence, l10n)
              .toLowerCase()
              .contains(sidebarQuery);
    }).toList();

    void toggleFavorite(String title) {
      final next = List<String>.from(favoriteTitles.value);
      if (next.contains(title)) {
        next.remove(title);
      } else {
        next.insert(0, title);
      }
      favoriteTitles.value = next;
    }

    void selectCategory(FortressCategory category) {
      if (selectedCategory.value == category) {
        selectedCategory.value = null;
        return;
      }
      isFocusMode.value = false;
      selectedCategory.value = category;
    }

    final selectedDuasAsync = selectedCategory.value == null
        ? null
        : ref.watch(
            muslimFortressDuasProvider(selectedCategory.value!.chapterId),
          );

    void startFocusReading({int initialIndex = 0}) {
      focusStartIndex.value = initialIndex;
      isFocusMode.value = true;
    }

    if (isFocusMode.value && selectedCategory.value != null) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: selectedDuasAsync!.when(
          data: (duas) => FortressFocusReadingView(
            category: selectedCategory.value!,
            duas: duas,
            initialIndex: focusStartIndex.value,
            onExit: () => isFocusMode.value = false,
          ),
          loading: () => FSkeletonizer(
            child: FortressFocusReadingView(
              category: selectedCategory.value!,
              duas: const [],
              onExit: () => isFocusMode.value = false,
            ),
          ),
          error: (e, _) => Scaffold(
            body: Center(child: Text(e.toString())),
          ),
        ),
      );
    }

    final recommendedCategories = day == null
        ? <FortressCategory>[]
        : recommendFortressCategories(
            allCategories: allCategories,
            now: day.now,
            prayerTimes: day.today,
            location: day.location,
          );

    final categoriesByTitle = {
      for (final category in allCategories) category.title: category,
    };
    final bookmarkCategories = [
      for (final title in favoriteTitles.value)
        if (categoriesByTitle[title] != null) categoriesByTitle[title]!,
    ].take(4).toList();

    if (chaptersAsync.hasError) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: theme.colors.background,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    FLucideIcons.circleAlert,
                    size: 48,
                    color: theme.colors.error,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.fortressLoadError,
                    style: theme.typography.lg.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '$chaptersAsync.error',
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FButton(
                    onPress: () =>
                        ref.invalidate(muslimFortressChaptersProvider),
                    child: Text(l10n.fortressRetry),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, viewport) {
        final contentHeight = viewport.maxHeight.isFinite
            ? viewport.maxHeight - AppSpacing.md * 2
            : MediaQuery.sizeOf(context).height - AppSpacing.md * 2;

        return FSkeletonizer(
          enabled: chaptersAsync.isLoading,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                  child: SizedBox(
                    height: contentHeight,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: _sidebarWidth,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                l10n.muslimFortress,
                                style: theme.typography.xl2.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              NonSelectable(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    FTabs(
                                      control: .lifted(
                                        index: sidePanelTabIndex.value,
                                        onChange: (index) =>
                                            sidePanelTabIndex.value = index,
                                      ),
                                      children: [
                                        FTabEntry(
                                          label: Text(l10n.fortressAllChapters),
                                          child: const SizedBox.shrink(),
                                        ),
                                        FTabEntry(
                                          label: Text(l10n.fortressFavorites),
                                          child: const SizedBox.shrink(),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.lg),
                                    FTextField(
                                      focusNode: searchFocusNode,
                                      hint: l10n.fortressSearchHint,
                                      control: FTextFieldControl.managed(
                                        controller: searchController,
                                      ),
                                      prefixBuilder:
                                          (context, style, variants) =>
                                              const Icon(FLucideIcons.search),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    FButton(
                                      variant: .ghost,
                                      onPress: () async {
                                        final entries = await ref.read(
                                          muslimFortressFakeHadithWarningsProvider
                                              .future,
                                        );
                                        if (!context.mounted) return;
                                        await showFortressFakeHadithDialog(
                                          context,
                                          entries: entries,
                                        );
                                      },
                                      prefix: const Icon(
                                        FLucideIcons.triangleAlert,
                                        size: 16,
                                      ),
                                      child: Text(
                                        l10n.fortressBrowseWeakHadith,
                                        style: theme.typography.xs,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              Expanded(
                                child: filteredCategories.isEmpty
                                    ? FortressEmptySidePanelState(
                                        isFavoritesTab:
                                            sidePanelTabIndex.value == 1,
                                      )
                                    : ListView.separated(
                                        itemCount: filteredCategories.length,
                                        separatorBuilder: (context, index) =>
                                            const SizedBox(
                                              height: AppSpacing.sm,
                                            ),
                                        itemBuilder: (context, index) {
                                          final category =
                                              filteredCategories[index];
                                          final isSelected =
                                              selectedCategory
                                                  .value
                                                  ?.chapterId ==
                                              category.chapterId;
                                          final isFavorite = favoriteTitles
                                              .value
                                              .contains(category.title);

                                          final tile = FortressCategoryListTile(
                                            category: category,
                                            isSelected: isSelected,
                                            isFavorite: isFavorite,
                                            onTap: () =>
                                                selectCategory(category),
                                            onToggleFavorite: () =>
                                                toggleFavorite(category.title),
                                          );

                                          if (animatedSidebarChapterIds.value
                                              .contains(category.chapterId)) {
                                            return tile;
                                          }

                                          return AnimationEntry(
                                            key: ValueKey(category.chapterId),
                                            animateOnce: true,
                                            delay: Duration(
                                              milliseconds: 100 + (index * 20),
                                            ),
                                            onEntranceComplete: () {
                                              animatedSidebarChapterIds.value =
                                                  {
                                                    ...animatedSidebarChapterIds
                                                        .value,
                                                    category.chapterId,
                                                  };
                                            },
                                            child: tile,
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          child: VerticalDivider(
                            color: theme.colors.border,
                            width: 1,
                            thickness: 1,
                          ),
                        ),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: isGlobalSearch
                                ? searchResultsAsync!.when(
                                    data: (results) => FortressSearchResultsPane(
                                      key: ValueKey(globalSearchQuery),
                                      results: results,
                                      query: globalSearchQuery,
                                      onSelectTitle: (category) {
                                        searchController.clear();
                                        ref
                                            .read(
                                              muslimFortressSearchQueryProvider
                                                  .notifier,
                                            )
                                            .setQuery('');
                                        selectCategory(category);
                                      },
                                      onSelectContent: (hit) async {
                                        searchController.clear();
                                        ref
                                            .read(
                                              muslimFortressSearchQueryProvider
                                                  .notifier,
                                            )
                                            .setQuery('');
                                        final category = allCategories
                                            .where(
                                              (c) =>
                                                  c.chapterId == hit.chapterId,
                                            )
                                            .firstOrNull;
                                        if (category == null) return;
                                        selectCategory(category);
                                        final duas = await ref.read(
                                          muslimFortressDuasProvider(
                                            hit.chapterId,
                                          ).future,
                                        );
                                        final index = duas.indexWhere(
                                          (d) =>
                                              d.contentId == hit.item.contentId,
                                        );
                                        startFocusReading(
                                          initialIndex: index >= 0 ? index : 0,
                                        );
                                      },
                                    ),
                                    loading: () => const Center(
                                      child: FCircularProgress.loader(),
                                    ),
                                    error: (e, _) =>
                                        Center(child: Text(e.toString())),
                                  )
                                : selectedCategory.value == null
                                ? MuslimFortressWelcomePane(
                                    key: const ValueKey('welcome'),
                                    recommendedCategories:
                                        recommendedCategories,
                                    bookmarkCategories: bookmarkCategories,
                                    onSelectCategory: selectCategory,
                                  )
                                : selectedDuasAsync == null
                                ? const SizedBox.shrink()
                                : selectedDuasAsync.when(
                                    data: (duas) => FortressCategoryDetailView(
                                      key: ValueKey(
                                        selectedCategory.value!.chapterId,
                                      ),
                                      category: selectedCategory.value!,
                                      duas: duas,
                                      isFavorite: favoriteTitles.value.contains(
                                        selectedCategory.value!.title,
                                      ),
                                      onToggleFavorite: () => toggleFavorite(
                                        selectedCategory.value!.title,
                                      ),
                                      onStartReading: startFocusReading,
                                    ),
                                    loading: () => FortressCategoryDetailView(
                                      key: ValueKey(
                                        selectedCategory.value!.chapterId,
                                      ),
                                      category: selectedCategory.value!,
                                      duas: const [],
                                      isFavorite: favoriteTitles.value.contains(
                                        selectedCategory.value!.title,
                                      ),
                                      onToggleFavorite: () => toggleFavorite(
                                        selectedCategory.value!.title,
                                      ),
                                      onStartReading: startFocusReading,
                                      isLoading: true,
                                    ),
                                    error: (e, _) =>
                                        Center(child: Text(e.toString())),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

