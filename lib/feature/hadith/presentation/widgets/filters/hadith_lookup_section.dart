import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_filters.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/theme.dart';

/// Configuration for a searchable multi-select lookup filter section.
class HadithLookupSectionConfig {
  const HadithLookupSectionConfig._({
    required this.title,
    required this.hint,
    required this.selected,
    required this.withSelected,
    required this.lookup,
  });

  /// Scholars lookup section.
  factory HadithLookupSectionConfig.scholars(AppLocalizations l10n) {
    return HadithLookupSectionConfig._(
      title: l10n.hadithScholars,
      hint: l10n.hadithTypeToSearch,
      selected: (filters) => filters.scholars,
      withSelected: (filters, selected) =>
          filters.copyWith(scholars: selected),
      lookup: (ref, query) =>
          ref.read(hadithScholarsLookupProvider(query).future),
    );
  }

  /// Books lookup section.
  factory HadithLookupSectionConfig.books(AppLocalizations l10n) {
    return HadithLookupSectionConfig._(
      title: l10n.hadithBooks,
      hint: l10n.hadithTypeToSearch,
      selected: (filters) => filters.books,
      withSelected: (filters, selected) => filters.copyWith(books: selected),
      lookup: (ref, query) => ref.read(hadithBooksLookupProvider(query).future),
    );
  }

  /// Narrators (rawi) lookup section.
  factory HadithLookupSectionConfig.rawi(AppLocalizations l10n) {
    return HadithLookupSectionConfig._(
      title: l10n.hadithNarrators,
      hint: l10n.hadithTypeToSearch,
      selected: (filters) => filters.rawi,
      withSelected: (filters, selected) => filters.copyWith(rawi: selected),
      lookup: (ref, query) => ref.read(hadithRawiLookupProvider(query).future),
    );
  }

  final String title;
  final String hint;
  final List<HadithLookupRef> Function(HadithFilters) selected;
  final HadithFilters Function(HadithFilters, List<HadithLookupRef>) withSelected;
  final Future<Iterable<HadithLookupRef>> Function(WidgetRef ref, String query)
  lookup;
}

/// Scholars multi-select lookup filter.
class HadithScholarsLookupSection extends ConsumerWidget {
  const HadithScholarsLookupSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return HadithLookupSection(
      config: HadithLookupSectionConfig.scholars(context.l10n),
    );
  }
}

/// Books multi-select lookup filter.
class HadithBooksLookupSection extends ConsumerWidget {
  const HadithBooksLookupSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return HadithLookupSection(
      config: HadithLookupSectionConfig.books(context.l10n),
    );
  }
}

/// Narrators multi-select lookup filter.
class HadithRawiLookupSection extends ConsumerWidget {
  const HadithRawiLookupSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return HadithLookupSection(
      config: HadithLookupSectionConfig.rawi(context.l10n),
    );
  }
}

/// Searchable multi-select for one lookup filter dimension.
class HadithLookupSection extends HookConsumerWidget {
  const HadithLookupSection({required this.config, super.key});

  final HadithLookupSectionConfig config;

  static const _lookupDebounceDuration = Duration(milliseconds: 200);
  static const _lookupMinLength = 2;

  Future<Iterable<HadithLookupRef>> _debouncedLookup(
    WidgetRef ref,
    String query,
    ObjectRef<int> requestId,
  ) async {
    final trimmed = query.trim();
    if (trimmed.length < _lookupMinLength) {
      return const <HadithLookupRef>[];
    }

    final currentRequest = ++requestId.value;
    await Future<void>.delayed(_lookupDebounceDuration);
    if (currentRequest != requestId.value) {
      return const <HadithLookupRef>[];
    }

    return config.lookup(ref, trimmed);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final ui = ref.watch(hadithScreenUiProvider);
    final filters = ui.filters;
    final interactionsEnabled = !ui.searchBusy;
    final selected = config.selected(filters);
    final selectedSet = selected.toSet();
    final lookupRequestId = useRef(0);

    useEffect(
      () => () => lookupRequestId.value++,
      const [],
    );

    void updateFilters(HadithFilters next) {
      if (!interactionsEnabled) return;
      unawaited(
        ref.read(hadithSessionControllerProvider.notifier).setFilters(next),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          config.title,
          style: theme.typography.body.sm.copyWith(
            color: theme.colors.mutedForeground,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        FMultiSelect<HadithLookupRef>.searchBuilder(
          enabled: interactionsEnabled,
          hint: Text(config.hint),
          format: (item) => Text(item.name),
          control: FMultiValueControl<HadithLookupRef>.lifted(
            value: selectedSet,
            onChange: (values) {
              if (!interactionsEnabled) return;
              values.where((value) => !selectedSet.contains(value)).forEach((
                item,
              ) {
                if (selected.any((entry) => entry.id == item.id)) {
                  return;
                }
                updateFilters(
                  config.withSelected(filters, [...selected, item]),
                );
              });

              selected.where((value) => !values.contains(value)).forEach((
                item,
              ) {
                updateFilters(
                  config.withSelected(
                    filters,
                    selected
                        .where((entry) => entry.id != item.id)
                        .toList(growable: false),
                  ),
                );
              });
            },
          ),
          filter: (query) => _debouncedLookup(ref, query, lookupRequestId),
          contentBuilder: (_, _, data) => [
            for (final item in data)
              FSelectItem(title: Text(item.name), value: item),
          ],
          contentLoadingBuilder: (_, _) => const FCircularProgress(),
          contentEmptyBuilder: (_, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Text(
              context.l10n.noResults,
              style: theme.typography.body.sm.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
