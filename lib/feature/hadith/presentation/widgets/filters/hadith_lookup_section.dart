import 'dart:async';

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_filters.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart';
import 'package:tawaq/theme/theme.dart';

/// Searchable multi-select for one lookup filter dimension.
class HadithLookupSection extends HookConsumerWidget {
  const new({
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
  final HadithFilters Function(HadithFilters, List<HadithLookupRef>)
  withSelected;

  static const _lookupDebounceDuration = Duration(milliseconds: 200);
  static const _lookupMinLength = 2;

  Future<Iterable<HadithLookupRef>> _debouncedLookup(
    WidgetRef ref,
    String query,
    ObjectRef<int> requestId,
  ) async {
    final currentRequest = ++requestId.value;
    final trimmed = query.trim();
    if (trimmed.length < _lookupMinLength) {
      return const <HadithLookupRef>[];
    }

    await Future<void>.delayed(_lookupDebounceDuration);
    if (!ref.context.mounted || currentRequest != requestId.value) {
      return const <HadithLookupRef>[];
    }

    return await ref.read(hadithLookupProvider(kind, trimmed).future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final filters = ref.watch(
      hadithSessionControllerProvider.select((s) => s.filters),
    );
    final interactionsEnabled = !ref.watch(
      hadithSessionControllerProvider.select((s) => s.searchBusy),
    );
    final selected = this.selected(filters);
    final selectedSet = selected.toSet();
    final lookupRequestId = useRef(0);
    final lookupController = useState(useMemoized(TextEditingController.new));
    useEffect(() => lookupController.value.dispose, [lookupController.value]);

    useEffect(
      () =>
          () => lookupRequestId.value++,
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
              // One commit from the final selection set — do not loop
              // per add/remove against a stale filters closure.
              updateFilters(
                withSelected(filters, values.toList(growable: false)),
              );
            },
          ),
          searchFieldProperties: FSelectSearchFieldProperties(
            control: .managed(controller: lookupController.value),
          ),
          filter: (query) => _debouncedLookup(ref, query, lookupRequestId),
          contentErrorBuilder: (_, _, _) => Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: AppSpacing.md,
              children: [
                Text(
                  context.l10n.hadithLookupFailed,
                  textAlign: TextAlign.center,
                ),
                FButton(
                  onPress: () {
                    ref
                        .read(hadithSessionControllerProvider.notifier)
                        .retryInitialization();
                    ref.invalidate(
                      hadithLookupProvider(
                        kind,
                        lookupController.value.text.trim(),
                      ),
                    );
                    // Forui reruns the filter when its search controller changes.
                    // Keep the query and selection while retrying the same request.
                    lookupController.value = TextEditingController.fromValue(
                      lookupController.value.value,
                    );
                  },
                  child: Text(context.l10n.retryAction),
                ),
              ],
            ),
          ),
          contentBuilder: (_, _, data) => [
            for (final item in data)
              FSelectItem(title: Text(item.name), value: item),
          ],
          contentLoadingBuilder: (_, _) => const FCircularProgress(),
          contentEmptyBuilder: (_, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Text(
              lookupController.value.text.trim().length < _lookupMinLength
                  ? context.l10n.hadithLookupPrompt
                  : context.l10n.noResults,
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
