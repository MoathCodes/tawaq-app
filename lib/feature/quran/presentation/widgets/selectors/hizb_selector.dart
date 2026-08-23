import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/text/arabic_search_normalize.dart';
import 'package:tawaq/feature/quran/domain/services/ayah_reference_logic.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/quran_semantics.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/quran_division_ordinals.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/quran_division_search_select.dart';
import 'package:tawaq/gen/fonts.gen.dart';
import 'package:tawaq/theme/theme.dart';

/// Resolves the hizb (1–60) containing [ayahId] from denormalized bounds.
int? hizbNumberForAyahId(MushafReaderController controller, int ayahId) {
  for (var n = 1; n <= 60; n++) {
    final bounds = controller.hizbAyahBounds(n);
    if (bounds == null) continue;
    if (ayahId >= bounds.startAyahId && ayahId <= bounds.endAyahId) {
      return n;
    }
  }
  return null;
}

/// Ranks [hizbs] by relevance to [query] (number, prefix, or starting surah name).
Iterable<Hizb> searchHizbs({
  required List<Hizb> hizbs,
  required MushafReaderController controller,
  required String query,
  required bool isArabic,
}) {
  if (query.isEmpty) return hizbs;

  final normalized = query.toLowerCase().trim();
  final arabicQuery = normalizeArabicForSearch(normalized);
  final queryNum = int.tryParse(normalized);

  final results = <(Hizb, int)>[];
  for (final hizb in hizbs) {
    var score = 0;
    if (queryNum != null && hizb.number == queryNum) {
      score = 100;
    } else if (hizb.number.toString().startsWith(normalized)) {
      score = 80;
    } else {
      final surahNumber = hizb.startSurahNumber;
      if (surahNumber != null) {
        final surah = controller.getSurahSync(surahNumber);
        if (surah?.nameEnglish?.toLowerCase().startsWith(normalized) ?? false) {
          score = 70;
        } else if (surah?.nameArabicSimplified != null &&
            normalizeArabicForSearch(
              surah!.nameArabicSimplified!,
            ).startsWith(arabicQuery)) {
          score = 70;
        } else if (surah?.englishNameTranslation?.toLowerCase().startsWith(
              normalized,
            ) ??
            false) {
          score = 65;
        }
      }
    }
    if (score > 0) results.add((hizb, score));
  }

  results.sort((a, b) {
    final scoreCompare = b.$2.compareTo(a.$2);
    if (scoreCompare != 0) return scoreCompare;
    return a.$1.number.compareTo(b.$1.number);
  });

  return results.map((e) => e.$1);
}

/// English closed/list label for a Hizb.
String englishHizbLabel(int n) => 'Hizb $n';

/// Locale-aware Hizb title (`الحزب {ordinal}` or `Hizb N`).
String localizedHizbTitle(int n, {required bool isArabic}) {
  return isArabic ? 'الحزب ${arabicHizbOrdinal(n)}' : englishHizbLabel(n);
}

/// Title row for a Hizb list item or closed field preview.
Widget hizbSelectTitle({
  required BuildContext context,
  required int number,
  TextStyle? style,
}) {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  return Text(
    localizedHizbTitle(number, isArabic: isArabic),
    style: style,
  );
}

/// Subtitle row for a Hizb list item (Uthmani ayah preview).
Widget hizbSelectSubtitle({
  required BuildContext context,
  required MushafReaderController controller,
  int? startSurahNumber,
  int? startAyahInSurah,
  String? startAyahUthmaniText,
}) {
  final theme = context.theme;
  final l10n = context.l10n;
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  final subtitleStyle = theme.typography.body.sm.copyWith(
    color: theme.colors.mutedForeground,
  );

  final uthmani = startAyahUthmaniText?.trim();
  if (uthmani == null || uthmani.isEmpty) {
    return const SizedBox.shrink();
  }

  final uthmaniWidget = Text(
    uthmani,
    style: subtitleStyle.copyWith(fontFamily: FontFamily.uthmanicHafs),
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    textDirection: TextDirection.rtl,
  );

  if (isArabic) return uthmaniWidget;

  if (startSurahNumber == null || startAyahInSurah == null) {
    return uthmaniWidget;
  }

  final surah = controller.getSurahSync(startSurahNumber);
  final surahName = AyahReferenceLogic.surahName(
    surah,
    startSurahNumber,
    preferArabic: false,
    fallbackName: '',
  );
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        l10n.surahAyahInfo(surahName, startAyahInSurah),
        style: subtitleStyle,
      ),
      const SizedBox(height: AppSpacing.xs),
      uthmaniWidget,
    ],
  );
}

/// Hizb selector with rich tiles (hizb label + starting ayah Uthmani preview).
class HizbSelector extends HookConsumerWidget {
  /// Creates a [HizbSelector] instance.
  const new({
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
    final allHizbs = useFuture(useMemoized(controller.getHizbs));

    return ListenableBuilder(
      listenable: controller.page,
      builder: (context, _) {
        final firstAyahId = controller.currentPageInfo?.firstAyahId;

        final selectorReady =
            allHizbs.connectionState == ConnectionState.done &&
            allHizbs.hasData;

        final currentHizbNumber = selectorReady && firstAyahId != null
            ? hizbNumberForAyahId(controller, firstAyahId)
            : null;

        final selectedHizb = allHizbs.hasData && currentHizbNumber != null
            ? allHizbs.data?.firstWhere(
                (e) => e.number == currentHizbNumber,
                orElse: () => allHizbs.data!.first,
              )
            : null;
        final hizbFieldName = QuranSemantics.hizbFieldName(context.l10n);

        return QuranDivisionSearchSelect<Hizb>(
          fieldName: hizbFieldName,
          closedValue: selectedHizb != null
              ? localizedHizbTitle(selectedHizb.number, isArabic: isArabic)
              : null,
          ready: selectorReady,
          loading: allHizbs.connectionState == ConnectionState.waiting,
          enabled: selectorReady,
          value: selectedHizb,
          showLabel: showLabel,
          inlineLabel: inlineLabel,
          useQuranFont: isArabic,
          format: (v) => localizedHizbTitle(v.number, isArabic: isArabic),
          filter: (q) => searchHizbs(
            hizbs: allHizbs.data ?? const [],
            controller: controller,
            query: q,
            isArabic: isArabic,
          ),
          onChanged: (v) async {
            if (v != null) await controller.jumpToHizb(v.number);
          },
          contentBuilder: (context, vals) => vals
              .map(
                (v) => FSelectItem<Hizb>(
                  value: v,
                  title: hizbSelectTitle(
                    context: context,
                    number: v.number,
                  ),
                  subtitle: hizbSelectSubtitle(
                    context: context,
                    controller: controller,
                    startSurahNumber: v.startSurahNumber,
                    startAyahInSurah: v.startAyahInSurah,
                    startAyahUthmaniText: v.startAyahUthmaniText,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}
