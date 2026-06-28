import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/hooks/hooks.dart';
import 'package:tawaq/core/layout/viewport_dialog_constraints.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/shortcuts/shortcuts.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_persisted_settings.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_filters.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/filters/hadith_filter_panel.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/hadith_accessibility.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/layout/hadith_layout_scope.dart';
import 'package:tawaq/theme/theme.dart';

/// Search query field with bookmarks and filter affordances.
class HadithQueryField extends HookConsumerWidget {
  /// Creates the query field.
  const HadithQueryField({super.key});

  static const _queryDebounceDuration = Duration(milliseconds: 420);
  static const _filterPopoverGroupId = 'hadith-filter-popover';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ui = ref.watch(hadithScreenUiProvider);
    final useSplitLayout = HadithLayoutScope.of(context);
    final queryController = useTextEditingController();
    useListenable(queryController);
    final screenController = ref.read(hadithSessionControllerProvider.notifier);
    final searchFocusNode = useFocusNode();
    final focusSearch = useCallback(
      searchFocusNode.requestFocus,
      [searchFocusNode],
    );

    useRegisterAppSearchFocus(focusSearch, enabled: ui.isSearchMode);

    useEffect(() {
      if (queryController.text != ui.query) {
        queryController.text = ui.query;
      }
      return null;
    }, [ui.query]);

    final theme = context.theme;
    final l10n = context.l10n;
    final activeFilterCount = ui.filters.activeCount;

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
                enabled: !ui.searchBusy,
                control: .managed(
                  controller: queryController,
                  onChange: (value) => onQueryChanged(value.text),
                ),
                onSubmit: ui.searchBusy ? null : commitQuery,
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
            if (ui.isSearchMode)
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
            if (useSplitLayout && ui.isSearchMode)
              FButton.icon(
                onPress: ui.searchBusy
                    ? null
                    : () {
                        screenController.setActiveTab(HadithPanelTab.filters);
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
            else if (ui.isSearchMode)
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
                  onPress: ui.searchBusy ? null : controller.toggle,
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
