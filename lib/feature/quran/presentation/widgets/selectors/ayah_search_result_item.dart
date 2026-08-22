import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/feature/quran/domain/services/ayah_reference_logic.dart';
import 'package:tawaq/feature/quran/presentation/widgets/surah_name_text.dart';
import 'package:tawaq/gen/fonts.gen.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/theme.dart';

/// Minimum query length before ayah search runs.
const kAyahSearchMinQueryLength = 2;

/// Filters ayahs for the Quran header search field.
Future<List<Ayah>> filterAyahsForSearch(
  MushafReaderController controller,
  String query, {
  int maxResults = 20,
}) async {
  if (query.length < kAyahSearchMinQueryLength) return [];
  return controller.searchAyahs(query, maxResults: maxResults);
}

/// Uthmani snippet for an ayah search result (falls back to Imlaei plain text).
String ayahSearchPreviewText(Ayah ayah) {
  final uthmani = ayah.uthmaniText?.trim();
  if (uthmani != null && uthmani.isNotEmpty) return uthmani;
  return ayah.textPlain?.trim() ?? '';
}

/// Builds a rich [FAutocompleteItem] row for Quran ayah search results.
FAutocompleteItem<Ayah> buildAyahSearchResultItem({
  required BuildContext context,
  required Ayah ayah,
  required MushafReaderController controller,
  required bool isArabic,
  required AppLocalizations l10n,
}) {
  final theme = context.theme;
  final colors = theme.colors;
  final typography = theme.typography;

  final surahName = AyahReferenceLogic.surahName(
    controller.getSurahSync(ayah.surahNumber),
    ayah.surahNumber,
    preferArabic: isArabic,
    fallbackName: '',
  );

  final preview = ayahSearchPreviewText(ayah);

  return FAutocompleteItem.item(
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
              fontFamily: FontFamily.uthmanicHafs,
              height: 1.5,
            ),
            textDirection: TextDirection.rtl,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          )
        : null,
  );
}
