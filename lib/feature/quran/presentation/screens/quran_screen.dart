import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/feature/quran/domain/models/quran_layouts.dart';
import 'package:tawaq/feature/quran/presentation/hooks/quran_ayah_selection.dart';
import 'package:tawaq/feature/quran/presentation/widgets/quran_header_widget.dart';
import 'package:tawaq/feature/quran/presentation/widgets/quran_layout_widgets.dart'
    as layouts;
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/theme/theme.dart';

/// Screen that displays the Quran with various view modes.
class QuranScreen extends HookConsumerWidget {
  /// Creates a [QuranScreen] instance.
  const QuranScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useQuranAyahSelectionSync(ref);

    final viewMode = ref.watch(
      quranScreenSettingsProvider.select(
        (v) => v.value?.layout ?? QuranReadingLayout.studyMode,
      ),
    );

    const mushafPane = layouts.QuranMushafPane(
      key: ValueKey('quran-mushaf-pane'),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const QuranHeaderWidget(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: switch (viewMode) {
              // QuranReadingLayout.singlePage => layouts.SinglePageLayout(
              //   mushaf: mushafPane,
              // ),
              QuranReadingLayout.doublePage => const layouts.DoublePageLayout(
                mushaf: mushafPane,
              ),
              QuranReadingLayout.studyMode => const layouts.StudyModeLayout(
                mushaf: mushafPane,
              ),
            },
          ),
        ),
      ],
    );
  }
}
