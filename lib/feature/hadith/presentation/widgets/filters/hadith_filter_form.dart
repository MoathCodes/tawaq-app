import 'dart:async';

import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/layout/responsive.dart';
import 'package:tawaq/core/layout/viewport_dialog_constraints.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_filters.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_locale_extensions.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/filters/hadith_lookup_section.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/hadith_accessibility.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/theme.dart';

/// Scrollable hadith search filter form (method, scope, degrees, lookups).
class HadithFilterForm extends ConsumerWidget {
  /// Creates the filter form.
  const HadithFilterForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ui = ref.watch(hadithScreenUiProvider);
    final panelEnabled = !ui.searchBusy;
    final filters = ui.filters;
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
        const HadithScholarsLookupSection(),
        const SizedBox(height: AppSpacing.md),
        const HadithBooksLookupSection(),
        const SizedBox(height: AppSpacing.md),
        const HadithRawiLookupSection(),
      ],
    );
  }
}

/// Removable chips for each active hadith search filter.
class HadithActiveFilterChips extends ConsumerWidget {
  /// Creates the active filter chips row.
  const HadithActiveFilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ui = ref.watch(hadithScreenUiProvider);
    final theme = context.theme;
    final l10n = context.l10n;
    final chips = buildActiveHadithFilterChips(ui.filters, l10n);

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
                      onPress: ui.filterInteractionsEnabled
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
                      onPress: ui.filterInteractionsEnabled
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
                      onPress: ui.filterInteractionsEnabled
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

/// A single removable active-filter chip action.
class HadithFilterChipAction {
  /// Creates a filter chip action.
  const HadithFilterChipAction({
    required this.label,
    required this.nextFilters,
  });

  /// Display label for the chip.
  final String label;

  /// Filter state after removing this chip.
  final HadithFilters nextFilters;
}
