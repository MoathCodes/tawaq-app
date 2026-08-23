import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/layout/viewport_dialog_constraints.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/text/arabic_search_normalize.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/core/widgets/select_empty_content.dart';
import 'package:tawaq/feature/quran/domain/models/translation_source.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_screen_settings_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/quran_semantics.dart';
import 'package:tawaq/theme/theme.dart';

/// Searchable select for choosing a Quran translation source.
class TranslationSourceSelector extends ConsumerWidget {
  /// Creates a [TranslationSourceSelector].
  const new({
    this.enabled = true,
    this.showLabel = true,
    super.key,
  });

  /// Whether the selector accepts input.
  final bool enabled;

  /// Whether to show the field label row above the control.
  final bool showLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final colors = theme.colors;
    final typography = theme.typography;
    final l10n = context.l10n;
    const sources = TranslationId.values;
    final selected = ref.watch(
      quranScreenSettingsProvider.select(
        (settings) =>
            settings.value?.selectedTranslation ?? kDefaultTranslationId,
      ),
    );
    final fieldLabel = l10n.translation;

    return NonSelectable(
      child: QuranSemantics.labeledControl(
        name: fieldLabel,
        value: selected.displayName,
        enabled: enabled,
        excludeChild: true,
        child: FSelect<TranslationId>.searchBuilder(
          enabled: enabled,
          label: showLabel
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      FLucideIcons.languages,
                      size: 14,
                      color: colors.primary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(fieldLabel),
                  ],
                )
              : null,
          contentConstraints: selectPopoverPortalConstraints(context),
          style: selectStyle(
            colors: colors,
            style: theme.style,
            typography: typography,
          ),
          control: FSelectControl.lifted(
            value: selected,
            onChange: (value) {
              if (value != null) {
                ref
                    .read(quranScreenSettingsProvider.notifier)
                    .setSelectedTranslation(value);
              }
            },
          ),
          format: (source) => source.displayName,
          filter: (query) {
            if (query.isEmpty) return sources;
            final normalized = query.toLowerCase().trim();
            return sources.where(
              (source) =>
                  arabicSearchContains(source.displayName, normalized) ||
                  source.displayName.toLowerCase().contains(normalized) ||
                  source.language.toLowerCase().contains(normalized),
            );
          },
          contentBuilder: (_, _, values) => _buildTranslationSections(
            values,
            colors,
            typography,
          ),
          contentEmptyBuilder: (_, _) => const SelectEmptyContent(),
        ),
      ),
    );
  }
}

List<FSelectItemMixin> _buildTranslationSections(
  Iterable<TranslationId> sources,
  FColors colors,
  FTypography typography,
) {
  final grouped = <String, List<TranslationId>>{};
  for (final source in sources) {
    grouped.putIfAbsent(source.language, () => []).add(source);
  }

  final languages = grouped.keys.toList()..sort();

  return [
    for (var i = 0; i < languages.length; i++)
      FSelectSection<TranslationId>.rich(
        label: Text(
          languages[i],
          style: typography.body.xs.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.mutedForeground,
          ),
        ),
        divider: i > 0 ? .indented : .none,
        children: [
          for (final source in grouped[languages[i]]!)
            FSelectItem<TranslationId>(
              value: source,
              title: Text(source.displayName),
            ),
        ],
      ),
  ];
}
