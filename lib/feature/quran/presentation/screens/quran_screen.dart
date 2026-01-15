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
    final controller = useMushafController(
      initialPage: ref.read(stateSettingsProvider).value?.lastQuranPage ?? 1,
    );

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        _HeaderWidget(mushafController: controller),
        Expanded(
          child: Padding(
            padding: const .only(bottom: AppSpacing.sm),
            child: CallbackShortcuts(
              bindings: <ShortcutActivator, VoidCallback>{
                const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
                    unawaited(
                      controller.animateToPage(controller.currentPage + 1),
                    ),
                const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
                    unawaited(
                      controller.animateToPage(controller.currentPage - 1),
                    ),
                const SingleActivator(LogicalKeyboardKey.space): () =>
                    unawaited(
                      controller.animateToPage(controller.currentPage + 1),
                    ),
              },
              child: Focus(
                autofocus: true,
                child: _MainContentWidget(
                  controller: controller,
                  onAyahTapped: (info) => ref
                      .read(audioPlayerProvider.notifier)
                      .selectAyahById(
                        info.ayahId,
                        ayahNumber: info.verseNumber,
                      ),
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
      builder: (context, ref, _) {
        final isAudioActive = ref.read(audioPlayerProvider).isActive;
        final layout = ref.watch(
          stateSettingsProvider.select(
            (v) => v.value?.lastLayout ?? QuranReadingLayout.studyMode,
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
                    onChange: (v) => ref
                        .read(stateSettingsProvider.notifier)
                        .setLastLayout(QuranReadingLayout.values[v]),
                  ),
                  style: (s) => s.copyWith(
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
              _SurahSelector(),
              const SizedBox(width: AppSpacing.sm),
              // Juz selector
              SizedBox(
                width: 200,
                height: 50,
                child: FSelect<int>.searchBuilder(
                  control: .managed(
                    initial: mushafController.currentPageInfo?.juzNumber,
                    onChange: (v) async {
                      if (v != null) await mushafController.jumpToJuz(v);
                    },
                  ),
                  format: (v) => v.toString(),
                  filter: (q) {
                    final sync = mushafController.getJuzsSync();
                    return (sync.isNotEmpty
                            ? Future.value(sync)
                            : mushafController.getJuzs())
                        .then(
                          (v) => v
                              .where((e) => e.number.toString().contains(q))
                              .map((e) => e.number),
                        );
                  },
                  contentBuilder: (_, _, vals) => vals
                      .map(
                        (v) =>
                            FSelectItem<int>(value: v, title: Text('Juz $v')),
                      )
                      .toList(),
                ),
              ),
              const Spacer(),
              // Action buttons
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
              ...[FIcons.search, FIcons.bookmark, FIcons.type].map(
                (icon) => FButton.icon(
                  onPress: () {},
                  style: FButtonStyle.ghost(),
                  child: Icon(icon, size: 18, color: colors.mutedForeground),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SurahSelector extends StatelessWidget {
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
          Icon(FIcons.chevronDown, size: 14, color: colors.mutedForeground),
        ],
      ),
    );
  }
}

class _MainContentWidget extends ConsumerWidget {
  const _MainContentWidget({
    required this.controller,
    required this.onAyahTapped,
  });
  final MushafReaderController controller;
  final void Function(AyahInfo) onAyahTapped;

  MushafStyle _buildStyle(FThemeData theme) => MushafStyle(
    ayahStyleModifier: (s) => s.copyWith(color: theme.colors.foreground),
    juzStyleModifier: (s) => s.copyWith(color: theme.colors.mutedForeground),
    pageNumberStyleModifier: (s) =>
        s.copyWith(color: theme.colors.mutedForeground),
    surahNameStyleModifier: (s) =>
        s.copyWith(color: theme.colors.mutedForeground),
    basmalahStyleModifier: (s) => s.copyWith(color: theme.colors.foreground),
    activeAyahStyleModifier: (s) => s.copyWith(
      backgroundColor: theme.colors.primary,
      color: theme.colors.primaryForeground,
    ),
    headerSurahNameStyleModifier: (s) =>
        s.copyWith(fontSize: 22, color: Colors.brown.shade800),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FTheme.of(context);
    final viewMode = ref.watch(
      stateSettingsProvider.select(
        (v) => v.value?.lastLayout ?? QuranReadingLayout.studyMode,
      ),
    );
    final style = _buildStyle(theme);
    void savePage(int p) =>
        unawaited(ref.read(stateSettingsProvider.notifier).setLastQuranPage(p));

    final child = switch (viewMode) {
      .singlePage => HoverCard(
        child: MushafReader(
          controller: controller,
          onAyahTap: onAyahTapped,
          style: style,
          onPageNumberChanged: savePage,
        ),
      ),
      .doublePage => HoverCard(
        child: MushafTwoPageReader(
          key: ValueKey(
            'two-page-${theme.colors.secondaryForeground.hashCode}',
          ),
          controller: controller,
          style: style,
          onAyahTap: onAyahTapped,
          onPageNumberChanged: ((int, int) v) => savePage(v.$1),
        ),
      ),
      .studyMode => _StudyModeLayout(
        style: style,
        controller: controller,
        onPageChanged: savePage,
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

class _StudyModeLayout extends StatelessWidget {
  const _StudyModeLayout({
    required this.style,
    required this.controller,
    required this.onPageChanged,
  });
  final MushafStyle style;
  final MushafReaderController controller;
  final void Function(int) onPageChanged;

  @override
  Widget build(BuildContext context) {
    const panelWidth = 350.0;
    const spacer = 20.0;
    final content = HoverCard(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: MushafReader(
            controller: controller,
            style: style,
            onPageNumberChanged: onPageChanged,
          ),
        ),
      ),
    );

    return LayoutBuilder(
      builder: (_, constraints) {
        final quranWidth = constraints.maxWidth - panelWidth - spacer;
        return Consumer(
          builder: (_, ref, _) {
            final isArabic =
                ref.watch(localeProvider).value?.languageCode == 'ar';
            return Directionality(
              textDirection: .ltr,
              child: FResizable(
                axis: .horizontal,
                children: [
                  .region(
                    initialExtent: isArabic ? quranWidth : panelWidth,
                    minExtent: isArabic ? null : 250,
                    builder: (_, _, _) => Align(
                      child: Padding(
                        padding: const .fromSTEB(0, 0, 8, 0),
                        child: isArabic ? content : const _StudyPanelWrapper(),
                      ),
                    ),
                  ),
                  .region(
                    initialExtent: isArabic ? panelWidth : quranWidth,
                    minExtent: isArabic ? 250 : null,
                    builder: (_, _, _) => Align(
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

class _StudyPanelWrapper extends ConsumerWidget {
  const _StudyPanelWrapper();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(audioPlayerProvider);
    return StudyPanel(
      selectedAyahId: s.selectedAyahId,
      surahName: s.surahName,
      ayahNumber: s.currentAyahNumber,
    );
  }
}
