import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/feature/quran/data/models/translation.dart';
import 'package:tawaq/feature/quran/domain/models/tafsir_source.dart';
import 'package:tawaq/feature/quran/domain/models/translation_source.dart';
import 'package:tawaq/feature/quran/presentation/models/study_panel_text_styles.dart';
import 'package:tawaq/feature/quran/presentation/providers/tafsir_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/translation_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/quran_semantics.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/tafsir_source_selector.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/translation_source_selector.dart';
import 'package:tawaq/feature/quran/presentation/widgets/study/study_panel_width_scope.dart';
import 'package:tawaq/feature/quran/presentation/widgets/study/tafsir_text.dart';
import 'package:tawaq/theme/theme.dart';

/// Builds a study accordion title row.
Widget studyAccordionTitle(
  BuildContext context, {
  required String label,
  required IconData icon,
  required bool hasSelectedAyah,
  required bool expanded,
}) {
  final colors = context.theme.colors;
  final l10n = context.l10n;
  return QuranSemantics.labeledControl(
    name: label,
    value: hasSelectedAyah
        ? (expanded ? l10n.collapse : null)
        : l10n.selectAyahToSeeContent,
    enabled: hasSelectedAyah,
    button: true,
    excludeChild: true,
    child: StudySectionTitle(
      colors: colors,
      icon: icon,
      text: label,
      muted: !hasSelectedAyah,
    ),
  );
}

/// Shared title row for tafsir and translation accordion sections.
class StudySectionTitle extends StatelessWidget {
  /// Creates a study section title row.
  const StudySectionTitle({
    required this.colors,
    required this.icon,
    required this.text,
    this.muted = false,
    super.key,
  });

  /// Theme colors for icon and text.
  final FColors colors;

  /// Leading icon.
  final IconData icon;

  /// Section label.
  final String text;

  /// When true, title uses muted styling.
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Row(
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
  }
}

/// Generic async study accordion body with source selector and content slot.
class StudyContentSection<T> extends StatelessWidget {
  /// Creates a study content section.
  const StudyContentSection({
    required this.asyncValue,
    required this.contentKey,
    required this.errorMessage,
    required this.emptyMessage,
    required this.sourceSelector,
    required this.contentBuilder,
    super.key,
  });

  /// Async content for the section.
  final AsyncValue<T?> asyncValue;

  /// Key used to animate content swaps.
  final Object contentKey;

  /// Message shown on load error.
  final String errorMessage;

  /// Message shown when content is null.
  final String emptyMessage;

  /// Source picker shown above content (tafsir/translation selector).
  final Widget sourceSelector;

  /// Builds the loaded content widget.
  final Widget Function(T data) contentBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final typography = theme.typography;

    return asyncValue.when(
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          sourceSelector,
          const SizedBox(height: AppSpacing.md),
          const FCircularProgress(),
        ],
      ),
      error: (_, _) => _statusColumn(
        typography: typography,
        colors: colors,
        message: errorMessage,
      ),
      data: (data) {
        if (data == null) {
          return _statusColumn(
            typography: typography,
            colors: colors,
            message: emptyMessage,
          );
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child:
              Padding(
                    key: ValueKey(contentKey),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        sourceSelector,
                        const SizedBox(height: AppSpacing.lg),
                        contentBuilder(data),
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

  Widget _messagePlaceholder(
    FTypography typography,
    FColors colors,
    String message,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Text(
        message,
        style: typography.body.sm.copyWith(color: colors.mutedForeground),
      ),
    );
  }

  Widget _statusColumn({
    required FTypography typography,
    required FColors colors,
    required String message,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        sourceSelector,
        const SizedBox(height: AppSpacing.md),
        _messagePlaceholder(typography, colors, message),
      ],
    );
  }
}

/// Tafsir accordion body with source selector, loading, and parsed commentary.
class TafsirAccordionSection extends ConsumerWidget {
  /// Creates a tafsir accordion section.
  const TafsirAccordionSection({
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

  /// Active tafsir source from persisted settings.
  final TafsirId? source;

  /// Whether the tafsir accordion is expanded and should fetch content.
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final colors = theme.colors;
    final typography = theme.typography;
    final l10n = context.l10n;
    final resolvedSource = source ?? kDefaultTafsirId;
    final narrowPanel = StudyPanelWidthScope.isNarrow(context);
    final sectionMinHeight = narrowPanel ? 72.0 : 120.0;

    final parsedAsync = enabled
        ? ref.watch(parsedTafsirProvider(resolvedSource, sura, aya))
        : const AsyncData(null);

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: sectionMinHeight),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return StudyContentSection(
            asyncValue: parsedAsync,
            contentKey: '${resolvedSource.name}-$sura-$aya',
            errorMessage: l10n.errorLoadingTafsir,
            emptyMessage: l10n.noTafsirAvailable,
            sourceSelector: const TafsirSourceSelector(),
            contentBuilder: (parsed) => TafsirText(
              parseResult: parsed,
              tafsirId: resolvedSource,
              baseStyle: StudyPanelTextStyles.tafsirBase(
                context: context,
                typography: typography,
                colors: colors,
                containerWidth: constraints.maxWidth,
              ),
            ),
          );
        },
      ),
    );
  }
}

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
    final narrowPanel = StudyPanelWidthScope.isNarrow(context);
    final sectionMinHeight = narrowPanel ? 72.0 : 120.0;

    final translationAsync = enabled
        ? ref.watch(ayahTranslationProvider(sura, aya))
        : const AsyncData<Translation?>(null);

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: sectionMinHeight),
      child: StudyContentSection<Translation?>(
        asyncValue: translationAsync,
        contentKey: '${source.name}-$sura-$aya',
        errorMessage: l10n.errorLoadingTranslation,
        emptyMessage: l10n.noTranslationAvailable,
        sourceSelector: const TranslationSourceSelector(),
        contentBuilder: (translation) => ScopedSelectableText(
          l10n.quranTranslationQuoted(translation!.translation),
          style: StudyPanelTextStyles.translation(
            typography: typography,
            colors: colors,
            source: source,
          ),
        ),
      ),
    );
  }
}
