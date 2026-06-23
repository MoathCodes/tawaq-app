import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/core/layout/viewport_dialog_constraints.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/f_skeletonizer.dart';
import 'package:tawaq/feature/quran/domain/services/ayah_reference_logic.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/quran_semantics.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/hizb_search.dart';
import 'package:tawaq/feature/quran/presentation/widgets/surah_name_text.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/theme.dart';

String _hizbStartAyahSubtitle({
  required Hizb hizb,
  required MushafReaderController controller,
  required bool isArabic,
  required AppLocalizations l10n,
  required String fallbackSurahName,
}) {
  final surahNumber = hizb.startSurahNumber;
  final ayahInSurah = hizb.startAyahInSurah;
  if (surahNumber == null || ayahInSurah == null) return '';

  final surah = controller.getSurahSync(surahNumber);
  final surahName = AyahReferenceLogic.surahName(
    surah,
    surahNumber,
    preferArabic: isArabic,
    fallbackName: fallbackSurahName,
  );
  return l10n.surahAyahInfo(surahName, ayahInSurah);
}

Widget _hizbStartAyahSubtitleWidget({
  required Hizb hizb,
  required MushafReaderController controller,
  required bool isArabic,
  required AppLocalizations l10n,
  required String fallbackSurahName,
  required TextStyle style,
}) {
  final reference = _hizbStartAyahSubtitle(
    hizb: hizb,
    controller: controller,
    isArabic: isArabic,
    l10n: l10n,
    fallbackSurahName: fallbackSurahName,
  );
  if (reference.isEmpty) return const SizedBox.shrink();

  if (isArabic) {
    return AyahReferenceText(reference, style: style);
  }
  return Text(reference, style: style);
}

/// Hizb selector with rich tiles (hizb label + starting ayah reference).
class HizbSelector extends HookConsumerWidget {
  /// Creates a [HizbSelector] instance.
  const HizbSelector({this.showLabel = true, super.key});

  /// Whether the field label is shown above the select.
  final bool showLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(quranMushafControllerProvider);
    final theme = context.theme;
    final l10n = context.l10n;
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
        final hizbFieldName = QuranSemantics.hizbFieldName(l10n);

        return FSkeletonizer(
          enabled: allHizbs.connectionState == ConnectionState.waiting,
          child: QuranSemantics.labeledControl(
            name: hizbFieldName,
            value: selectedHizb != null
                ? l10n.hizbLabel(selectedHizb.number)
                : null,
            enabled: selectorReady,
            excludeChild: true,
            child: FSelect<Hizb>.searchBuilder(
              enabled: selectorReady,
              label: showLabel ? Text(hizbFieldName) : const SizedBox.shrink(),
              contentConstraints: selectPopoverPortalConstraints(context),
              style: selectStyle(
                colors: theme.colors,
                style: theme.style,
                typography: theme.typography,
                useQuranFont: isArabic,
              ),
              control: FSelectControl.lifted(
                value: selectedHizb,
                onChange: (v) async {
                  if (v != null) {
                    await controller.jumpToHizb(v.number);
                  }
                },
              ),
              format: (v) => l10n.hizbLabel(v.number),
              filter: (q) => searchHizbs(
                hizbs: allHizbs.data ?? const [],
                controller: controller,
                query: q,
                isArabic: isArabic,
              ),
              contentBuilder: (_, _, vals) => vals
                  .map(
                    (v) => FSelectItem<Hizb>(
                      value: v,
                      title: Text(l10n.hizbLabel(v.number)),
                      subtitle: _hizbStartAyahSubtitleWidget(
                        hizb: v,
                        controller: controller,
                        isArabic: isArabic,
                        l10n: l10n,
                        fallbackSurahName: l10n.surahNameDefault(
                          v.startSurahNumber ?? 1,
                        ),
                        style: theme.typography.body.sm.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
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

/// Visible for testing: builds the hizb tile subtitle from denormalized fields.
String hizbSelectorStartAyahSubtitleForTest({
  required Hizb hizb,
  required MushafReaderController controller,
  required bool isArabic,
  required AppLocalizations l10n,
  required String fallbackSurahName,
}) =>
    _hizbStartAyahSubtitle(
      hizb: hizb,
      controller: controller,
      isArabic: isArabic,
      l10n: l10n,
      fallbackSurahName: fallbackSurahName,
    );
