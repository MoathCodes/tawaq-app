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
import 'package:tawaq/theme/theme.dart';

/// Scrollable hadith search filter form (method, scope, degrees, lookups).
class HadithFilterForm extends ConsumerWidget {
  const HadithFilterForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(hadithSessionControllerProvider);
    final panelEnabled = !session.searchBusy;
    final filters = session.filters;
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
