import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/bootstrap/app_init_providers.dart';
import 'package:tawaq/feature/quran/domain/models/quran_ui_models.dart';
import 'package:tawaq/feature/quran/presentation/hooks/quran_ayah_selection.dart';
import 'package:tawaq/feature/quran/presentation/widgets/quran_header_widget.dart';
import 'package:tawaq/feature/quran/presentation/widgets/quran_mushaf_pane.dart';
import 'package:tawaq/feature/quran/presentation/widgets/study_mode_layout.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/theme/theme.dart';

/// Screen that displays the Quran with various view modes.
class QuranScreen extends HookConsumerWidget {
  /// Creates a [QuranScreen] instance.
  const QuranScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(mushafLibraryInitProvider);
    useQuranAyahSelectionSync(ref);

    final viewMode = ref.watch(
      quranScreenSettingsProvider.select(
        (v) => v.value?.layout ?? QuranReadingLayout.studyMode,
      ),
    );

    const mushafPane = QuranMushafPane(
      key: ValueKey('quran-mushaf-pane'),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const QuranHeaderWidget(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: QuranMushafInitGate(
              child: switch (viewMode) {
                QuranReadingLayout.doublePage => mushafPane,
                QuranReadingLayout.studyMode => const StudyModeLayout(
                  mushaf: mushafPane,
                ),
              },
            ),
          ),
        ),
      ],
    );
  }
}
