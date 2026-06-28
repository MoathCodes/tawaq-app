import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/quran/domain/services/ayah_reference_logic.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/quran_semantics.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/hizb_search.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/quran_division_ordinals.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/quran_division_search_select.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_screen_settings_provider.dart';
import 'package:tawaq/gen/fonts.gen.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/theme.dart';

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
    fallbackName: l10n.surahNameDefault(startSurahNumber),
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
  const HizbSelector({this.showLabel = true, this.inlineLabel = false, super.key});

  /// Whether the field label is shown above the select.
  final bool showLabel;

  /// Shows a muted in-field label prefix (for the Quran header rail).
  final bool inlineLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(quranMushafControllerProvider);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final allHizbs = useFuture(useMemoized(controller.getHizbs));

    final fallbackFirstAyahId = ref.watch(
      quranScreenSettingsProvider.select(
        (v) => v.value?.pageInfo.firstAyahId,
      ),
    );

    return ListenableBuilder(
      listenable: controller.page,
      builder: (context, _) {
        final firstAyahId =
            controller.currentPageInfo?.firstAyahId ?? fallbackFirstAyahId;

        final selectorReady =
            allHizbs.connectionState == ConnectionState.done && allHizbs.hasData;

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
