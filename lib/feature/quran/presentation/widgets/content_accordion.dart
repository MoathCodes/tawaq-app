import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/feature/quran/domain/models/tafsir_source.dart';
import 'package:hasanat/feature/quran/domain/models/translation.dart';
import 'package:hasanat/feature/quran/domain/models/translation_source.dart';
import 'package:hasanat/feature/quran/presentation/providers/tafsir_provider.dart';
import 'package:hasanat/feature/quran/presentation/providers/translation_provider.dart';
import 'package:hasanat/feature/quran/presentation/widgets/tafsir_text.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hasanat/theme/theme.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Content accordion displaying tafsir, translation, and word analysis.
class ContentAccordion extends HookConsumerWidget {
  /// Creates a [ContentAccordion] instance.
  const ContentAccordion({
    required this.colors,
    required this.typography,
    required this.sura,
    required this.aya,
    required this.hasSelectedAyah,
    super.key,
  });

  /// The color scheme.
  final FColors colors;

  /// The typography styles.
  final FTypography typography;

  /// The surah number.
  final int sura;

  /// The ayah number.
  final int aya;

  /// Whether an ayah is selected.
  final bool hasSelectedAyah;

  Widget _sectionTitle(IconData icon, String text) => Row(
    children: [
      Icon(icon, size: 16, color: colors.primary),
      const SizedBox(width: AppSpacing.sm),
      Text(text),
    ],
  );

  Widget _errorPlaceholder(String message) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
    child: Text(
      message,
      style: typography.sm.copyWith(
        color: colors.mutedForeground,
      ),
    ),
  );

  Widget _noAyahSelectedMessage(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
    child: Row(
      children: [
        Icon(
          FIcons.info,
          size: 16,
          color: colors.mutedForeground,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            context.l10n.selectAyahToSeeContent,
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
    // Watch accordion states from provider
    final tafsirEnabled = ref.watch(
      stateSettingsProvider.select(
        (v) => v.value?.quranState.tafsirEnabled ?? true,
      ),
    );
    final translationEnabled = ref.watch(
      stateSettingsProvider.select(
        (v) => v.value?.quranState.translationEnabled ?? true,
      ),
    );

    // Fetch tafsir from service (only when ayah is selected)
    final tafsirFuture = useMemoized(
      () => hasSelectedAyah
          ? ref
                .read(tafsirServiceProvider)
                .getTafsir(TafsirId.tafseerMouaser, sura, aya)
          : Future<dynamic>.value(),
      [sura, aya, hasSelectedAyah],
    );
    final tafsirSnapshot = useFuture(tafsirFuture);

    // Fetch translation from service (only when ayah is selected)
    final translationFuture = useMemoized(
      () => hasSelectedAyah
          ? ref
                .read(translationServiceProvider)
                .getTranslation(TranslationId.saheehInternational, sura, aya)
          : Future<Translation?>.value(),
      [sura, aya, hasSelectedAyah],
    );
    final translationSnapshot = useFuture(translationFuture);

    return FAccordion(
      control: FAccordionControl.lifted(
        expanded: (index) => switch (index) {
          0 => tafsirEnabled,
          1 => translationEnabled,
          _ => false,
        },
        onChange: (index, isExpanded) {
          switch (index) {
            case 0:
              ref
                  .read(stateSettingsProvider.notifier)
                  .setTafsirEnabled(
                    enabled: isExpanded,
                  );
            case 1:
              ref
                  .read(stateSettingsProvider.notifier)
                  .setTranslationEnabled(
                    enabled: isExpanded,
                  );
          }
        },
      ),
      style: (style) => style.copyWith(
        dividerStyle: FDividerStyle(
          color: colors.border,
          padding: EdgeInsets.zero,
        ).call,
      ),
      children: [
        FAccordionItem(
          title: _sectionTitle(
            FIcons.messageSquare,
            context.l10n.tafsir,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 120),
            child: hasSelectedAyah
                ? _buildTafsirContent(context, tafsirSnapshot)
                : _noAyahSelectedMessage(context),
          ),
        ),
        FAccordionItem(
          title: _sectionTitle(
            FIcons.languages,
            context.l10n.translation,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 120),
            child: hasSelectedAyah
                ? _buildTranslationContent(context, translationSnapshot)
                : _noAyahSelectedMessage(context),
          ),
        ),
      ],
    );
  }

  Widget _buildTafsirContent(
    BuildContext context,
    AsyncSnapshot<dynamic> snapshot,
  ) {
    final l10n = context.l10n;
    final isLoading = snapshot.connectionState == ConnectionState.waiting;

    if (snapshot.hasError) {
      return _errorPlaceholder(l10n.errorLoadingTafsir);
    }
    if (!isLoading && snapshot.data == null) {
      return _errorPlaceholder(l10n.noTafsirAvailable);
    }

    final tafsirText = snapshot.data?.ayaTafseer as String? ?? '';

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: isLoading
          ? const SizedBox.shrink()
          : Padding(
                  key: ValueKey(tafsirText),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            l10n.sourceLabel,
                            style: typography.sm.copyWith(
                              color: colors.mutedForeground,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          FBadge(
                            style: FBadgeStyle.secondary(),
                            child: Text(l10n.tafsirAlMuyassar),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TafsirText(
                        text: tafsirText,
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
  }

  Widget _buildTranslationContent(
    BuildContext context,
    AsyncSnapshot<Translation?> snapshot,
  ) {
    final l10n = context.l10n;
    final isLoading = snapshot.connectionState == ConnectionState.waiting;

    if (snapshot.hasError) {
      return _errorPlaceholder(l10n.errorLoadingTranslation);
    }
    if (!isLoading && snapshot.data == null) {
      return _errorPlaceholder(l10n.noTranslationAvailable);
    }

    final translation = snapshot.data;
    final translationText = translation?.translation ?? '';

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: isLoading
          ? const SizedBox.shrink()
          : Padding(
                  key: ValueKey(translationText),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${l10n.languageLabel}:',
                            style: typography.sm.copyWith(
                              color: colors.mutedForeground,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          FBadge(
                            style: FBadgeStyle.secondary(),
                            child: Text(l10n.englishLanguage),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        '"$translationText"',
                        style: typography.sm.copyWith(
                          color: colors.foreground,
                          height: 1.6,
                          fontStyle: FontStyle.italic,
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
  }
}
