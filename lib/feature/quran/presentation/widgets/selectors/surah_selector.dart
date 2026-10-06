import 'dart:async';

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/quran/domain/services/ayah_reference_logic.dart';
import 'package:tawaq/feature/quran/domain/services/quran_search_query.dart';
export 'package:tawaq/feature/quran/domain/services/quran_search_query.dart'
    show searchSurahs;
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/quran_semantics.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/quran_division_search_select.dart';
import 'package:tawaq/feature/quran/presentation/widgets/surah_name_text.dart';

/// Searchable surah picker shared by the Quran header and range dialog.
class SurahSearchSelect extends HookConsumerWidget {
  /// Creates a [SurahSearchSelect].
  const new({
    required this.value,
    required this.onChanged,
    required this.label,
    this.enabled = true,
    this.showLabel = true,
    this.inlineLabel = false,
    this.size = FTextFieldSizeVariant.md,
    super.key,
  });

  /// Selected surah number (1–114), or null when unset.
  final int? value;

  /// Called when the user picks a surah.
  final ValueChanged<int> onChanged;

  /// Field label shown above the control.
  final String label;

  /// Whether the control accepts input.
  final bool enabled;

  /// Whether the field label is shown above the select.
  final bool showLabel;

  /// Shows a muted in-field label prefix (for the Quran header rail).
  final bool inlineLabel;

  /// Text field size variant. Defaults to [FTextFieldSizeVariant.md].
  final FTextFieldSizeVariant size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(quranMushafControllerProvider);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    String localizedName(Surah surah) => AyahReferenceLogic.surahName(
      surah,
      surah.number,
      preferArabic: isArabic,
      fallbackName: '',
    );
    final allSurahs = useFuture(useMemoized(controller.getAllSurahs));

    final selectedSurah = allSurahs.hasData && value != null
        ? allSurahs.data?.cast<Surah?>().firstWhere(
            (s) => s?.number == value,
            orElse: () => null,
          )
        : null;

    final ready =
        allSurahs.connectionState == ConnectionState.done && allSurahs.hasData;

    return QuranDivisionSearchSelect<Surah>(
      fieldName: label,
      closedValue: selectedSurah == null ? null : localizedName(selectedSurah),
      ready: ready,
      loading: allSurahs.connectionState == ConnectionState.waiting,
      enabled: enabled,
      value: selectedSurah,
      showLabel: showLabel,
      inlineLabel: inlineLabel,
      useQuranFont: isArabic,
      size: size,
      includeSemantics: false,
      format: localizedName,
      filter: (q) => searchSurahs(allSurahs.data ?? const [], q),
      onChanged: (v) {
        if (v != null) onChanged(v.number);
      },
      contentBuilder: (context, vals) => vals
          .map(
            (v) => FSelectItem<Surah>(
              value: v,
              title: isArabic
                  ? SurahNameText(localizedName(v))
                  : Text(localizedName(v)),
              subtitle: isArabic
                  ? Text(v.nameEnglish ?? v.englishNameTranslation ?? '')
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (v.englishNameTranslation?.isNotEmpty ?? false)
                          Text(v.englishNameTranslation!),
                        if (v.nameArabic != null) SurahNameText(v.nameArabic!),
                      ],
                    ),
            ),
          )
          .toList(),
    );
  }
}

/// A dropdown selector for choosing a Surah in the Quran reader.
class SurahSelector extends HookConsumerWidget {
  /// Creates a [SurahSelector] instance.
  const new({this.showLabel = true, this.inlineLabel = false, super.key});

  /// Whether the field label is shown above the select.
  final bool showLabel;

  /// Shows a muted in-field label prefix (for the Quran header rail).
  final bool inlineLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(quranMushafControllerProvider);
    final l10n = context.l10n;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final allSurahs = useFuture(useMemoized(controller.getAllSurahs));
    return ListenableBuilder(
      listenable: controller.page,
      builder: (context, _) {
        final currentSurahNumber =
            controller.currentPageInfo?.primarySurahNumber;
        final selectedSurah = allSurahs.hasData && currentSurahNumber != null
            ? allSurahs.data?.firstWhere(
                (e) => e.number == currentSurahNumber,
                orElse: () => allSurahs.data!.first,
              )
            : null;

        final selectorReady =
            allSurahs.connectionState == ConnectionState.done &&
            allSurahs.hasData;
        final surahFieldName = QuranSemantics.surahFieldName(l10n);
        final displayedValue = selectedSurah == null
            ? null
            : AyahReferenceLogic.surahName(
                selectedSurah,
                selectedSurah.number,
                preferArabic: isArabic,
                fallbackName: '',
              );

        return QuranSemantics.labeledControl(
          name: surahFieldName,
          value: displayedValue,
          enabled: selectorReady,
          child: SurahSearchSelect(
            value: currentSurahNumber,
            label: surahFieldName,
            showLabel: showLabel,
            inlineLabel: inlineLabel,
            enabled: selectorReady,
            onChanged: (number) => unawaited(controller.jumpToSurah(number)),
          ),
        );
      },
    );
  }
}
