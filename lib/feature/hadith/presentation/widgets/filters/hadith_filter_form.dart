import 'dart:async';

import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/layout/responsive.dart';
import 'package:tawaq/core/layout/viewport_dialog_constraints.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/text/arabic_search_normalize.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_filters.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_locale_extensions.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/filters/hadith_lookup_section.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/hadith_accessibility.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/theme.dart';

/// Filter panel for the side tab or compact-layout popover.
class HadithFilterPanel extends ConsumerWidget {
  /// Creates the filter panel.
  ///
  /// Pass [onClose] when shown in a popover; omit for the side-panel tab.
  const new({this.onClose, super.key});

  /// Called when the user dismisses a popover instance.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final panelEnabled = !ref.watch(
      hadithSessionControllerProvider.select((s) => s.searchBusy),
    );
    final l10n = context.l10n;
    final theme = context.theme;

    Widget panel = NonSelectable(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (onClose != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.hadithFilterTab,
                    style: theme.typography.body.xl,
                  ),
                  FButton.icon(
                    variant: FButtonVariant.ghost,
                    semanticsLabel: hadithCloseFiltersSemanticsLabel(l10n),
                    onPress: onClose,
                    child: const HadithDecorExcludeSemantics(
                      child: Icon(FLucideIcons.x, size: 16),
                    ),
                  ),
                ],
              ),
            ),
          const Expanded(child: HadithFilterForm()),
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
                            .read(hadithSessionControllerProvider.notifier)
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

    if (onClose != null) {
      final fallbackHeight = dialogConstraints(
        context,
        preferredHeight: 620,
        minWidth: 320,
      ).maxHeight.clamp(360.0, 620.0);

      panel = SizedBox(height: fallbackHeight, child: panel);
    }

    return panel;
  }
}

/// A single removable active-filter chip action.
class HadithFilterChipAction {
  const new({
    required this.label,
    required this.nextFilters,
  });

  final String label;
  final HadithFilters nextFilters;
}

/// Builds removable chip descriptors for the active [filters].
List<HadithFilterChipAction> buildActiveHadithFilterChips(
  HadithFilters filters,
  AppLocalizations l10n,
) {
  final chips = <HadithFilterChipAction>[];

  if (filters.searchMethod != SearchMethod.anyWord) {
    chips.add(
      HadithFilterChipAction(
        label: filters.searchMethod.getLocaleName(l10n),
        nextFilters: filters.copyWith(searchMethod: SearchMethod.anyWord),
      ),
    );
  }

  if (filters.zone != SearchZone.all) {
    chips.add(
      HadithFilterChipAction(
        label: filters.zone.getLocaleName(l10n),
        nextFilters: filters.copyWith(zone: SearchZone.all),
      ),
    );
  }

  if (filters.specialist) {
    chips.add(
      HadithFilterChipAction(
        label: l10n.hadithSpecialist,
        nextFilters: filters.copyWith(specialist: false),
      ),
    );
  }

  for (final degree in filters.degrees) {
    chips.add(
      HadithFilterChipAction(
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
      HadithFilterChipAction(
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
      HadithFilterChipAction(
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
      HadithFilterChipAction(
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

/// Scrollable hadith search filter form (method, scope, degrees, lookups).
class HadithFilterForm extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final panelEnabled = !ref.watch(
      hadithSessionControllerProvider.select((s) => s.searchBusy),
    );
    final filters = ref.watch(
      hadithSessionControllerProvider.select((s) => s.filters),
    );
    final theme = context.theme;
    final l10n = context.l10n;

    void updateFilters(HadithFilters next) {
      if (!panelEnabled) return;
      unawaited(
        ref.read(hadithSessionControllerProvider.notifier).setFilters(next),
      );
    }

    return ListView(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.sm,
        end: AppSpacing.sm,
        bottom: AppSpacing.md,
      ),
      children: [
        Text(
          l10n.hadithSearchMethod,
          style: theme.typography.body.sm.copyWith(
            color: theme.colors.mutedForeground,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = !isContainerAtLeast(
              context,
              constraints,
              FBreakpoint.md,
            );

            if (compact) {
              return FSelect<SearchMethod>(
                enabled: panelEnabled,
                hint: l10n.hadithSearchMethod,
                contentConstraints: selectPopoverPortalConstraints(context),
                style: selectStyle(
                  colors: theme.colors,
                  style: theme.style,
                  typography: theme.typography,
                ),
                items: {
                  for (final method in SearchMethod.values)
                    method.getLocaleName(l10n): method,
                },
                control: FSelectControl<SearchMethod>.lifted(
                  value: filters.searchMethod,
                  onChange: (value) {
                    if (!panelEnabled || value == null) return;
                    updateFilters(filters.copyWith(searchMethod: value));
                  },
                ),
              );
            }

            return FTabs(
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
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n.hadithScope,
          style: theme.typography.body.sm.copyWith(
            color: theme.colors.mutedForeground,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        FSelect<SearchZone>.search(
          enabled: panelEnabled,
          hint: l10n.hadithScope,
          contentConstraints: selectPopoverPortalConstraints(context),
          style: selectStyle(
            colors: theme.colors,
            style: theme.style,
            typography: theme.typography,
          ),
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
            final trimmed = query.trim();
            if (trimmed.isEmpty) return SearchZone.values;
            final lower = trimmed.toLowerCase();
            return SearchZone.values.where((zone) {
              final name = zone.getLocaleName(l10n);
              return arabicSearchContains(name, trimmed) ||
                  name.toLowerCase().contains(lower);
            });
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
            final trimmed = query.trim();
            final values = HadithDegree.values.where(
              (value) => value != HadithDegree.all,
            );
            if (trimmed.isEmpty) return values;
            final lower = trimmed.toLowerCase();
            return values.where((value) {
              final name = value.getLocaleName(l10n);
              return arabicSearchContains(name, trimmed) ||
                  name.toLowerCase().contains(lower);
            });
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        HadithLookupSection(
          title: l10n.hadithScholars,
          hint: l10n.hadithTypeToSearch,
          kind: HadithLookupKind.scholars,
          selected: (filters) => filters.scholars,
          withSelected: (filters, selected) =>
              filters.copyWith(scholars: selected),
        ),
        const SizedBox(height: AppSpacing.md),
        HadithLookupSection(
          title: l10n.hadithBooks,
          hint: l10n.hadithTypeToSearch,
          kind: HadithLookupKind.books,
          selected: (filters) => filters.books,
          withSelected: (filters, selected) => filters.copyWith(books: selected),
        ),
        const SizedBox(height: AppSpacing.md),
        HadithLookupSection(
          title: l10n.hadithNarrators,
          hint: l10n.hadithTypeToSearch,
          kind: HadithLookupKind.rawi,
          selected: (filters) => filters.rawi,
          withSelected: (filters, selected) => filters.copyWith(rawi: selected),
        ),
      ],
    );
  }
}
