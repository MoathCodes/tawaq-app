import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/core/hooks/use_mushaf_controller.dart';
import 'package:tawaq/feature/quran/domain/models/quran_layouts.dart';
import 'package:tawaq/feature/quran/presentation/hooks/quran_ayah_selection.dart';
import 'package:tawaq/feature/quran/presentation/models/quran_mushaf_style.dart';
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
    final controller = useMushafController(
      initialPage: ref.read(
        quranScreenSettingsProvider.select(
          (v) => v.value?.pageInfo.pageNumber ?? 1,
        ),
      ),
    );
    useQuranAyahSelectionSync(ref, controller);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QuranHeaderWidget(mushafController: controller),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _MainContentWidget(
              controller: controller,
              onAyahTapped: (info) =>
                  toggleQuranAyahSelection(ref, controller, info),
            ),
          ),
        ),
      ],
    );
  }
}

class _MainContentWidget extends ConsumerWidget {
  const _MainContentWidget({
    required this.controller,
    required this.onAyahTapped,
  });
  final MushafReaderController controller;
  final void Function(Ayah) onAyahTapped;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(
      quranScreenSettingsProvider.select(
        (v) => v.value?.layout ?? QuranReadingLayout.studyMode,
      ),
    );

    void savePageInfo(MushafPageInfo info) =>
        ref.read(quranScreenSettingsProvider.notifier).setLastPageInfo(info);

    final mushafPane = layouts.QuranMushafPane(
      key: const ValueKey('quran-mushaf-pane'),
      controller: controller,
      layout: viewMode,
      buildStyle: buildQuranMushafStyle,
      onPageChanged: savePageInfo,
      onAyahTapped: onAyahTapped,
    );

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: switch (viewMode) {
        // QuranReadingLayout.singlePage => layouts.SinglePageLayout(
        //   mushaf: mushafPane,
        // ),
        QuranReadingLayout.doublePage => layouts.DoublePageLayout(
          mushaf: mushafPane,
        ),
        QuranReadingLayout.studyMode => layouts.StudyModeLayout(
          controller: controller,
          mushaf: mushafPane,
        ),
      },
    );
  }
}
