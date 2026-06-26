import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/core/layout/viewport_dialog_constraints.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/f_skeletonizer.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/quran_semantics.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/quran_division_ordinals.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/quran_division_select_item.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/quran_inline_select_prefix.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/theme/theme.dart';

/// Juz selector that only rebuilds when juz number changes.
class JuzSelector extends HookConsumerWidget {
  /// Creates a [JuzSelector] instance.
  const JuzSelector({
    this.showLabel = true,
    this.inlineLabel = false,
    super.key,
  });

  /// Whether the field label is shown above the select.
  final bool showLabel;

  /// Shows a muted in-field label prefix (for the Quran header rail).
  final bool inlineLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(quranMushafControllerProvider);
    final theme = context.theme;
    final l10n = context.l10n;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final allJuzs = useFuture(
      useMemoized(controller.getJuzs),
    );

    final fallbackJuzNumber = ref.watch(
      quranScreenSettingsProvider.select(
        (v) => v.value?.pageInfo.juzNumber,
      ),
    );

    return ListenableBuilder(
      listenable: controller.page,
      builder: (context, _) {
        final currentJuzNumber =
            controller.currentPageInfo?.juzNumber ?? fallbackJuzNumber;
        final selectedJuz = allJuzs.hasData && currentJuzNumber != null
            ? allJuzs.data?.firstWhere(
                (e) => e.number == currentJuzNumber,
                orElse: () => allJuzs.data!.first,
              )
            : null;

        final selectorReady =
            allJuzs.connectionState == ConnectionState.done && allJuzs.hasData;
        final juzFieldName = QuranSemantics.juzFieldName(l10n);

        return FSkeletonizer(
          enabled: allJuzs.connectionState == ConnectionState.waiting,
          child: QuranSemantics.labeledControl(
            name: juzFieldName,
            value: selectedJuz != null
                ? juzClosedLabel(
                    number: selectedJuz.number,
                    glyph: selectedJuz.glyph,
                    isArabic: isArabic,
                  )
                : null,
            enabled: selectorReady,
            excludeChild: true,
            child: FSelect<Juz>.searchBuilder(
              enabled: selectorReady,
              label: showLabel && !inlineLabel
                  ? Text(juzFieldName)
                  : const SizedBox.shrink(),
              prefixBuilder: inlineLabel
                  ? quranInlineSelectPrefixBuilder(juzFieldName)
                  : null,
              contentConstraints: selectPopoverPortalConstraints(context),
              style: selectStyle(
                colors: theme.colors,
                style: theme.style,
                typography: theme.typography,
                useQuranFont: isArabic,
              ),
              control: FSelectControl.lifted(
                value: selectedJuz,
                onChange: (v) async {
                  if (v != null) {
                    await controller.jumpToJuz(v.number);
                  }
                },
              ),
              format: (v) => localizedJuzNumericLabel(
                v.number,
                isArabic: isArabic,
              ),
              filter: (q) {
                return allJuzs.hasData
                    ? allJuzs.data!.where(
                        (e) => e.number.toString().contains(q),
                      )
                    : [];
              },
              contentBuilder: (_, _, vals) => vals
                  .map(
                    (v) => FSelectItem<Juz>(
                      value: v,
                      title: QuranSemantics.mergedChip(
                        child: QuranDivisionSelectItem.title(
                          context: context,
                          kind: QuranDivisionKind.juz,
                          number: v.number,
                          juzGlyph: v.glyph,
                        ),
                      ),
                      subtitle: QuranDivisionSelectItem.subtitle(
                        context: context,
                        kind: QuranDivisionKind.juz,
                        controller: controller,
                        startSurahNumber: v.startSurahNumber,
                        startAyahInSurah: v.startAyahInSurah,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        );
      },
    );
  }
}
