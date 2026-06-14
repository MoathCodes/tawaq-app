import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/core/layout/viewport_dialog_constraints.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/quran/presentation/hooks/quran_ayah_selection.dart';
import 'package:tawaq/feature/quran/presentation/widgets/quran_semantics.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/theme.dart';

/// Ayah search selector for searching through the Quran.
class AyahSearchSelector extends ConsumerWidget {
  /// Creates an [AyahSearchSelector] instance.
  const AyahSearchSelector({
    required this.controller,
    this.searchPopoverController,
    super.key,
  });

  /// The mushaf reader controller.
  final MushafReaderController controller;

  /// Optional popover controller used to open search via keyboard shortcut.
  final FPopoverController? searchPopoverController;

  String _surahName(int surahNumber, AppLocalizations l10n) {
    final surah = controller.getSurahSync(surahNumber);
    return surah?.nameArabic ??
        surah?.nameEnglish ??
        l10n.surahNameDefault(surahNumber);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final colors = theme.colors;
    final typography = theme.typography;
    final l10n = context.l10n;

    // Watch selected ayah from unified state for lifted control
    final selectedAyah = ref.watch(
      quranScreenSettingsProvider.select((v) => v.value?.selectedAyah),
    );

    final popoverController = searchPopoverController;

    return QuranSemantics.labeledControl(
      name: l10n.searchQuran,
      value: selectedAyah != null
          ? l10n.surahAyahInfo(
              _surahName(selectedAyah.surahNumber, l10n),
              selectedAyah.numberInSurah,
            )
          : null,
      excludeChild: true,
      child: FSelect<Ayah>.searchBuilder(
        popoverControl: popoverController != null
            ? FPopoverControl.managed(controller: popoverController)
            : const FPopoverControl.managed(),
        hint: l10n.searchQuran,
        label: Text(l10n.searchQuran),
        prefixBuilder: (context, style, states) => Padding(
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: QuranSemantics.decorative(
            Icon(
              FLucideIcons.search,
              color: colors.mutedForeground,
              size: 14,
            ),
          ),
        ),
      suffixBuilder: null,
      contentConstraints: selectPopoverPortalConstraints(context),
      style: selectStyle(
        colors: colors,
        style: theme.style,
        typography: typography,
      ),
      searchFieldProperties: FSelectSearchFieldProperties(
        hint: l10n.searchQuran,
        prefixBuilder: (context, style, _) => Padding(
          padding: const EdgeInsets.only(left: 8),
          child: QuranSemantics.decorative(
            Icon(
              FLucideIcons.search,
              size: 16,
              color: colors.mutedForeground,
            ),
          ),
        ),
      ),
      format: (v) => l10n.surahAyahInfo(
        _surahName(v.surahNumber, l10n),
        v.numberInSurah,
      ),
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
              FLucideIcons.searchX,
              size: 32,
              color: colors.mutedForeground,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noResultsFound,
              style: typography.sm.copyWith(color: colors.mutedForeground),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.tryDifferentSearchTerm,
              style: typography.xs.copyWith(color: colors.mutedForeground),
            ),
          ],
        ),
      ),
      contentLoadingBuilder: (context, style) => const Padding(
        padding: EdgeInsets.all(24),
        child: FCircularProgress.loader(),
      ),
      // Lifted control syncs with selectedAyah from unified state
      control: FSelectControl.lifted(
        value: selectedAyah,
        onChange: (v) async {
          if (v == null) {
            setQuranSelectedAyah(ref, controller, null);
            return;
          }
          await jumpToQuranAyah(ref, controller, v);
        },
      ),
      contentBuilder: (context, style, ayahs) => ayahs.map((ayah) {
        final surahName = _surahName(ayah.surahNumber, l10n);

        // Truncate text for preview
        final preview = ayah.textPlain != null
            ? (ayah.textPlain!.length > 60
                  ? l10n.quranAyahSearchPreviewTruncated(
                      ayah.textPlain!.substring(0, 60),
                    )
                  : ayah.textPlain!)
            : '';

        return FSelectItem<Ayah>(
          value: ayah,
          title: Row(
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    l10n.surahAyahInfo(surahName, ayah.numberInSurah),
                    style: typography.xs.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.pageJuzInfo(ayah.page, ayah.juz),
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
