import 'dart:async';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/quran/domain/use_cases/navigate_study_ayah.dart';
import 'package:tawaq/feature/quran/presentation/hooks/quran_ayah_selection.dart';
import 'package:tawaq/feature/quran/presentation/widgets/quran_semantics.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/theme.dart';

/// Header widget for the study panel.
class StudyPanelHeader extends ConsumerWidget {
  /// Creates a [StudyPanelHeader] instance.
  const StudyPanelHeader({
    required this.controller,
    this.surahNumber,
    this.ayahNumber,
    this.currentAyahId,
    super.key,
  });

  /// The mushaf reader controller.
  final MushafReaderController controller;

  /// The current surah number (from page or selected ayah).
  final int? surahNumber;

  /// The current ayah number.
  final int? ayahNumber;

  /// The current ayah ID.
  final int? currentAyahId;

  Future<void> _navigateAyah(WidgetRef ref, int delta) async {
    await navigateStudyAyah(
      ref: ref,
      controller: controller,
      currentAyahId: currentAyahId,
      delta: delta,
    );
  }

  String _surahName(AppLocalizations l10n, bool isArabic) {
    final number = surahNumber;
    if (number == null || number <= 0) return l10n.defaultSurahName;
    final surah = controller.getSurahSync(number);
    if (surah == null) return l10n.surahNameDefault(number);
    return (isArabic ? surah.nameArabic : surah.nameEnglish) ??
        surah.nameArabic ??
        surah.nameEnglish ??
        l10n.surahNameDefault(number);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final colors = theme.colors;
    final typography = theme.typography;
    final l10n = context.l10n;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final surahName = _surahName(l10n, isArabic);

    final atFirstAyah = currentAyahId == 1;
    final atLastAyah = currentAyahId == kMaxQuranAyahId;
    final contextLabel = ayahNumber != null
        ? l10n.surahAyahInfo(surahName, ayahNumber!)
        : surahName;
    final headerLabel = ayahNumber != null
        ? '${l10n.studyMode}, $contextLabel'
        : l10n.studyMode;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
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
                          style: typography.md.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.foreground,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          contextLabel,
                          style: typography.sm.copyWith(
                            color: colors.mutedForeground,
                          ),
                        ),
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
                      : () => unawaited(_navigateAyah(ref, -1)),
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
                      : () => unawaited(_navigateAyah(ref, 1)),
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
