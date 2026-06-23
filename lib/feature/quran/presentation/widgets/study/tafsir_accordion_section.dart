import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/quran/data/sources/quran_content_registry.dart';
import 'package:tawaq/feature/quran/domain/models/tafsir_source.dart';
import 'package:tawaq/feature/quran/presentation/models/study_panel_text_styles.dart';
import 'package:tawaq/feature/quran/presentation/providers/tafsir_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/tafsir_source_selector.dart';
import 'package:tawaq/feature/quran/presentation/widgets/study/study_accordion_async_shell.dart';
import 'package:tawaq/feature/quran/presentation/widgets/study/tafsir_text.dart';

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
    final resolvedSource =
        source ?? QuranContentRegistry.defaultTafsir;

    final parsedAsync = enabled
        ? ref.watch(parsedTafsirProvider(resolvedSource, sura, aya))
        : const AsyncData(null);

    return LayoutBuilder(
      builder: (context, constraints) {
        return StudyAccordionAsyncShell(
          asyncValue: parsedAsync,
          header: const TafsirSourceSelector(),
          contentKey: '${resolvedSource.name}-$sura-$aya',
          errorMessage: l10n.errorLoadingTafsir,
          emptyMessage: l10n.noTafsirAvailable,
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
    );
  }
}
