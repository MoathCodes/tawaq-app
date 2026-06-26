import 'dart:async';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/quran/domain/services/ayah_reference_logic.dart';
import 'package:tawaq/feature/quran/domain/use_cases/navigate_study_ayah.dart';
import 'package:tawaq/feature/quran/presentation/hooks/quran_ayah_selection.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/quran_semantics.dart';
import 'package:tawaq/feature/quran/presentation/widgets/surah_name_text.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/theme/theme.dart';

/// Header widget for the study panel.
class StudyPanelHeader extends ConsumerWidget {
  /// Creates a [StudyPanelHeader] instance.
  const StudyPanelHeader({super.key});

  Future<void> _navigateAyah(
    WidgetRef ref,
    int? currentAyahId,
    int delta,
  ) async {
    await navigateStudyAyah(
      ref: ref,
      currentAyahId: currentAyahId,
      delta: delta,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(quranMushafControllerProvider);
    final selectedAyah = ref.watch(
      quranScreenSettingsProvider.select(
        (value) => value.value?.selectedAyah,
      ),
    );
    // Effective surah: prefer the selected ayah, falling back to the page's
    // primary surah only when nothing is selected. Folding the fallback into a
    // single selection means scrolling pages doesn't rebuild the header while
    // an ayah is selected (the `??` short-circuits to the stable ayah value).
    final surahNumber = ref.watch(
      quranScreenSettingsProvider.select(
        (value) =>
            value.value?.selectedAyah?.surahNumber ??
            value.value?.pageInfo.primarySurahNumber,
      ),
    );
    final currentAyahId = selectedAyah?.ayahId;
    final ayahNumber = selectedAyah?.numberInSurah;

    final theme = context.theme;
    final colors = theme.colors;
    final typography = theme.typography;
    final l10n = context.l10n;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final surahName = () {
      final number = surahNumber;
      if (number == null || number <= 0) return l10n.defaultSurahName;
      final surah = controller.getSurahSync(number);
      return AyahReferenceLogic.surahName(
        surah,
        number,
        preferArabic: isArabic,
        fallbackName: l10n.surahNameDefault(number),
      );
    }();

    final atFirstAyah = currentAyahId == 1;
    final atLastAyah = currentAyahId == kMaxQuranAyahId;
    final contextLabelStyle = typography.body.sm.copyWith(
      color: colors.mutedForeground,
    );
    final contextLabelWidget = ayahNumber != null
        ? SurahNameWithSuffix(
            surahName: surahName,
            suffix: ' • ${l10n.ayahLabel} $ayahNumber',
            style: contextLabelStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          )
        : SurahNameText(
            surahName,
            style: contextLabelStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
    final headerLabel = ayahNumber != null
        ? '${l10n.studyMode}, ${l10n.surahAyahInfo(surahName, ayahNumber)}'
        : l10n.studyMode;

    final isRtl = Directionality.of(context) == TextDirection.rtl;
    const collapseHandleInset = 40.0;

    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: AppSpacing.lg + (!isRtl ? collapseHandleInset : 0),
        end: AppSpacing.lg + (isRtl ? 0 : collapseHandleInset),
        top: AppSpacing.lg,
        bottom: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          QuranSemantics.sectionHeader(
            label: headerLabel,
            child: Row(
              children: [
                QuranSemantics.decorative(
                  Icon(FLucideIcons.bookOpen, size: 20, color: colors.primary),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: QuranSemantics.decorative(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.studyMode,
                          style: typography.body.md.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.foreground,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        contextLabelWidget,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              QuranSemantics.labeledControl(
                name: l10n.back,
                button: true,
                enabled: !atFirstAyah,
                excludeChild: true,
                child: FButton.icon(
                  onPress: atFirstAyah
                      ? null
                      : () => unawaited(_navigateAyah(ref, currentAyahId, -1)),
                  variant: .secondary,
                  child: QuranSemantics.decorative(
                    const Icon(FLucideIcons.arrowLeft),
                  ),
                ),
              ),
              QuranSemantics.labeledControl(
                name: l10n.next,
                button: true,
                enabled: !atLastAyah,
                excludeChild: true,
                child: FButton.icon(
                  onPress: atLastAyah
                      ? null
                      : () => unawaited(_navigateAyah(ref, currentAyahId, 1)),
                  variant: .secondary,
                  child: QuranSemantics.decorative(
                    const Icon(FLucideIcons.arrowRight),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
