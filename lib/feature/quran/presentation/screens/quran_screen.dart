import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/hooks/use_mushaf_controller.dart';
import 'package:hasanat/core/widgets/custom_cards.dart';
import 'package:hasanat/feature/quran/domain/models/quran_layouts.dart';
import 'package:hasanat/feature/quran/presentation/providers/audio_player_provider.dart';
import 'package:hasanat/feature/quran/presentation/widgets/study_panel.dart';
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
    // Controllers with auto-dispose
    final controller = useMushafController(
      initialPage: ref.read(stateSettingsProvider).value?.lastQuranPage ?? 1,
    );

    void onAyahTapped(AyahInfo info) {
      // Update the global audio player state
      ref
          .read(audioPlayerProvider.notifier)
          .selectAyahById(
            info.ayahId,
            ayahNumber: info.verseNumber,
          );
    }

    void goBackAPage() {
      unawaited(
        controller.animateToPage(controller.currentPage - 1),
      );
    }

    void moveAPage() {
      unawaited(
        controller.animateToPage(controller.currentPage + 1),
      );
    }

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        // Header bar
        _HeaderWidget(
          mushafController: controller,
          // toggleAudioPlayer: toggleAudioPlayer,
        ),
        // Main content
        Expanded(
          child: Padding(
            padding: const .only(bottom: AppSpacing.sm),
            child: CallbackShortcuts(
              bindings: <ShortcutActivator, VoidCallback>{
                const SingleActivator(LogicalKeyboardKey.arrowLeft): moveAPage,
                const SingleActivator(LogicalKeyboardKey.arrowRight):
                    goBackAPage,
                const SingleActivator(LogicalKeyboardKey.space): moveAPage,
              },
              child: Focus(
                autofocus: true,
                child: _MainContentWidget(
                  controller: controller,
                  onAyahTapped: onAyahTapped,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderWidget extends HookWidget {
  const _HeaderWidget({required this.mushafController});

  final MushafReaderController mushafController;

  @override
  Widget build(BuildContext context) {
    final colors = FTheme.of(context).colors;

    return HookConsumer(
      builder: (context, ref, child) {
        final audioPlayerState = ref.read(audioPlayerProvider);
        final isAudioActive = audioPlayerState.isActive;
        final layout = ref.watch(
          stateSettingsProvider.select(
            (value) => value.value?.lastLayout ?? QuranReadingLayout.studyMode,
          ),
        );
        return Padding(
          padding: const .symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // View mode tabs
              SizedBox(
                width: 140,
                child: FTabs(
                  control: .lifted(
                    index: layout.index,
                    onChange: (value) => ref
                        .read(stateSettingsProvider.notifier)
                        .setLastLayout(QuranReadingLayout.values[value]),
                  ),
                  style: (style) => style.copyWith(
                    padding: const .all(2),
                    indicatorSize: FTabBarIndicatorSize.tab,
                  ),
                  children: [
                    for (final mode in QuranReadingLayout.values)
                      FTabEntry(
                        label: Icon(mode.icon, size: 14),
                        child: const SizedBox.shrink(),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              // Surah selector
              const _SurahSelectorWidget(),
              const SizedBox(width: AppSpacing.sm),
              // Juz selector
              SizedBox(
                width: 200,
                height: 50,
                child: FSelect<int>.searchBuilder(
                  control: .managed(
                    initial: mushafController.currentPageInfo?.juzNumber,
                    onChange: (value) async {
                      if (value != null) {
                        await mushafController.jumpToJuz(value);
                      }
                    },
                  ),
                  format: (value) => value.toString(),
                  filter: (query) {
                    final syncValues = mushafController.getJuzsSync();
                    return (syncValues.isNotEmpty
                            ? Future.value(syncValues)
                            : mushafController.getJuzs())
                        .then(
                          (value) => value
                              .where((e) => e.number.toString().contains(query))
                              .map(
                                (e) => e.number,
                              ),
                        );
                  },
                  contentBuilder: (context, query, values) => values
                      .map(
                        (value) => FSelectItem<int>(
                          value: value,
                          title: Text('Juz $value'),
                        ),
                      )
                      .toList(),
                ),
              ),
              const Spacer(),
              // Play/Stop audio button
              FButton.icon(
                onPress: () {},
                style: isAudioActive
                    ? FButtonStyle.primary()
                    : FButtonStyle.secondary(),
                child: Icon(
                  isAudioActive ? FIcons.pause : FIcons.play,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Search button
              FButton.icon(
                onPress: () {},
                style: FButtonStyle.ghost(),
                child: Icon(
                  FIcons.search,
                  size: 18,
                  color: colors.mutedForeground,
                ),
              ),
              // Bookmark button
              FButton.icon(
                onPress: () {},
                style: FButtonStyle.ghost(),
                child: Icon(
                  FIcons.bookmark,
                  size: 18,
                  color: colors.mutedForeground,
                ),
              ),
              // Translation toggle
              FButton.icon(
                onPress: () {},
                style: FButtonStyle.ghost(),
                child: Icon(
                  FIcons.type,
                  size: 18,
                  color: colors.mutedForeground,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SurahSelectorWidget extends StatelessWidget {
  const _SurahSelectorWidget();

  @override
  Widget build(BuildContext context) {
    final colors = FTheme.of(context).colors;
    final typography = FTheme.of(context).typography;

    return Container(
      padding: const .symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.secondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const .symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '2',
              style: typography.xs.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.primaryForeground,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Al-Baqarah',
            style: typography.sm.copyWith(
              fontWeight: FontWeight.w500,
              color: colors.foreground,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Icon(
            FIcons.chevronDown,
            size: 14,
            color: colors.mutedForeground,
          ),
        ],
      ),
    );
  }
}

// class _JuzSelectorWidget extends StatelessWidget {
//   const _JuzSelectorWidget();

//   @override
//   Widget build(BuildContext context) {
//     final colors = FTheme.of(context).colors;
//     final typography = FTheme.of(context).typography;

//     return Container(
//       padding: const .symmetric(horizontal: 12, vertical: 6),
//       decoration: BoxDecoration(
//         color: colors.secondary,
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: colors.border),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text(
//             'Juz 1',
//             style: typography.sm.copyWith(
//               fontWeight: FontWeight.w500,
//               color: colors.foreground,
//             ),
//           ),
//           const SizedBox(width: AppSpacing.xs),
//           Icon(
//             FIcons.chevronDown,
//             size: 14,
//             color: colors.mutedForeground,
//           ),
//         ],
//       ),
//     );
//   }
// }

class _MainContentWidget extends ConsumerWidget {
  const _MainContentWidget({
    required this.controller,
    required this.onAyahTapped,
  });

  final MushafReaderController controller;
  final void Function(AyahInfo) onAyahTapped;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FTheme.of(context);
    final viewMode = ref.watch(
      stateSettingsProvider.select(
        (value) => value.value?.lastLayout ?? QuranReadingLayout.studyMode,
      ),
    );

    final mushafStyle = MushafStyle(
      ayahStyleModifier: (defaultStyle) =>
          defaultStyle.copyWith(color: theme.colors.foreground),
      juzStyleModifier: (defaultStyle) => defaultStyle.copyWith(
        color: theme.colors.mutedForeground,
      ),
      pageNumberStyleModifier: (defaultStyle) => defaultStyle.copyWith(
        color: theme.colors.mutedForeground,
      ),
      surahNameStyleModifier: (defaultStyle) => defaultStyle.copyWith(
        color: theme.colors.mutedForeground,
      ),
      basmalahStyleModifier: (defaultStyle) => defaultStyle.copyWith(
        color: theme.colors.foreground,
      ),

      activeAyahStyleModifier: (defaultStyle) => defaultStyle.copyWith(
        backgroundColor: theme.colors.primary,
        color: theme.colors.primaryForeground,
      ),
      headerSurahNameStyleModifier: (defaultStyle) =>
          defaultStyle.copyWith(fontSize: 22, color: Colors.brown.shade800),

      // selectedAyahTextColor: theme.colors.primaryForeground,
      // surahHeaderBorderColor: theme.colors.border,
    );
    void onPageNumberChanged(int page) {
      unawaited(
        ref.read(stateSettingsProvider.notifier).setLastQuranPage(page),
      );
    }

    final child = switch (viewMode) {
      .singlePage => _SinglePageModeWidget(
        controller: controller,
        onAyahTapped: onAyahTapped,
        mushafStyle: mushafStyle,
        onPageNumberChanged: onPageNumberChanged,
      ),
      .doublePage => _TwoPageModeWidget(
        controller: controller,
        onAyahTapped: onAyahTapped,
        mushafStyle: mushafStyle,
        onPageNumberChanged: ((int, int) v) => onPageNumberChanged(v.$1),
      ),
      .studyMode => _StudyModeWidget(
        mushafStyle: mushafStyle,
        controller: controller,
        onPageNumberChanged: onPageNumberChanged,
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

class _SinglePageModeWidget extends StatelessWidget {
  const _SinglePageModeWidget({
    required this.controller,
    required this.onAyahTapped,
    required this.mushafStyle,
    required this.onPageNumberChanged,
  });

  final MushafReaderController controller;
  final MushafStyle mushafStyle;
  final void Function(AyahInfo) onAyahTapped;
  final void Function(int) onPageNumberChanged;

  @override
  Widget build(BuildContext context) {
    return HoverCard(
      child: MushafReader(
        controller: controller,
        onAyahTap: onAyahTapped,
        style: mushafStyle,
        onPageNumberChanged: onPageNumberChanged,
      ),
    );
  }
}

class _TwoPageModeWidget extends StatelessWidget {
  const _TwoPageModeWidget({
    required this.controller,
    required this.onAyahTapped,
    required this.mushafStyle,
    required this.onPageNumberChanged,
  });

  final MushafReaderController controller;
  final MushafStyle mushafStyle;
  final void Function(AyahInfo) onAyahTapped;
  final void Function((int, int)) onPageNumberChanged;

  @override
  Widget build(BuildContext context) {
    final colors = FTheme.of(context).colors;

    return HoverCard(
      child: MushafTwoPageReader(
        key: ValueKey(
          'two-page-reader-${colors.secondaryForeground.hashCode}',
        ),
        controller: controller,
        style: mushafStyle,
        onAyahTap: onAyahTapped,
        onPageNumberChanged: onPageNumberChanged,
      ),
    );
  }
}

class _StudyModeWidget extends StatelessWidget {
  const _StudyModeWidget({
    required this.mushafStyle,
    required this.controller,
    required this.onPageNumberChanged,
  });

  final MushafStyle mushafStyle;
  final MushafReaderController controller;
  final void Function(int) onPageNumberChanged;

  @override
  Widget build(BuildContext context) {
    // final resizeController = useFResizableController();
    const double studyPanelWidth = 350;
    const double spacer = 20;
    final content = HoverCard(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: MushafReader(
            controller: controller,
            style: mushafStyle,
            onPageNumberChanged: onPageNumberChanged,
          ),
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final quranWidth = constraints.maxWidth - studyPanelWidth - spacer;
        return Consumer(
          builder: (context, ref, child) {
            final isArabic =
                ref.watch(localeProvider).value?.languageCode == 'ar';
            return Directionality(
              textDirection: .ltr,
              child: FResizable(
                // control: .managed(controller: resizeController),
                axis: .horizontal,
                children: [
                  // Study panel (left side)
                  .region(
                    initialExtent: isArabic ? quranWidth : studyPanelWidth,
                    minExtent: isArabic ? null : 250,
                    builder: (context, value, child) => Align(
                      child: Padding(
                        padding: const .fromSTEB(0, 0, 8, 0),
                        child: isArabic ? content : const _StudyPanelWrapper(),
                      ),
                    ),
                  ),
                  // Mushaf reader (right side, main area)
                  .region(
                    initialExtent: isArabic ? studyPanelWidth : quranWidth,
                    minExtent: isArabic ? 250 : null,
                    builder: (context, value, child) => Align(
                      child: Padding(
                        padding: const .fromSTEB(8, 0, 0, 0),
                        child: isArabic ? const _StudyPanelWrapper() : content,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Wrapper that watches ayah state via Riverpod,
/// isolating rebuilds from FResizable.
class _StudyPanelWrapper extends ConsumerWidget {
  const _StudyPanelWrapper();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioPlayerProvider);

    return StudyPanel(
      selectedAyahId: audioState.selectedAyahId,
      surahName: audioState.surahName,
      ayahNumber: audioState.currentAyahNumber,
    );
  }
}
