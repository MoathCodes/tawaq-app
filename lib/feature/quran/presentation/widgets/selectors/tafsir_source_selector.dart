import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/layout/viewport_dialog_constraints.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/core/widgets/select_empty_content.dart';
import 'package:tawaq/feature/quran/domain/models/tafsir_source.dart';
import 'package:tawaq/feature/quran/presentation/widgets/quran_semantics.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/theme/theme.dart';

/// Searchable select for choosing a Quran tafsir source.
class TafsirSourceSelector extends ConsumerWidget {
  /// Creates a [TafsirSourceSelector].
  const TafsirSourceSelector({
    this.enabled = true,
    super.key,
  });

  /// Whether the selector accepts input.
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final colors = theme.colors;
    final typography = theme.typography;
    final l10n = context.l10n;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final sources = TafsirId.values;
    final selected = ref.watch(
      quranScreenSettingsProvider.select(
        (settings) =>
            settings.value?.selectedTafsir ??
            kDefaultTafsirId,
      ),
    );
    final fieldLabel = l10n.tafsir;

    return NonSelectable(
      child: QuranSemantics.labeledControl(
        name: fieldLabel,
        value: selected.displayLabel(isArabic: isArabic),
        enabled: enabled,
        excludeChild: true,
        child: FSelect<TafsirId>.searchBuilder(
          enabled: enabled,
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
                    .setSelectedTafsir(value);
              }
            },
          ),
          format: (source) => source.displayLabel(isArabic: isArabic),
          filter: (query) {
            if (query.isEmpty) return sources;
            final normalized = query.toLowerCase().trim();
            return sources.where(
              (source) =>
                  source.arabicName.toLowerCase().contains(normalized) ||
                  source.englishName.toLowerCase().contains(normalized) ||
                  source.language.toLowerCase().contains(normalized),
            );
          },
          contentBuilder: (_, _, values) => values
              .map(
                (source) => FSelectItem<TafsirId>(
                  value: source,
                  title: Text(source.displayLabel(isArabic: isArabic)),
                  subtitle: Text(
                    source.language,
                    style: typography.body.xs.copyWith(
                      color: colors.mutedForeground,
                    ),
                  ),
                ),
              )
              .toList(),
          contentEmptyBuilder: (_, _) => const SelectEmptyContent(),
        ),
      ),
    );
  }
}
