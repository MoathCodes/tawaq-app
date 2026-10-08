import 'dart:async';

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/shortcuts/shortcuts.dart';
import 'package:tawaq/feature/hadith/presentation/models/hadith_session_state.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/filters/hadith_filter_form.dart';
import 'package:tawaq/theme/theme.dart';

/// Search draft, endpoint selection and applied-filter summary.
class HadithSearchColumn extends HookConsumerWidget {
  const HadithSearchColumn({required this.onFilters, super.key});
  final VoidCallback onFilters;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(
      hadithSessionControllerProvider.select(
        (s) => (s.context, s.target, s.query, s.filters, s.searchBusy),
      ),
    );
    final session = ref.read(hadithSessionControllerProvider);
    final controller = ref.read(hadithSessionControllerProvider.notifier);
    final query = useTextEditingController(text: session.query);
    final focus = useFocusNode();
    final invalid = useState(false);
    useListenable(query);
    useRegisterAppSearchFocus(focus.requestFocus);
    useEffect(() {
      if (query.text != session.query) query.text = session.query;
      return null;
    }, [session.query]);
    final l10n = context.l10n;
    final canSearch =
        query.text.trim().isNotEmpty ||
        (session.target == HadithSearchTarget.records &&
            session.filters.optionalPhrases.any((p) => p.trim().isNotEmpty));
    void submit() {
      if (!canSearch) return;
      invalid.value =
          query.text.length > 500 ||
          session.filters.exclude.length > 500 ||
          session.filters.optionalPhrases.length > 4 ||
          session.filters.optionalPhrases.any((p) => p.length > 500);
      if (!invalid.value) unawaited(controller.setQuery(query.text));
    }

    final chips =
        session.isSearchMode && session.target == HadithSearchTarget.records
        ? buildActiveHadithFilterChips(
            session.committedFilters ?? session.filters,
            l10n,
          )
        : <HadithFilterChipAction>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.sm,
      children: [
        Row(
          children: [
            Expanded(
              child: FTextField(
                key: const ValueKey('hadith-query'),
                control: .managed(controller: query),
                focusNode: focus,
                hint: l10n.hadithSearchHint,
                prefixBuilder: (_, _, _) => FPopoverMenu(
                  menuBuilder: (_, popover, _) => [
                    FItemGroup(
                      children: [
                        for (final target in HadithSearchTarget.values)
                          FItem(
                            title: Text(
                              target == HadithSearchTarget.records
                                  ? l10n.hadithSearchRecords
                                  : l10n.hadithSearchProse,
                            ),
                            onPress: () {
                              popover.hide();
                              unawaited(controller.setTarget(target));
                            },
                          ),
                      ],
                    ),
                  ],
                  builder: (_, popover, _) => FButton(
                    variant: .ghost,
                    size: .sm,
                    mainAxisSize: MainAxisSize.min,
                    onPress: popover.toggle,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          session.target == HadithSearchTarget.records
                              ? l10n.hadithTargetRecords
                              : l10n.hadithTargetProse,
                        ),
                        const SizedBox(width: 4),
                        const Icon(FLucideIcons.chevronDown, size: 12),
                      ],
                    ),
                  ),
                ),
                onSubmit: (_) => submit(),
                error: invalid.value ? Text(l10n.hadithInvalidSearch) : null,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            FButton.icon(
              onPress: canSearch && !session.searchBusy ? submit : null,
              semanticsTooltip: l10n.hadithSearchAction,
              child: const Icon(FLucideIcons.search, size: 18),
            ),
            if (session.supportsFilters) const SizedBox(width: AppSpacing.xs),
            if (session.supportsFilters)
              FButton.icon(
                variant: .outline,
                onPress: onFilters,
                semanticsTooltip: l10n.hadithFilterTab,
                child: const Icon(FLucideIcons.slidersHorizontal, size: 18),
              ),
          ],
        ),
        if (chips.isNotEmpty)
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final chip in chips)
                FButton(
                  variant: .ghost,
                  size: .sm,
                  mainAxisSize: MainAxisSize.min,
                  onPress: () =>
                      unawaited(controller.setFilters(chip.nextFilters)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(child: Text(chip.label)),
                      const SizedBox(width: AppSpacing.xs),
                      const Icon(FLucideIcons.x, size: 12),
                    ],
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
