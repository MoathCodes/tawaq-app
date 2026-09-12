import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/feature/quran/data/models/translation.dart';
import 'package:tawaq/feature/quran/domain/models/translation_source.dart';
import 'package:tawaq/feature/quran/presentation/models/study_panel_text_styles.dart';
import 'package:tawaq/feature/quran/presentation/providers/translation_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/quran_semantics.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/translation_source_selector.dart';
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
  const new({
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
    final typography = context.theme.typography;
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
          style: typography.body.sm.copyWith(
            color: muted ? colors.mutedForeground : colors.foreground,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Generic async study accordion body with source selector and content slot.
class StudyContentSection<T> extends StatelessWidget {
  /// Creates a study content section.
  const new({
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
          const FCircularProgress(),
          _selectorFooter(context, sourceSelector),
        ],
      ),
      error: (_, _) => _statusColumn(
        context: context,
        typography: typography,
        colors: colors,
        message: errorMessage,
      ),
      data: (data) {
        if (data == null) {
          return _statusColumn(
            context: context,
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
                        contentBuilder(data),
                        _selectorFooter(context, sourceSelector),
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
    required BuildContext context,
    required FTypography typography,
    required FColors colors,
    required String message,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _messagePlaceholder(typography, colors, message),
        _selectorFooter(
          // The footer owns the separator and keeps the source picker a
          // secondary control after the reading content/status.
          context,
          sourceSelector,
        ),
      ],
    );
  }

  Widget _selectorFooter(BuildContext context, Widget selector) {
    final colors = context.theme.colors;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Divider(
            height: 1,
            thickness: 1,
            color: colors.border.withValues(alpha: 0.55),
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(alignment: AlignmentDirectional.centerStart, child: selector),
        ],
      ),
    );
  }
}

/// Translation accordion body: source selector, loading states, and text.
class TranslationAccordionSection extends ConsumerWidget {
  /// Creates a translation accordion section.
  const new({
    required this.sura,
    required this.aya,
    required this.source,
    required this.enabled,
    required this.narrowPanel,
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

  /// Whether the study panel is narrower than the small breakpoint.
  final bool narrowPanel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final colors = theme.colors;
    final typography = theme.typography;
    final l10n = context.l10n;
    final sectionMinHeight = narrowPanel ? 72.0 : 120.0;

    final translationAsync = enabled
        ? ref.watch(ayahTranslationRowProvider(source, sura, aya))
        : const AsyncData<Translation?>(null);

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: sectionMinHeight),
      child: LayoutBuilder(
        builder: (context, constraints) => StudyContentSection<Translation?>(
          asyncValue: translationAsync,
          contentKey: '${source.name}-$sura-$aya',
          errorMessage: l10n.errorLoadingTranslation,
          emptyMessage: l10n.noTranslationAvailable,
          // The accordion title already names this section. Keep the select
          // compact while QuranSemantics retains its explicit field name.
          sourceSelector: const TranslationSourceSelector(showLabel: false),
          contentBuilder: (translation) => TranslationProse(
            translation: translation!,
            source: source,
            style: StudyPanelTextStyles.translation(
              context: context,
              typography: typography,
              colors: colors,
              source: source,
              containerWidth: constraints.maxWidth,
            ),
          ),
        ),
      ),
    );
  }
}

/// Renders a translation without changing its source punctuation or content.
///
/// Direction comes from the selected edition's metadata rather than the
/// interface locale or the first character of the translation.
class TranslationProse extends StatelessWidget {
  /// Creates a translation prose block.
  const TranslationProse({
    required this.translation,
    required this.source,
    required this.style,
    super.key,
  });

  /// Translation row returned by the bundled source database.
  final Translation translation;

  /// Selected source metadata.
  final TranslationId source;

  /// Source-aware prose style.
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final textDirection = source.direction == TranslationDirection.rtl
        ? TextDirection.rtl
        : TextDirection.ltr;
    return Directionality(
      textDirection: textDirection,
      child: ScopedSelectableText(
        translation.translation,
        style: style,
        textAlign: TextAlign.start,
        textDirection: textDirection,
      ),
    );
  }
}
