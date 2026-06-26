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
import 'package:tawaq/feature/quran/presentation/widgets/selectors/hizb_search.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/quran_division_ordinals.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/quran_division_select_item.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/quran_inline_select_prefix.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme.dart';
import 'package:tawaq/theme/theme_model.dart';

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
                ? localizedHizbTitle(selectedHizb.number, isArabic: isArabic)
                : null,
            enabled: selectorReady,
            excludeChild: true,
            child: FSelect<Hizb>.searchBuilder(
              enabled: selectorReady,
              label: showLabel && !inlineLabel
                  ? Text(hizbFieldName)
                  : const SizedBox.shrink(),
              prefixBuilder: inlineLabel
                  ? quranInlineSelectPrefixBuilder(hizbFieldName)
                  : null,
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
              format: (v) => localizedHizbTitle(v.number, isArabic: isArabic),
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
                      title: QuranDivisionSelectItem.title(
                        context: context,
                        kind: QuranDivisionKind.hizb,
                        number: v.number,
                      ),
                      subtitle: QuranDivisionSelectItem.subtitle(
                        context: context,
                        kind: QuranDivisionKind.hizb,
                        controller: controller,
                        startSurahNumber: v.startSurahNumber,
                        startAyahInSurah: v.startAyahInSurah,
                        startAyahUthmaniText: v.startAyahUthmaniText,
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

/// Visible for testing: builds the hizb tile subtitle widget.
Widget hizbSelectorStartAyahSubtitleForTest({
  required Hizb hizb,
  required MushafReaderController controller,
  required bool isArabic,
  required AppLocalizations l10n,
  required String fallbackSurahName,
}) {
  final appTheme = buildAppTheme(
    palette: AppPalette.zinc,
    themeMode: ThemeMode.light,
    touch: false,
    textScale: 1,
  );

  return FTheme(
    data: appTheme,
    child: MaterialApp(
      locale: Locale(isArabic ? 'ar' : 'en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => QuranDivisionSelectItem.subtitle(
          context: context,
          kind: QuranDivisionKind.hizb,
          controller: controller,
          startSurahNumber: hizb.startSurahNumber,
          startAyahInSurah: hizb.startAyahInSurah,
          startAyahUthmaniText: hizb.startAyahUthmaniText,
        ),
      ),
    ),
  );
}
