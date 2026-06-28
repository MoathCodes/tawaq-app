import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/quran/domain/models/translation_source.dart';
import 'package:tawaq/feature/quran/presentation/widgets/study/study_content_section.dart';
import 'package:tawaq/feature/settings/presentation/provider/ui_state_settings_providers.dart';
import 'package:tawaq/theme/theme.dart';

/// Content accordion displaying tafsir and translation for the selected ayah.
class ContentAccordion extends ConsumerWidget {
  /// Creates a [ContentAccordion] instance.
  const ContentAccordion({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final colors = theme.colors;
    final typography = theme.typography;
    final l10n = context.l10n;

    final selectedAyah = ref.watch(
      quranScreenSettingsProvider.select((v) => v.value?.selectedAyah),
    );
    final hasSelectedAyah = selectedAyah != null;
    final sura = selectedAyah?.surahNumber ?? 1;
    final aya = selectedAyah?.numberInSurah ?? 1;

    final tafsirEnabled = ref.watch(
      quranScreenSettingsProvider.select(
        (v) => v.value?.tafsirEnabled ?? true,
      ),
    );
    final translationEnabled = ref.watch(
      quranScreenSettingsProvider.select(
        (v) => v.value?.translationEnabled ?? true,
      ),
    );
    final selectedTafsir = ref.watch(
      quranScreenSettingsProvider.select(
        (v) => v.value?.selectedTafsir,
      ),
    );
    final selectedTranslation = ref.watch(
      quranScreenSettingsProvider.select(
        (v) =>
            v.value?.selectedTranslation ?? kDefaultTranslationId,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AbsorbPointer(
          absorbing: !hasSelectedAyah,
          child: Opacity(
            opacity: hasSelectedAyah ? 1 : 0.45,
            child: FAccordion(
              control: FAccordionControl.lifted(
                expanded: (index) =>
                    hasSelectedAyah &&
                    switch (index) {
                      0 => tafsirEnabled,
                      1 => translationEnabled,
                      _ => false,
                    },
                onChange: (index, isExpanded) {
                  if (!hasSelectedAyah) return;
                  switch (index) {
                    case 0:
                      ref
                          .read(quranScreenSettingsProvider.notifier)
                          .setTafsirEnabled(
                            enabled: isExpanded,
                          );
                    case 1:
                      ref
                          .read(quranScreenSettingsProvider.notifier)
                          .setTranslationEnabled(
                            enabled: isExpanded,
                          );
                  }
                },
              ),
              style: .delta(
                dividerStyle: .delta(
                  color: colors.border,
                  padding: const .value(EdgeInsets.zero),
                ),
              ),
              children: [
                FAccordionItem(
                  title: studyAccordionTitle(
                    context,
                    label: l10n.tafsir,
                    icon: FLucideIcons.messageSquare,
                    hasSelectedAyah: hasSelectedAyah,
                    expanded: tafsirEnabled,
                  ),
                  child: TafsirAccordionSection(
                    sura: sura,
                    aya: aya,
                    source: selectedTafsir,
                    enabled: hasSelectedAyah && tafsirEnabled,
                  ),
                ),
                FAccordionItem(
                  title: studyAccordionTitle(
                    context,
                    label: l10n.translation,
                    icon: FLucideIcons.languages,
                    hasSelectedAyah: hasSelectedAyah,
                    expanded: translationEnabled,
                  ),
                  child: TranslationAccordionSection(
                    sura: sura,
                    aya: aya,
                    source: selectedTranslation,
                    enabled: hasSelectedAyah && translationEnabled,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!hasSelectedAyah) ...[
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Row(
              children: [
                Icon(
                  FLucideIcons.info,
                  size: 16,
                  color: colors.mutedForeground,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.selectAyahToSeeContent,
                    style: typography.body.sm.copyWith(
                      color: colors.mutedForeground,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
