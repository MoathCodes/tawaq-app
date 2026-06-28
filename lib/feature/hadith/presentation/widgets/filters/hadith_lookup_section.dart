import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_filters.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart';
import 'package:tawaq/theme/theme.dart';

/// Searchable multi-select for one lookup filter dimension.
class HadithLookupSection extends HookConsumerWidget {
  const HadithLookupSection({
    required this.title,
    required this.hint,
    required this.kind,
    required this.selected,
    required this.withSelected,
    super.key,
  });

  final String title;
  final String hint;
  final HadithLookupKind kind;
  final List<HadithLookupRef> Function(HadithFilters) selected;
  final HadithFilters Function(HadithFilters, List<HadithLookupRef>) withSelected;

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

    return ref.read(hadithLookupProvider(kind, trimmed).future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final session = ref.watch(hadithSessionControllerProvider);
    final filters = session.filters;
    final interactionsEnabled = !session.searchBusy;
    final selected = this.selected(filters);
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
          title,
          style: theme.typography.body.sm.copyWith(
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
              values.where((value) => !selectedSet.contains(value)).forEach((
                item,
              ) {
                if (selected.any((entry) => entry.id == item.id)) {
                  return;
                }
                updateFilters(
                  withSelected(filters, [...selected, item]),
                );
              });

              selected.where((value) => !values.contains(value)).forEach((
                item,
              ) {
                updateFilters(
                  withSelected(
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
