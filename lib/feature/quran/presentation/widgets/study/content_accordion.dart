import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/quran/data/models/tafsir.dart';
import 'package:tawaq/feature/quran/data/models/translation.dart';
import 'package:tawaq/feature/quran/domain/models/tafsir_source.dart';
import 'package:tawaq/feature/quran/presentation/providers/tafsir_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/translation_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/quran_semantics.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/tafsir_source_selector.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/translation_source_selector.dart';
import 'package:tawaq/feature/quran/presentation/widgets/study/tafsir_text.dart';
import 'package:tawaq/feature/settings/presentation/provider/ui_state_settings_providers.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/theme.dart';

/// Content accordion displaying tafsir and translation for the selected ayah.
class ContentAccordion extends ConsumerWidget {
  /// Creates a [ContentAccordion] instance.
  const ContentAccordion({
    required this.sura,
    required this.aya,
    required this.hasSelectedAyah,
    super.key,
  });

  /// The surah number.
  final int sura;

  /// The ayah number.
  final int aya;

  /// Whether an ayah is selected.
  final bool hasSelectedAyah;

  Widget _sectionTitle(
    FColors colors,
    IconData icon,
    String text, {
    bool muted = false,
  }) =>
      Row(
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

  Widget _errorPlaceholder(
    FColors colors,
    FTypography typography,
    String message,
  ) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
    child: Text(
      message,
      style: typography.sm.copyWith(
        color: colors.mutedForeground,
      ),
    ),
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
            style: typography.sm.copyWith(
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

    final tafsirAsync = hasSelectedAyah
        ? ref.watch(ayahTafsirProvider(sura, aya))
        : const AsyncData<Tafsir?>(null);
    final translationAsync = hasSelectedAyah
        ? ref.watch(ayahTranslationProvider(sura, aya))
        : const AsyncData<Translation?>(null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AbsorbPointer(
          absorbing: !hasSelectedAyah,
          child: Opacity(
            opacity: hasSelectedAyah ? 1 : 0.45,
            child: FAccordion(
              control: FAccordionControl.lifted(
                expanded: (index) => hasSelectedAyah && switch (index) {
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
                    constraints: const BoxConstraints(minHeight: 120),
                    child: _buildTafsirContent(
                      l10n,
                      colors,
                      typography,
                      tafsirAsync,
                      selectedTafsir,
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
                    constraints: const BoxConstraints(minHeight: 120),
                    child: _buildTranslationContent(
                      l10n,
                      colors,
                      typography,
                      translationAsync,
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

  Widget _buildTafsirContent(
    AppLocalizations l10n,
    FColors colors,
    FTypography typography,
    AsyncValue<Tafsir?> asyncValue,
    TafsirId? source,
  ) {
    return asyncValue.when(
      loading: () => const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TafsirSourceSelector(),
          SizedBox(height: AppSpacing.md),
          FCircularProgress(),
        ],
      ),
      error: (_, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TafsirSourceSelector(),
          const SizedBox(height: AppSpacing.md),
          _errorPlaceholder(
            colors,
            typography,
            l10n.errorLoadingTafsir,
          ),
        ],
      ),
      data: (tafsir) {
        if (tafsir == null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const TafsirSourceSelector(),
              const SizedBox(height: AppSpacing.md),
              _errorPlaceholder(
                colors,
                typography,
                l10n.noTafsirAvailable,
              ),
            ],
          );
        }

        final tafsirText = tafsir.ayaTafseer;

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Padding(
                  key: ValueKey('${source?.name ?? ''}-$sura-$aya'),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const TafsirSourceSelector(),
                      const SizedBox(height: AppSpacing.lg),
                      TafsirText(
                        text: tafsirText,
                        tafsirId: source,
                        baseStyle: typography.sm.copyWith(
                          color: colors.foreground,
                          fontFamily: 'UthmanTN',
                          height: 1.8,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(duration: 250.ms, curve: Curves.easeOut)
                .slideY(
                  begin: 0.02,
                  end: 0,
                  duration: 250.ms,
                  curve: Curves.easeOut,
                ),
        );
      },
    );
  }

  Widget _buildTranslationContent(
    AppLocalizations l10n,
    FColors colors,
    FTypography typography,
    AsyncValue<Translation?> asyncValue,
  ) {
    return asyncValue.when(
      loading: () => const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TranslationSourceSelector(),
          SizedBox(height: AppSpacing.md),
          FCircularProgress(),
        ],
      ),
      error: (_, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TranslationSourceSelector(),
          const SizedBox(height: AppSpacing.md),
          _errorPlaceholder(
            colors,
            typography,
            l10n.errorLoadingTranslation,
          ),
        ],
      ),
      data: (translation) {
        if (translation == null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const TranslationSourceSelector(),
              const SizedBox(height: AppSpacing.md),
              _errorPlaceholder(
                colors,
                typography,
                l10n.noTranslationAvailable,
              ),
            ],
          );
        }

        final translationText = translation.translation;

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Padding(
                  key: ValueKey('$sura-$aya-$translationText'),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const TranslationSourceSelector(),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        l10n.quranTranslationQuoted(translationText),
                        style: typography.sm.copyWith(
                          color: colors.foreground,
                          height: 1.6,
                          fontStyle: FontStyle.italic,
                          fontFamily: translation.fontFamily,
                        ),
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(duration: 250.ms, curve: Curves.easeOut)
                .slideY(
                  begin: 0.02,
                  end: 0,
                  duration: 250.ms,
                  curve: Curves.easeOut,
                ),
        );
      },
    );
  }
}
