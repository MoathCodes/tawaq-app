import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/widgets/custom_cards.dart';
import 'package:hasanat/feature/quran/presentation/providers/audio_player_provider.dart';
import 'package:hasanat/feature/quran/presentation/widgets/study_panel.dart';
import 'package:hasanat/theme/theme.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mushaf_reader/mushaf_reader.dart';

/// View modes for the Quran screen.
enum QuranViewMode {
  /// Single page mode - shows one Mushaf page.
  singlePage,

  /// Two page mode - shows two Mushaf pages side by side.
  twoPage,

  /// Study mode - shows Mushaf with Study Panel.
  study,
}

/// Screen that displays the Quran with various view modes.
class QuranScreen extends HookConsumerWidget {
  /// Creates a [QuranScreen] instance.
  const QuranScreen({super.key});

  // Mock data for current page ayahs
  static const List<int> _currentPageAyahIds = [1, 2, 3, 4, 5, 6, 7];
  static const String _currentSurahName = 'Al-Fatihah';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Controllers with auto-dispose
    final page1Controller = useMemoized(MushafReaderController.new);
    final page2Controller = useMemoized(
      () => MushafReaderController(initialPage: 2),
    );

    // Dispose controllers on unmount
    useEffect(
      () {
        return () {
          page1Controller.dispose();
          page2Controller.dispose();
        };
      },
      const [],
    );

    // State
    final viewMode = useState(QuranViewMode.twoPage);

    void onViewModeChanged(int index) {
      viewMode.value = QuranViewMode.values[index];
    }

    void onAyahTapped(AyahInfo info) {
      // Update the global audio player state
      ref
          .read(audioPlayerProvider.notifier)
          .selectAyahById(
            info.ayahId,
            ayahNumber: info.verseNumber,
          );
    }

    void toggleAudioPlayer() {
      final notifier = ref.read(audioPlayerProvider.notifier);
      final state = ref.read(audioPlayerProvider);

      if (state.isActive) {
        notifier.hidePlayer();
      } else {
        notifier.showPlayer(
          surahName: _currentSurahName,
          currentAyahNumber: state.currentAyahNumber,
          currentPage: page1Controller.currentPage,
          ayahIds: _currentPageAyahIds,
        );
      }
    }

    void goBackAPage() {
      unawaited(
        page1Controller.animateToPage(page1Controller.currentPage - 2),
      );
      if (viewMode.value == QuranViewMode.twoPage) {
        unawaited(
          page2Controller.animateToPage(page1Controller.currentPage + 1),
        );
      }
    }

    void moveAPage() {
      if (viewMode.value == QuranViewMode.twoPage) {
        unawaited(
          page1Controller.animateToPage(page2Controller.currentPage + 1),
        );
        unawaited(
          page2Controller.animateToPage(page1Controller.currentPage + 1),
        );
      } else {
        unawaited(
          page1Controller.animateToPage(page1Controller.currentPage + 1),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header bar
        _HeaderWidget(
          viewMode: viewMode.value,
          onViewModeChanged: onViewModeChanged,
          toggleAudioPlayer: toggleAudioPlayer,
        ),
        const FDivider(),
        // Main content
        Expanded(
          child: Row(
            spacing: 12,
            children: [
              // Left navigation button
              FButton.icon(
                onPress: goBackAPage,
                style: FButtonStyle.ghost(),
                child: const Icon(
                  FIcons.chevronLeft,
                  size: 24,
                ),
              ),
              // Main reading area
              Expanded(
                child: CallbackShortcuts(
                  bindings: <ShortcutActivator, VoidCallback>{
                    const SingleActivator(LogicalKeyboardKey.arrowLeft):
                        moveAPage,
                    const SingleActivator(LogicalKeyboardKey.arrowRight):
                        goBackAPage,
                    const SingleActivator(LogicalKeyboardKey.space): moveAPage,
                  },
                  child: Focus(
                    autofocus: true,
                    child: _MainContentWidget(
                      viewMode: viewMode.value,
                      page1Controller: page1Controller,
                      page2Controller: page2Controller,
                      onAyahTapped: onAyahTapped,
                    ),
                  ),
                ),
              ),
              // Right navigation button
              FButton.icon(
                onPress: moveAPage,
                style: FButtonStyle.ghost(),
                child: const Icon(
                  FIcons.chevronRight,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
        FSlider(
          control: const .managedDiscrete(),
          onEnd: (value) =>
              page1Controller.jumpToPage((value.max * 604).round()),
          tooltipBuilder: (controller, value) =>
              Text('Page ${(value * 604).round()}'),
          marks: List.generate(
            604,
            (index) => .mark(value: (index + 1) / 604),
          ),
        ),
      ],
    );
  }
}

class _HeaderWidget extends HookWidget {
  const _HeaderWidget({
    required this.viewMode,
    required this.onViewModeChanged,
    required this.toggleAudioPlayer,
  });

  final QuranViewMode viewMode;
  final void Function(int) onViewModeChanged;
  final VoidCallback toggleAudioPlayer;

  @override
  Widget build(BuildContext context) {
    final colors = FTheme.of(context).colors;

    return HookConsumer(
      builder: (context, ref, child) {
        final audioPlayerState = ref.read(audioPlayerProvider);
        final isAudioActive = audioPlayerState.isActive;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // View mode tabs
              SizedBox(
                width: 140,
                child: FTabs(
                  control: .managed(initial: viewMode.index),
                  onPress: onViewModeChanged,
                  style: (style) => style.copyWith(
                    padding: const EdgeInsets.all(2),
                    indicatorSize: FTabBarIndicatorSize.tab,
                  ),
                  children: const [
                    FTabEntry(
                      label: Icon(FIcons.book, size: 14),
                      child: SizedBox.shrink(),
                    ),
                    FTabEntry(
                      label: Icon(FIcons.columns2, size: 14),
                      child: SizedBox.shrink(),
                    ),
                    FTabEntry(
                      label: Icon(FIcons.panelRight, size: 14),
                      child: SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              // Surah selector
              const _SurahSelectorWidget(),
              const SizedBox(width: AppSpacing.sm),
              // Juz selector
              const _JuzSelectorWidget(),
              const Spacer(),
              // Play/Stop audio button
              FButton.icon(
                onPress: toggleAudioPlayer,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.secondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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

class _JuzSelectorWidget extends StatelessWidget {
  const _JuzSelectorWidget();

  @override
  Widget build(BuildContext context) {
    final colors = FTheme.of(context).colors;
    final typography = FTheme.of(context).typography;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.secondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Juz 1',
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

class _MainContentWidget extends StatelessWidget {
  const _MainContentWidget({
    required this.viewMode,
    required this.page1Controller,
    required this.page2Controller,
    required this.onAyahTapped,
  });

  final QuranViewMode viewMode;
  final MushafReaderController page1Controller;
  final MushafReaderController page2Controller;
  final void Function(AyahInfo) onAyahTapped;

  @override
  Widget build(BuildContext context) {
    return switch (viewMode) {
      QuranViewMode.singlePage => _SinglePageModeWidget(
        controller: page1Controller,
        onAyahTapped: onAyahTapped,
      ),
      QuranViewMode.twoPage => _TwoPageModeWidget(
        page1Controller: page1Controller,
        page2Controller: page2Controller,
        onAyahTapped: onAyahTapped,
      ),
      QuranViewMode.study => _StudyModeWidget(
        onAyahTap: onAyahTapped,
      ),
    };
  }
}

class _SinglePageModeWidget extends StatelessWidget {
  const _SinglePageModeWidget({
    required this.controller,
    required this.onAyahTapped,
  });

  final MushafReaderController controller;
  final void Function(AyahInfo) onAyahTapped;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 120),
      child: StaticCard(
        child: Center(
          child: MushafReader(
            controller: controller,
            onAyahTap: onAyahTapped,
          ),
        ),
      ),
    );
  }
}

class _TwoPageModeWidget extends StatelessWidget {
  const _TwoPageModeWidget({
    required this.page1Controller,
    required this.page2Controller,
    required this.onAyahTapped,
  });

  final MushafReaderController page1Controller;
  final MushafReaderController page2Controller;
  final void Function(AyahInfo) onAyahTapped;

  @override
  Widget build(BuildContext context) {
    final colors = FTheme.of(context).colors;

    return StaticCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: MushafReader(
              controller: page1Controller,
              onAyahTap: onAyahTapped,
            ),
          ),
          FDivider(
            axis: Axis.vertical,
            style: (style) => style.copyWith(color: colors.border),
          ),
          Expanded(
            child: MushafReader(
              controller: page2Controller,
              onAyahTap: onAyahTapped,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudyModeWidget extends StatelessWidget {
  const _StudyModeWidget({
    this.onAyahTap,
  });

  final void Function(AyahInfo)? onAyahTap;

  @override
  Widget build(BuildContext context) {
    // final resizeController = useFResizableController();
    const double studyPanelWidth = 350;
    const double spacer = 20;
    return LayoutBuilder(
      builder: (context, constraints) {
        final quranWidth = constraints.maxWidth - studyPanelWidth - spacer;
        return FResizable(
          // control: .managed(controller: resizeController),
          axis: .horizontal,
          hitRegionExtent: 20,
          children: [
            // Study panel (left side)
            .region(
              initialExtent: studyPanelWidth,
              minExtent: 250,
              builder: (context, value, child) => const Align(
                child: Padding(
                  padding: .fromSTEB(0, 0, 8, 0),
                  child: _StudyPanelWrapper(),
                ),
              ),
            ),
            // Mushaf reader (right side, main area)
            .region(
              initialExtent: quranWidth,
              builder: (context, value, child) => Align(
                child: Padding(
                  padding: const .fromSTEB(8, 0, 0, 0),
                  child: StaticCard(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: MushafReader(
                          onAyahTap: onAyahTap,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Wrapper that watches ayah state via Riverpod, isolating rebuilds from FResizable.
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
