import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/hooks/use_mushaf_controller.dart';
import 'package:hasanat/core/widgets/custom_cards.dart';
import 'package:hasanat/core/widgets/f_skeletonizer.dart';
import 'package:hasanat/feature/quran/domain/models/font_sizes.dart';
import 'package:hasanat/feature/quran/domain/models/quran_layouts.dart';
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
      initialPage: ref.read(
        stateSettingsProvider.select(
          (v) => v.value?.quranState.pageInfo.pageNumber ?? 1,
        ),
      ),
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
                  onAyahTapped: (info) async {
                    final ayah = await controller.getAyah(info.ayahId);
                    ref.read(stateSettingsProvider.notifier).selectAyah(ayah);
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderWidget extends HookConsumerWidget {
  const _HeaderWidget({required this.mushafController});
  final MushafReaderController mushafController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(
      stateSettingsProvider.select(
        (v) => v.value?.quranState.layout ?? QuranReadingLayout.studyMode,
      ),
    );
    final fontSize = ref.watch(
      stateSettingsProvider.select(
        (v) => v.value?.quranState.fontSize ?? FontSizes.medium,
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
          _SurahSelector(
            controller: mushafController,
          ),
          const SizedBox(width: AppSpacing.sm),
          // Juz selector - extracted for granular rebuilds
          _JuzSelector(controller: mushafController),
          const SizedBox(width: AppSpacing.md),
          // Ayah search selector
          Expanded(child: _AyahSearchSelector(controller: mushafController)),
          const Spacer(),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 140,
            child: FTabs(
              control: FTabControl.lifted(
                index: fontSize.index,
                onChange: (int v) => ref
                    .read(stateSettingsProvider.notifier)
                    .setFontSize(FontSizes.values[v]),
              ),
              style: (s) => s.copyWith(
                padding: const .all(2),
                indicatorSize: FTabBarIndicatorSize.tab,
              ),
              children: List.generate(
                3,
                (index) => FTabEntry(
                  label: Icon(
                    index == 0 || index == 2 ? FIcons.aLargeSmall : FIcons.type,
                    size: 18 - (index * 2),
                  ),
                  child: const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SurahSelector extends HookConsumerWidget {
  const _SurahSelector({required this.controller});
  final MushafReaderController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allSurahs = useFuture(
      useMemoized(controller.getAllSurahs),
    );

    // Use Riverpod state for current page info
    final currentSurahNumber = ref.watch(
      stateSettingsProvider.select(
        (v) => v.value?.quranState.pageInfo.primarySurahNumber,
      ),
    );
    final selectedSurah = allSurahs.hasData && currentSurahNumber != null
        ? allSurahs.data?.firstWhere(
            (e) => e.number == currentSurahNumber,
            orElse: () => allSurahs.data!.first,
          )
        : null;

    return SizedBox(
      width: 150,
      child: FSkeletonizer(
        enabled: allSurahs.connectionState == .waiting,
        child: FSelect<Surah>.searchBuilder(
          style: selectStyle(
            colors: context.theme.colors,
            style: context.theme.style,
            typography: context.theme.typography,
          ).call,
          control: FSelectControl.lifted(
            value: selectedSurah,
            onChange: (v) async {
              if (v != null) {
                await controller.jumpToSurah(v.number);
              }
            },
          ),
          format: (v) =>
              (Localizations.localeOf(context).languageCode == 'ar'
                  ? v.nameArabic
                  : v.nameEnglish) ??
              '',
          filter: (q) {
            if (q.isEmpty) return allSurahs.data ?? [];
            final query = q.toLowerCase().trim();
            final queryNum = int.tryParse(query);

            // Efficient multi-field search with relevance scoring
            final results = <(Surah, int)>[];
            for (final surah in allSurahs.data ?? <Surah>[]) {
              var score = 0;

              // 1. Exact number match (highest priority)
              if (queryNum != null && surah.number == queryNum) {
                score = 100;
              }
              // 2. Number starts with query
              else if (surah.number.toString().startsWith(query)) {
                score = 80;
              }
              // 3. English name starts with query (e.g., "Al-Fatihah")
              else if (surah.nameEnglish?.toLowerCase().startsWith(query) ??
                  false) {
                score = 70;
              }
              // 4. Arabic name starts with query
              else if (surah.nameArabicSimplified?.startsWith(q) ?? false) {
                score = 70;
              }
              // 5. English translation starts with query (e.g., "The Opening")
              else if (surah.englishNameTranslation?.toLowerCase().startsWith(
                    query,
                  ) ??
                  false) {
                score = 65;
              }
              // 6. English name contains query
              else if (surah.nameEnglish?.toLowerCase().contains(query) ??
                  false) {
                score = 50;
              }
              // 7. English translation contains query
              else if (surah.englishNameTranslation?.toLowerCase().contains(
                    query,
                  ) ??
                  false) {
                score = 45;
              }
              // 8. Arabic name contains query
              else if (surah.nameArabicSimplified?.contains(q) ?? false) {
                score = 50;
              }

              if (score > 0) results.add((surah, score));
            }

            // Sort by score (descending), then by surah number
            results.sort((a, b) {
              final scoreCompare = b.$2.compareTo(a.$2);
              if (scoreCompare != 0) return scoreCompare;
              return a.$1.number.compareTo(b.$1.number);
            });

            return results.map((e) => e.$1);
          },
          contentBuilder: (_, _, vals) => vals
              .map(
                (v) => FSelectItem<Surah>(
                  value: v,
                  title: Text(
                    v.nameArabic ?? '',
                  ),
                  subtitle: Text(
                    v.nameEnglish ?? '',
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

/// Juz selector that only rebuilds when juz number changes.
class _JuzSelector extends HookConsumerWidget {
  const _JuzSelector({required this.controller});
  final MushafReaderController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allJuzs = useFuture(
      useMemoized(controller.getJuzs),
    );

    // Use Riverpod state for current page info
    final currentJuzNumber = ref.watch(
      stateSettingsProvider.select(
        (v) => v.value?.quranState.pageInfo.juzNumber,
      ),
    );
    final selectedJuz = allJuzs.hasData && currentJuzNumber != null
        ? allJuzs.data?.firstWhere(
            (e) => e.number == currentJuzNumber,
            orElse: () => allJuzs.data!.first,
          )
        : null;

    return SizedBox(
      width: 200,
      child: FSkeletonizer(
        enabled: allJuzs.connectionState == .waiting,
        child: FSelect<Juz>.searchBuilder(
          style: selectStyle(
            colors: context.theme.colors,
            style: context.theme.style,
            typography: context.theme.typography,
            useQuranFont: true,
          ).call,
          control: FSelectControl.lifted(
            value: selectedJuz,
            onChange: (v) async {
              if (v != null) {
                await controller.jumpToJuz(v.number);
              }
            },
          ),
          format: (v) => v.glyph,
          filter: (q) {
            return allJuzs.hasData
                ? allJuzs.data!.where((e) => e.number.toString().contains(q))
                : [];
          },
          contentBuilder: (_, _, vals) => vals
              .map(
                (v) => FSelectItem<Juz>(
                  value: v,
                  title: Text(
                    v.glyph,
                    style: const TextStyle(
                      fontFamily: 'QCF4_BSML',
                      package: 'mushaf_reader',
                      fontSize: 36,
                    ),
                  ),
                  subtitle: Text('Juz ${v.number}'),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

/// Ayah search selector for searching through the Quran.
class _AyahSearchSelector extends ConsumerWidget {
  const _AyahSearchSelector({required this.controller});
  final MushafReaderController controller;

  String _getSurahName(int surahNumber) {
    final surah = controller.getSurahSync(surahNumber);
    return surah?.nameArabic ?? surah?.nameEnglish ?? 'Surah $surahNumber';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    // Watch selected ayah from unified state for lifted control
    final selectedAyah = ref.watch(
      stateSettingsProvider.select((v) => v.value?.quranState.selectedAyah),
    );

    return SizedBox(
      width: 280,
      child: FSelect<Ayah>.searchBuilder(
        prefixBuilder: (context, style, states) => Padding(
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: Icon(
            FIcons.search,
            color: colors.mutedForeground,
            size: 14,
          ),
        ),
        suffixBuilder: null,
        style: selectStyle(
          colors: colors,
          style: context.theme.style,
          typography: typography,
        ).call,
        searchFieldProperties: FSelectSearchFieldProperties(
          hint: 'Search Quran...',
          prefixBuilder: (context, style, _) => Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Icon(
              FIcons.search,
              size: 16,
              color: colors.mutedForeground,
            ),
          ),
        ),
        format: (v) => '${_getSurahName(v.surahNumber)} : ${v.numberInSurah}',
        filter: (query) async {
          if (query.isEmpty || query.length < 2) return [];
          return controller.searchAyahs(query, maxResults: 20);
        },
        contentEmptyBuilder: (context, style) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                FIcons.searchX,
                size: 32,
                color: colors.mutedForeground,
              ),
              const SizedBox(height: 8),
              Text(
                'No results found',
                style: typography.sm.copyWith(color: colors.mutedForeground),
              ),
              const SizedBox(height: 4),
              Text(
                'Try a different search term',
                style: typography.xs.copyWith(color: colors.mutedForeground),
              ),
            ],
          ),
        ),
        contentLoadingBuilder: (context, style) => const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        // Lifted control syncs with selectedAyah from unified state
        control: FSelectControl.lifted(
          value: selectedAyah,
          onChange: (v) async {
            ref.read(stateSettingsProvider.notifier).selectAyah(v);
            if (v != null) {
              await controller.jumpToAyah(v.ayahId, select: true);
            }
          },
        ),
        contentBuilder: (context, style, ayahs) => ayahs.map((ayah) {
          // Get Surah name
          final surahName = _getSurahName(ayah.surahNumber);

          // Truncate text for preview
          final preview = ayah.textPlain != null
              ? (ayah.textPlain!.length > 60
                    ? '${ayah.textPlain!.substring(0, 60)}...'
                    : ayah.textPlain!)
              : '';

          return FSelectItem<Ayah>(
            value: ayah,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$surahName : ${ayah.numberInSurah}',
                    style: typography.xs.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Page ${ayah.page} • Juz ${ayah.juz}',
                  style: typography.xs.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
              ],
            ),
            subtitle: preview.isNotEmpty
                ? Text(
                    preview,
                    style: typography.sm.copyWith(
                      color: colors.foreground,
                      height: 1.4,
                    ),
                    textDirection: TextDirection.rtl,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
          );
        }).toList(),
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
  final void Function(Ayah) onAyahTapped;

  MushafStyle _buildStyle(FThemeData theme, FontSizes fontSize) => MushafStyle(
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
    final fontSize = ref.watch(
      stateSettingsProvider.select(
        (v) => v.value?.quranState.fontSize ?? FontSizes.medium,
      ),
    );
    final style = _buildStyle(theme, fontSize);
    void savePageInfo(MushafPageInfo info) => unawaited(
      ref.read(stateSettingsProvider.notifier).setLastQuranPageInfo(info),
    );

    final child = switch (viewMode) {
      .singlePage => HoverCard(
        child: MushafReader(
          controller: controller,
          onAyahTap: onAyahTapped,
          style: style,
          onPageChanged: savePageInfo,
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
          onPageChanged: (info) => savePageInfo(info.$1),
        ),
      ),
      .studyMode => _StudyModeLayout(
        style: style,
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

class _StudyModeLayout extends StatelessWidget {
  const _StudyModeLayout({
    required this.style,
    required this.controller,
    required this.onPageChanged,
    required this.onAyahTapped,
  });
  final MushafStyle style;
  final MushafReaderController controller;
  final void Function(MushafPageInfo) onPageChanged;
  final void Function(Ayah) onAyahTapped;

  @override
  Widget build(BuildContext context) {
    const panelWidth = 350.0;
    const spacer = 20.0;
    final panel = StudyPanel(controller: controller);
    final content = HoverCard(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: MushafReader(
            controller: controller,
            style: style,
            onPageChanged: onPageChanged,
            onAyahTap: onAyahTapped,
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
                        child: isArabic ? content : panel,
                      ),
                    ),
                  ),
                  .region(
                    initialExtent: isArabic ? panelWidth : quranWidth,
                    minExtent: isArabic ? 250 : null,
                    builder: (_, _, _) => Align(
                      child: Padding(
                        padding: const .fromSTEB(8, 0, 0, 0),
                        child: isArabic ? panel : content,
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
