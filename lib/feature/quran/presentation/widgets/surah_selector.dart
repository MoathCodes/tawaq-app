import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/widgets/f_skeletonizer.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hasanat/theme/theme.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mushaf_reader/mushaf_reader.dart';

/// A dropdown selector for choosing a Surah in the Quran reader.
class SurahSelector extends HookConsumerWidget {
  /// Creates a [SurahSelector] instance.
  const SurahSelector({required this.controller, super.key});

  /// The mushaf reader controller.
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
        enabled: allSurahs.connectionState == ConnectionState.waiting,
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
