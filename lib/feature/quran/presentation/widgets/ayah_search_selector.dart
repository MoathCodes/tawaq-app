import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hasanat/l10n/app_localizations.dart';
import 'package:hasanat/theme/theme.dart';
import 'package:mushaf_reader/mushaf_reader.dart';

/// Ayah search selector for searching through the Quran.
class AyahSearchSelector extends ConsumerWidget {
  /// Creates an [AyahSearchSelector] instance.
  const AyahSearchSelector({required this.controller, super.key});

  /// The mushaf reader controller.
  final MushafReaderController controller;

  String _getSurahName(BuildContext context, int surahNumber) {
    final surah = controller.getSurahSync(surahNumber);
    return surah?.nameArabic ??
        surah?.nameEnglish ??
        AppLocalizations.of(context)!.surahNameDefault(surahNumber);
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
        hint: AppLocalizations.of(context)!.searchQuran,
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
          hint: AppLocalizations.of(context)!.searchQuran,
          prefixBuilder: (context, style, _) => Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Icon(
              FIcons.search,
              size: 16,
              color: colors.mutedForeground,
            ),
          ),
        ),
        format: (v) =>
            '${_getSurahName(context, v.surahNumber)} : ${v.numberInSurah}',
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
                AppLocalizations.of(context)!.noResultsFound,
                style: typography.sm.copyWith(color: colors.mutedForeground),
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context)!.tryDifferentSearchTerm,
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
          final surahName = _getSurahName(context, ayah.surahNumber);

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
                  AppLocalizations.of(
                    context,
                  )!.pageJuzInfo(ayah.page, ayah.juz),
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
