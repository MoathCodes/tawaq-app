import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hasanat/theme/theme.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mushaf_reader/mushaf_reader.dart';

/// Header widget for the study panel.
class StudyPanelHeader extends ConsumerWidget {
  /// Creates a [StudyPanelHeader] instance.
  const StudyPanelHeader({
    required this.colors,
    required this.typography,
    required this.controller,
    this.surahName,
    this.ayahNumber,
    this.currentAyahId,
    super.key,
  });

  /// The color scheme.
  final FColors colors;

  /// The typography styles.
  final FTypography typography;

  /// The mushaf reader controller.
  final MushafReaderController controller;

  /// The current surah name.
  final String? surahName;

  /// The current ayah number.
  final int? ayahNumber;

  /// The current ayah ID.
  final int? currentAyahId;

  /// Maximum ayah ID in the Quran.
  static const int _maxAyahId = 6236;

  void _navigateAyah(WidgetRef ref, int delta) {
    if (currentAyahId == null) {
      // If no ayah selected, select first ayah on current page
      controller.getPage(controller.currentPage).then((page) {
        if (page.surahs.isNotEmpty) {
          final firstFragment = page.surahs.first.ayahs.firstOrNull;
          if (firstFragment != null) {
            controller.getAyah(firstFragment.ayahId).then((ayah) {
              ref.read(stateSettingsProvider.notifier).selectAyah(ayah);
              controller.jumpToAyah(ayah.ayahId, select: true);
            });
          }
        }
      });
      return;
    }

    final newAyahId = (currentAyahId! + delta).clamp(1, _maxAyahId);
    if (newAyahId == currentAyahId) return;

    controller.getAyah(newAyahId).then((ayah) {
      ref.read(stateSettingsProvider.notifier).selectAyah(ayah);
      controller.jumpToAyah(ayah.ayahId, select: true);
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(FIcons.bookOpen, size: 20, color: colors.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.studyMode,
                      style: typography.base.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.foreground,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      ayahNumber != null
                          ? context.l10n.surahAyahInfo(
                              surahName ?? context.l10n.defaultSurahName,
                              ayahNumber!,
                            )
                          : surahName ?? context.l10n.defaultSurahName,
                      style: typography.sm.copyWith(
                        color: colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FButton.icon(
                onPress: () => _navigateAyah(ref, -1), // Previous ayah
                style: FButtonStyle.secondary(),
                child: const Icon(FIcons.arrowLeft),
              ),
              FButton.icon(
                onPress: () => _navigateAyah(ref, 1), // Next ayah
                style: FButtonStyle.secondary(),
                child: const Icon(FIcons.arrowRight),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
