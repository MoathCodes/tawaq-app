import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/quran/domain/services/ayah_reference_logic.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/quran_semantics.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/quran_division_ordinals.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/quran_division_search_select.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/quran_glyph_text.dart';
import 'package:tawaq/feature/quran/presentation/widgets/surah_name_text.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_screen_settings_provider.dart';
import 'package:tawaq/gen/fonts.gen.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/theme.dart';

/// English closed/list label for a Juz.
String englishJuzLabel(int n) => 'Juz $n';

/// Locale-aware Juz title for closed fields and search (not the glyph).
String localizedJuzNumericLabel(int n, {required bool isArabic}) {
  return isArabic ? 'الجزء ${arabicJuzOrdinal(n)}' : englishJuzLabel(n);
}

/// Closed-field label for a Juz: AR glyph only; EN `Juz N`.
String juzClosedLabel({
  required int number,
  required String glyph,
  required bool isArabic,
}) {
  if (isArabic) {
    return glyph.isNotEmpty ? glyph : arabicJuzOrdinal(number);
  }
  return englishJuzLabel(number);
}

/// Title row for a Juz list item or closed field preview.
Widget juzSelectTitle({
  required BuildContext context,
  required int number,
  String? glyph,
  TextStyle? style,
}) {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';

  if (isArabic) {
    return Text(
      localizedJuzNumericLabel(number, isArabic: true),
      textDirection: TextDirection.rtl,
      style: (style ?? const TextStyle()).copyWith(
        fontFamily: FontFamily.uthmanicHafs,
      ),
    );
  }

  final juzGlyph = glyph ?? '';
  if (juzGlyph.isNotEmpty) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        JuzNameText(juzGlyph, style: style, fontSize: 28),
        const SizedBox(width: AppSpacing.sm),
        Text(englishJuzLabel(number), style: style),
      ],
    );
  }
  return Text(englishJuzLabel(number), style: style);
}

/// Subtitle row for a Juz list item (start surah reference).
Widget juzSelectSubtitle({
  required BuildContext context,
  required MushafReaderController controller,
  int? startSurahNumber,
  int? startAyahInSurah,
}) {
  final theme = context.theme;
  final l10n = context.l10n;
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  final subtitleStyle = theme.typography.body.sm.copyWith(
    color: theme.colors.mutedForeground,
  );

  if (startSurahNumber == null || startAyahInSurah == null) {
    return const SizedBox.shrink();
  }

  final surah = controller.getSurahSync(startSurahNumber);
  if (isArabic) {
    final glyph = surah?.glyph;
    if (glyph != null && glyph.isNotEmpty) {
      return SurahGlyphText(glyph, style: subtitleStyle, fontSize: 24);
    }
    final surahName = AyahReferenceLogic.surahName(
      surah,
      startSurahNumber,
      preferArabic: true,
      fallbackName: l10n.surahNameDefault(startSurahNumber),
    );
    return SurahNameText(surahName, style: subtitleStyle);
  }

  final surahName = AyahReferenceLogic.surahName(
    surah,
    startSurahNumber,
    preferArabic: false,
    fallbackName: l10n.surahNameDefault(startSurahNumber),
  );
  return Text(
    l10n.surahAyahInfo(surahName, startAyahInSurah),
    style: subtitleStyle,
  );
}

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
        final juzFieldName = QuranSemantics.juzFieldName(context.l10n);

        return QuranDivisionSearchSelect<Juz>(
          fieldName: juzFieldName,
          closedValue: selectedJuz != null
              ? juzClosedLabel(
                  number: selectedJuz.number,
                  glyph: selectedJuz.glyph,
                  isArabic: isArabic,
                )
              : null,
          ready: selectorReady,
          loading: allJuzs.connectionState == ConnectionState.waiting,
          enabled: selectorReady,
          value: selectedJuz,
          showLabel: showLabel,
          inlineLabel: inlineLabel,
          useQuranFont: isArabic,
          format: (v) => localizedJuzNumericLabel(v.number, isArabic: isArabic),
          filter: (q) => allJuzs.hasData
              ? allJuzs.data!.where((e) => e.number.toString().contains(q))
              : [],
          onChanged: (v) async {
            if (v != null) await controller.jumpToJuz(v.number);
          },
          contentBuilder: (context, vals) => vals
              .map(
                (v) => FSelectItem<Juz>(
                  value: v,
                  title: QuranSemantics.mergedChip(
                    child: juzSelectTitle(
                      context: context,
                      number: v.number,
                      glyph: v.glyph,
                    ),
                  ),
                  subtitle: juzSelectSubtitle(
                    context: context,
                    controller: controller,
                    startSurahNumber: v.startSurahNumber,
                    startAyahInSurah: v.startAyahInSurah,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}
