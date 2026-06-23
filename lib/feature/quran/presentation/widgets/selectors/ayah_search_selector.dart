import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/core/layout/viewport_dialog_constraints.dart';
import 'package:tawaq/core/widgets/empty_state_panel.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/quran/domain/services/ayah_reference_logic.dart';
import 'package:tawaq/feature/quran/presentation/hooks/quran_ayah_selection.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/quran_semantics.dart';
import 'package:tawaq/feature/quran/presentation/widgets/surah_name_text.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/theme.dart';

/// Ayah search selector for searching through the Quran.
class AyahSearchSelector extends ConsumerWidget {
  /// Creates an [AyahSearchSelector] instance.
  const AyahSearchSelector({
    this.searchPopoverController,
    this.showLabel = true,
    super.key,
  });

  /// Optional popover controller used to open search via keyboard shortcut.
  final FPopoverController? searchPopoverController;

  /// Whether the field label is shown above the select.
  final bool showLabel;

  String _surahName(
    MushafReaderController controller,
    int surahNumber,
    AppLocalizations l10n,
    bool preferArabic,
  ) {
    return AyahReferenceLogic.surahName(
      controller.getSurahSync(surahNumber),
      surahNumber,
      preferArabic: preferArabic,
      fallbackName: l10n.surahNameDefault(surahNumber),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(quranMushafControllerProvider);
    final theme = context.theme;
    final colors = theme.colors;
    final typography = theme.typography;
    final l10n = context.l10n;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    // Watch selected ayah from unified state for lifted control
    final selectedAyah = ref.watch(
      quranScreenSettingsProvider.select((v) => v.value?.selectedAyah),
    );

    final popoverController = searchPopoverController;

    return QuranSemantics.labeledControl(
      name: l10n.searchQuran,
      value: selectedAyah != null
          ? l10n.surahAyahInfo(
              _surahName(controller, selectedAyah.surahNumber, l10n, isArabic),
              selectedAyah.numberInSurah,
            )
          : null,
      excludeChild: true,
      child: FSelect<Ayah>.searchBuilder(
        popoverControl: popoverController != null
            ? FPopoverControl.managed(controller: popoverController)
            : const FPopoverControl.managed(),
        hint: l10n.searchQuran,
        label: showLabel ? Text(l10n.searchQuran) : const SizedBox.shrink(),
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
          useQuranFont: true,
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
          _surahName(controller, v.surahNumber, l10n, isArabic),
          v.numberInSurah,
        ),
        filter: (query) async {
          if (query.isEmpty || query.length < 2) return [];
          return controller.searchAyahs(query, maxResults: 20);
        },
        contentEmptyBuilder: (context, style) => EmptyStatePanel(
          icon: FLucideIcons.searchX,
          title: l10n.noResultsFound,
          hint: l10n.tryDifferentSearchTerm,
          iconSize: 32,
          padding: const EdgeInsets.all(AppSpacing.lg),
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
              setQuranSelectedAyah(ref, null);
              return;
            }
            await jumpToQuranAyah(ref, v);
          },
        ),
        contentBuilder: (context, style, ayahs) => ayahs.map((ayah) {
          final surahName = _surahName(controller, ayah.surahNumber, l10n, isArabic);

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
                    child: SurahNameWithSuffix(
                      surahName: surahName,
                      suffix: ' • ${l10n.ayahLabel} ${ayah.numberInSurah}',
                      style: typography.body.xs.copyWith(
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
                  style: typography.body.xs.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
              ],
            ),
            subtitle: preview.isNotEmpty
                ? Text(
                    preview,
                    style: typography.body.sm.copyWith(
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
