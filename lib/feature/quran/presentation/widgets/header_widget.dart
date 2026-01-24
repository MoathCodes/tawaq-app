import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/feature/quran/domain/models/font_sizes.dart';
import 'package:hasanat/feature/quran/domain/models/quran_layouts.dart';
import 'package:hasanat/feature/quran/presentation/widgets/ayah_search_selector.dart';
import 'package:hasanat/feature/quran/presentation/widgets/juz_selector.dart';
import 'package:hasanat/feature/quran/presentation/widgets/surah_selector.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hasanat/theme/theme.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mushaf_reader/mushaf_reader.dart';

/// Header widget for the Quran screen containing navigation controls.
class QuranHeaderWidget extends HookConsumerWidget {
  /// Creates a [QuranHeaderWidget] instance.
  const QuranHeaderWidget({required this.mushafController, super.key});

  /// The mushaf reader controller.
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          // View mode tabs
          SizedBox(
            width: 140,
            child: FTabs(
              control: FTabControl.lifted(
                index: layout.index,
                onChange: (v) => ref
                    .read(stateSettingsProvider.notifier)
                    .setLastLayout(QuranReadingLayout.values[v]),
              ),
              style: (s) => s.copyWith(
                padding: const EdgeInsets.all(2),
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
          const SizedBox(width: AppSpacing.xl),
          SurahSelector(
            controller: mushafController,
          ),
          const SizedBox(width: AppSpacing.md),
          // Juz selector - extracted for granular rebuilds
          JuzSelector(controller: mushafController),
          const SizedBox(width: AppSpacing.lg),
          // Ayah search selector
          Expanded(child: AyahSearchSelector(controller: mushafController)),
          const SizedBox(width: AppSpacing.xl),
          // Visual separator
          Container(
            height: 24,
            width: 1,
            color: FTheme.of(context).colors.border,
          ),
          const SizedBox(width: AppSpacing.xl),
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
                padding: const EdgeInsets.all(2),
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
