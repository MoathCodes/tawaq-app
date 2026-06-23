import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/feature/quran/data/models/translation.dart';
import 'package:tawaq/feature/quran/domain/models/translation_source.dart';
import 'package:tawaq/feature/quran/presentation/models/study_panel_text_styles.dart';
import 'package:tawaq/feature/quran/presentation/providers/translation_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/translation_source_selector.dart';
import 'package:tawaq/feature/quran/presentation/widgets/study/study_accordion_async_shell.dart';

/// Translation accordion body: source selector, loading states, and text.
class TranslationAccordionSection extends ConsumerWidget {
  /// Creates a translation accordion section.
  const TranslationAccordionSection({
    required this.sura,
    required this.aya,
    required this.source,
    required this.enabled,
    super.key,
  });

  /// Surah number for the selected ayah.
  final int sura;

  /// Ayah number within the surah.
  final int aya;

  /// Active translation source from persisted settings.
  final TranslationId source;

  /// Whether the translation accordion is expanded and should fetch content.
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final colors = theme.colors;
    final typography = theme.typography;
    final l10n = context.l10n;

    final translationAsync = enabled
        ? ref.watch(ayahTranslationProvider(sura, aya))
        : const AsyncData<Translation?>(null);

    return StudyAccordionAsyncShell<Translation?>(
      asyncValue: translationAsync,
      header: const TranslationSourceSelector(),
      contentKey: '${source.name}-$sura-$aya',
      errorMessage: l10n.errorLoadingTranslation,
      emptyMessage: l10n.noTranslationAvailable,
      contentBuilder: (translation) => ScopedSelectableText(
        l10n.quranTranslationQuoted(translation!.translation),
        style: StudyPanelTextStyles.translation(
          typography: typography,
          colors: colors,
          source: source,
        ),
      ),
    );
  }
}
