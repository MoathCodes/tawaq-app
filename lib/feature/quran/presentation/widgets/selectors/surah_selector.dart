import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/core/layout/viewport_dialog_constraints.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/f_skeletonizer.dart';
import 'package:tawaq/feature/quran/presentation/widgets/quran_semantics.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/theme/theme.dart';

/// A dropdown selector for choosing a Surah in the Quran reader.
class SurahSelector extends HookConsumerWidget {
  /// Creates a [SurahSelector] instance.
  const SurahSelector({required this.controller, super.key});

  /// The mushaf reader controller.
  final MushafReaderController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final l10n = context.l10n;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final allSurahs = useFuture(
      useMemoized(controller.getAllSurahs),
    );

    // Use Riverpod state for current page info
    final currentSurahNumber = ref.watch(
      quranScreenSettingsProvider.select(
        (v) => v.value?.pageInfo.primarySurahNumber,
      ),
    );
    final selectedSurah = allSurahs.hasData && currentSurahNumber != null
        ? allSurahs.data?.firstWhere(
            (e) => e.number == currentSurahNumber,
            orElse: () => allSurahs.data!.first,
          )
        : null;

    final selectorReady =
        allSurahs.connectionState == ConnectionState.done && allSurahs.hasData;
    final surahFieldName = QuranSemantics.surahFieldName(l10n);
    final displayedValue = selectedSurah != null
        ? ((isArabic ? selectedSurah.nameArabic : selectedSurah.nameEnglish) ??
              l10n.surahNameDefault(selectedSurah.number))
        : null;

    return FSkeletonizer(
      enabled: allSurahs.connectionState == ConnectionState.waiting,
      child: QuranSemantics.labeledControl(
        name: surahFieldName,
        value: displayedValue,
        enabled: selectorReady,
        excludeChild: true,
        child: FSelect<Surah>.searchBuilder(
          enabled: selectorReady,
          label: Text(surahFieldName),
          contentConstraints: selectPopoverPortalConstraints(context),
          style: selectStyle(
            colors: theme.colors,
            style: theme.style,
            typography: theme.typography,
          ),
          control: FSelectControl.lifted(
          value: selectedSurah,
          onChange: (v) async {
            if (v != null) {
              await controller.jumpToSurah(v.number);
            }
          },
        ),
        format: (v) => (isArabic ? v.nameArabic : v.nameEnglish) ?? '',
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
                  isArabic
                      ? (v.nameArabic ?? l10n.surahNameDefault(v.number))
                      : (v.nameEnglish ??
                            v.nameArabic ??
                            l10n.surahNameDefault(v.number)),
                ),
                subtitle: Text(
                  isArabic
                      ? (v.nameEnglish ??
                            v.englishNameTranslation ??
                            '')
                      : (v.englishNameTranslation ??
                            v.nameArabic ??
                            ''),
                ),
              ),
            )
            .toList(),
        ),
      ),
    );
  }
}
