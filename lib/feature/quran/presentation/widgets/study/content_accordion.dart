import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/layout/responsive.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/quran/data/sources/quran_content_registry.dart';
import 'package:tawaq/feature/quran/presentation/widgets/quran_semantics.dart';
import 'package:tawaq/feature/quran/presentation/widgets/study/tafsir_accordion_section.dart';
import 'package:tawaq/feature/quran/presentation/widgets/study/translation_accordion_section.dart';
import 'package:tawaq/feature/settings/presentation/provider/ui_state_settings_providers.dart';
import 'package:tawaq/theme/theme.dart';

/// Content accordion displaying tafsir and translation for the selected ayah.
class ContentAccordion extends ConsumerWidget {
  /// Creates a [ContentAccordion] instance.
  const ContentAccordion({this.panelWidth, super.key});

  /// Allocated study-panel width for density-aware layout.
  final double? panelWidth;

  Widget _sectionTitle(
    FColors colors,
    IconData icon,
    String text, {
    bool muted = false,
  }) => Row(
    children: [
      QuranSemantics.decorative(
        Icon(
          icon,
          size: 16,
          color: muted ? colors.mutedForeground : colors.primary,
        ),
      ),
      const SizedBox(width: AppSpacing.sm),
      Text(
        text,
        style: TextStyle(
          color: muted ? colors.mutedForeground : null,
        ),
      ),
    ],
  );

  Widget _noAyahSelectedMessage(
    FColors colors,
    FTypography typography,
    String message,
  ) => Padding(
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
            message,
            style: typography.body.sm.copyWith(
              color: colors.mutedForeground,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    ),
  );

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
            v.value?.selectedTranslation ??
            QuranContentRegistry.defaultTranslation,
      ),
    );

    final narrowPanel = panelWidth != null
        ? panelWidth! < context.theme.breakpoints.sm
        : isLessThan(context, FBreakpoint.sm);
    final sectionMinHeight = narrowPanel ? 72.0 : 120.0;

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
                  title: QuranSemantics.labeledControl(
                    name: l10n.tafsir,
                    value: hasSelectedAyah
                        ? (tafsirEnabled ? l10n.collapse : null)
                        : l10n.selectAyahToSeeContent,
                    enabled: hasSelectedAyah,
                    button: true,
                    excludeChild: true,
                    child: _sectionTitle(
                      colors,
                      FLucideIcons.messageSquare,
                      l10n.tafsir,
                      muted: !hasSelectedAyah,
                    ),
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: sectionMinHeight),
                    child: TafsirAccordionSection(
                      sura: sura,
                      aya: aya,
                      source: selectedTafsir,
                      enabled: hasSelectedAyah && tafsirEnabled,
                    ),
                  ),
                ),
                FAccordionItem(
                  title: QuranSemantics.labeledControl(
                    name: l10n.translation,
                    value: hasSelectedAyah
                        ? (translationEnabled ? l10n.collapse : null)
                        : l10n.selectAyahToSeeContent,
                    enabled: hasSelectedAyah,
                    button: true,
                    excludeChild: true,
                    child: _sectionTitle(
                      colors,
                      FLucideIcons.languages,
                      l10n.translation,
                      muted: !hasSelectedAyah,
                    ),
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: sectionMinHeight),
                    child: TranslationAccordionSection(
                      sura: sura,
                      aya: aya,
                      source: selectedTranslation,
                      enabled: hasSelectedAyah && translationEnabled,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!hasSelectedAyah) ...[
          const SizedBox(height: AppSpacing.md),
          _noAyahSelectedMessage(
            colors,
            typography,
            l10n.selectAyahToSeeContent,
          ),
        ],
      ],
    );
  }
}
