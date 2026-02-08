import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/hooks/use_mushaf_controller.dart';
import 'package:hasanat/feature/quran/domain/models/font_sizes.dart';
import 'package:hasanat/feature/quran/domain/models/quran_layouts.dart';
import 'package:hasanat/feature/quran/presentation/widgets/header_widget.dart';
import 'package:hasanat/feature/quran/presentation/widgets/quran_layout_widgets.dart'
    as layouts;
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hasanat/theme/theme.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mushaf_reader/mushaf_reader.dart';

/// Screen that displays the Quran with various view modes.
class QuranScreen extends HookConsumerWidget {
  /// Creates a [QuranScreen] instance.
  const QuranScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useMushafController(
      initialPage: ref.read(
        stateSettingsProvider.select(
          (v) => v.value?.quranState.pageInfo.pageNumber ?? 1,
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QuranHeaderWidget(mushafController: controller),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _MainContentWidget(
              controller: controller,
              onAyahTapped: (info) async {
                final previous = ref.read(
                  stateSettingsProvider.select(
                    (v) => v.value?.quranState.selectedAyah,
                  ),
                );
                if (previous?.ayahId == info.ayahId) {
                  ref.read(stateSettingsProvider.notifier).selectAyah(null);
                } else {
                  ref.read(stateSettingsProvider.notifier).selectAyah(info);
                }
              },
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

  MushafStyle _buildStyle(
    FThemeData theme, [
    FontSizes fontSize = FontSizes.medium,
  ]) => MushafStyle(
    ayahStyleModifier: (s) =>
        s.copyWith(color: theme.colors.foreground, fontSize: fontSize.size),
    juzStyleModifier: (s) => s.copyWith(color: theme.colors.mutedForeground),
    pageNumberStyleModifier: (s) =>
        s.copyWith(color: theme.colors.mutedForeground),
    surahNameStyleModifier: (s) =>
        s.copyWith(color: theme.colors.mutedForeground),
    basmalahStyleModifier: (s) => s.copyWith(color: theme.colors.foreground),
    activeAyahStyleModifier: (s) => s.copyWith(
      backgroundColor: theme.colors.primary,
      color: theme.colors.primaryForeground,
      fontSize: fontSize.size,
    ),
    headerSurahNameStyleModifier: (s) =>
        s.copyWith(fontSize: 22, color: Colors.brown.shade800),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FTheme.of(context);
    final viewMode = ref.watch(
      stateSettingsProvider.select(
        (v) => v.value?.quranState.layout ?? QuranReadingLayout.studyMode,
      ),
    );

    void savePageInfo(MushafPageInfo info) => unawaited(
      ref.read(stateSettingsProvider.notifier).setLastQuranPageInfo(info),
    );

    final child = switch (viewMode) {
      // QuranReadingLayout.singlePage => layouts.SinglePageLayout(
      //   controller: controller,
      //   buildStyle: _buildStyle,
      //   theme: theme,
      //   onPageChanged: savePageInfo,
      //   onAyahTapped: onAyahTapped,
      // ),
      QuranReadingLayout.doublePage => layouts.DoublePageLayout(
        controller: controller,
        buildStyle: _buildStyle,
        theme: theme,
        onPageChanged: savePageInfo,
        onAyahTapped: onAyahTapped,
      ),
      QuranReadingLayout.studyMode => layouts.StudyModeLayout(
        buildStyle: _buildStyle,
        theme: theme,
        controller: controller,
        onPageChanged: savePageInfo,
        onAyahTapped: onAyahTapped,
      ),
    };

    return KeyedSubtree(
      key: ValueKey(viewMode),
      child: child
          .animate()
          .fadeIn(duration: context.theme.durations.fast, curve: Curves.easeOut)
          .scale(
            begin: const Offset(0.98, 0.98),
            end: const Offset(1, 1),
            duration: context.theme.durations.normal,
            curve: Curves.easeOutCubic,
          ),
    );
  }
}
