import 'package:tawaq/feature/hadith/presentation/widgets/filters/hadith_filter_tag.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/filters/hadith_filter_interaction.dart';

import 'dart:async';

import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/core/layout/viewport_dialog_constraints.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/text/arabic_search_normalize.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/hadith_help.dart';
import 'package:tawaq/core/widgets/select_empty_content.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_filters.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_locale_extensions.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/filters/hadith_lookup_section.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/hadith_accessibility.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/theme.dart';

/// Shared filter body for the desk column and modal sheet.
class HadithFilterPanel extends ConsumerWidget {
  /// Creates the filter panel.
  ///
  /// Pass [onClose] for the modal sheet; omit for the desktop column.
  const new({this.onClose, super.key});

  /// Called when the user closes the filter sheet.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final panelEnabled = ref.watch(
      hadithSessionControllerProvider.select((s) => s.supportsFilters),
    );
    if (!panelEnabled) return const SizedBox.shrink();
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
                  Text(l10n.hadithFilterTab, style: theme.typography.body.xl),
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
              child: Flexible(child: Text(l10n.hadithResetFilters)),
            ),
          ),
        ],
      ),
    );

    return panel;
  }
}

/// A single removable active-filter chip action.
class HadithFilterChipAction {
  const new({required this.label, required this.nextFilters});

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

  for (final type in filters.types) {
    chips.add(
      HadithFilterChipAction(
        label: type.getLocaleName(l10n),
        nextFilters: filters.copyWith(types: {...filters.types}..remove(type)),
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

  if (filters.exclude.trim().isNotEmpty)
    chips.add(
      HadithFilterChipAction(
        label: '${l10n.hadithExclude}: ${filters.exclude}',
        nextFilters: filters.copyWith(exclude: ''),
      ),
    );
  for (final (index, phrase) in filters.optionalPhrases.indexed) {
    if (phrase.trim().isNotEmpty)
      chips.add(
        HadithFilterChipAction(
          label: phrase,
          nextFilters: filters.copyWith(
            optionalPhrases: [...filters.optionalPhrases]..removeAt(index),
          ),
        ),
      );
  }
  if (filters.sort != null)
    chips.add(
      HadithFilterChipAction(
        label: l10n.hadithDegreeOrder,
        nextFilters: filters.copyWith(sort: null),
      ),
    );
  return chips;
}

/// Mounted bounded form; results and lookup menus remain virtualized.
class HadithFilterForm extends HookConsumerWidget {
  const HadithFilterForm({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(
      hadithSessionControllerProvider.select((s) => s.filters),
    );
    final ui = ref.watch(hadithFilterInteractionProvider);
    useListenable(ui);
    final expanded = Set<int>.of(ui.expanded);
    final l10n = context.l10n;
    void update(HadithFilters next) => unawaited(
      ref.read(hadithSessionControllerProvider.notifier).setFilters(next),
    );
    return SingleChildScrollView(
      key: const PageStorageKey('hadith-filter-scroll'),
      controller: ui.scroll,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.md,
        children: [
          HadithHelpLabel(
            label: l10n.hadithSearchMethod,
            help: l10n.hadithSearchMethodHelp,
          ),
          FSelect<SearchMethod>(
            hint: l10n.hadithSearchMethod,
            contentConstraints: selectPopoverPortalConstraints(context),
            items: {
              for (final method in SearchMethod.values)
                method.getLocaleName(l10n): method,
            },
            control: FSelectControl.lifted(
              value: filters.searchMethod,
              onChange: (value) {
                if (value != null)
                  update(filters.copyWith(searchMethod: value));
              },
            ),
          ),
          HadithHelpLabel(label: l10n.hadithScope, help: l10n.hadithScopeHelp),
          FMultiSelect<HadithTypeFilter>(
            tagBuilder: hadithFilterTag,
            items: {
              for (final type in HadithTypeFilter.values)
                type.getLocaleName(l10n): type,
            },
            hint: Text(l10n.hadithScope),
            control: FMultiValueControl.lifted(
              value: filters.types,
              onChange: (values) => update(filters.copyWith(types: values)),
            ),
          ),
          HadithHelpLabel(
            label: l10n.hadithDegrees,
            help: l10n.hadithDegreesHelp,
          ),
          FMultiSelect<HadithDegree>.search(
            tagBuilder: hadithFilterTag,
            contentEmptyBuilder: (_, _) => const SelectEmptyContent(),
            {
              for (final degree in HadithDegree.values.where(
                (d) => d != HadithDegree.all,
              ))
                degree.getLocaleName(l10n): degree,
            },
            hint: Text(l10n.hadithDegrees),
            control: FMultiValueControl.lifted(
              value: filters.degrees.toSet(),
              onChange: (values) =>
                  update(filters.copyWith(degrees: values.toList())),
            ),
            filter: (query) => HadithDegree.values.where(
              (d) =>
                  d != HadithDegree.all &&
                  (query.trim().isEmpty ||
                      arabicSearchContains(
                        d.getLocaleName(l10n),
                        query.trim(),
                      ) ||
                      d
                          .getLocaleName(l10n)
                          .toLowerCase()
                          .contains(query.toLowerCase())),
            ),
          ),
          FAccordion(
            control: FAccordionControl.lifted(
              expanded: expanded.contains,
              onChange: ui.expand,
            ),
            children: [
              FAccordionItem(
                title: Text(l10n.hadithScholars),
                child: HadithLookupSection(
                  title: l10n.hadithScholars,
                  hint: l10n.hadithTypeToSearch,
                  kind: HadithLookupKind.scholars,
                  selected: (f) => f.scholars,
                  withSelected: (f, v) => f.copyWith(scholars: v),
                ),
              ),
              FAccordionItem(
                title: Text(l10n.hadithBooks),
                child: HadithLookupSection(
                  title: l10n.hadithBooks,
                  hint: l10n.hadithTypeToSearch,
                  kind: HadithLookupKind.books,
                  selected: (f) => f.books,
                  withSelected: (f, v) => f.copyWith(books: v),
                ),
              ),
              FAccordionItem(
                title: Text(l10n.hadithNarrators),
                child: HadithLookupSection(
                  title: l10n.hadithNarrators,
                  hint: l10n.hadithTypeToSearch,
                  kind: HadithLookupKind.rawi,
                  selected: (f) => f.rawi,
                  withSelected: (f, v) => f.copyWith(rawi: v),
                ),
              ),
              FAccordionItem(
                title: Text(l10n.hadithAdvanced),
                child: const _AdvancedFilters(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdvancedFilters extends HookConsumerWidget {
  const _AdvancedFilters();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(
      hadithSessionControllerProvider.select((s) => s.filters),
    );
    final ui = ref.watch(hadithFilterInteractionProvider);
    ui.sync(filters);
    final controller = ref.read(hadithSessionControllerProvider.notifier);
    void commit() => unawaited(
      controller.setFilters(
        ref
            .read(hadithSessionControllerProvider)
            .filters
            .copyWith(
              exclude: ui.exclude.text,
              optionalPhrases: ui.phrases.map((p) => p.text).toList(),
            ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.sm,
      children: [
        HadithHelpLabel(
          label: context.l10n.hadithExclude,
          help: context.l10n.hadithExcludeHelp,
        ),
        FTextField(
          key: const ValueKey('hadith-exclude'),
          focusNode: ui.excludeFocus,
          autofocus: ui.lastFocused == ui.excludeFocus,
          control: .managed(controller: ui.exclude, onChange: (_) => commit()),
          maxLength: 500,
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final (index, field) in ui.phrases.indexed)
          Row(
            key: ObjectKey(field),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: FTextField(
                  control: .managed(
                    controller: field,
                    onChange: (_) => commit(),
                  ),
                  focusNode: ui.focusFor(field),
                  autofocus: ui.lastFocused == ui.focusFor(field),
                  hint: context.l10n.hadithOptionalPhrase,
                  maxLength: 500,
                ),
              ),
              FButton.icon(
                variant: .ghost,
                semanticsTooltip: context.l10n.hadithRemovePhrase,
                onPress: () {
                  ui.removePhrase(index);
                  commit();
                },
                child: const Icon(FLucideIcons.x, size: 16),
              ),
            ],
          ),
        if (ui.phrases.length < 4)
          FButton(
            variant: .ghost,
            prefix: const Icon(FLucideIcons.plus, size: 16),
            onPress: () {
              ui.phrases.add(TextEditingController());
              commit();
            },
            child: Flexible(child: Text(context.l10n.hadithAddPhrase)),
          ),
      ],
    );
  }
}
