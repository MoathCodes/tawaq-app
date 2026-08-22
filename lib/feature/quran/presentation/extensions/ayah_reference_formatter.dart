import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/feature/quran/domain/services/ayah_reference_logic.dart';
import 'package:tawaq/l10n/app_localizations.dart';

/// Localized ayah reference for UI labels (e.g. "Al-Baqara • Ayah 255").
String localizedAyahReference({
  required Ayah ayah,
  required MushafReaderController controller,
  required AppLocalizations l10n,
  required bool isArabic,
}) {
  final surah = controller.getSurahSync(ayah.surahNumber);
  final surahName = AyahReferenceLogic.surahName(
    surah,
    ayah.surahNumber,
    preferArabic: isArabic,
    fallbackName: '',
  );
  return surahName.isEmpty
      ? localizedAyahNumber(l10n, ayah.numberInSurah)
      : l10n.surahAyahInfo(surahName, ayah.numberInSurah);
}

/// Verse number only, e.g. "Ayah 7" / "الآية 7".
String localizedAyahNumber(AppLocalizations l10n, int numberInSurah) {
  return '${l10n.ayahLabel} $numberInSurah';
}

/// Whether every ayah on the page belongs to the same surah.
bool isSingleSurahPage(Iterable<Ayah> ayahs) {
  final iterator = ayahs.iterator;
  if (!iterator.moveNext()) return true;
  final surahNumber = iterator.current.surahNumber;
  while (iterator.moveNext()) {
    if (iterator.current.surahNumber != surahNumber) return false;
  }
  return true;
}

/// Indices on a page that should show a slider mark label.
///
/// Only in-page surah boundaries between the first and last ayah. Endpoints
/// are omitted because the slider description already shows the full range and
/// edge labels clip outside the dialog in RTL.
Set<int> sliderMarkLabelIndices(List<Ayah> orderedAyahs) {
  final count = orderedAyahs.length;
  if (count <= 2) return {};
  final indices = <int>{};
  for (var i = 1; i < count - 1; i++) {
    if (orderedAyahs[i].surahNumber != orderedAyahs[i - 1].surahNumber) {
      indices.add(i);
    }
  }
  return indices;
}

/// Whether a compact slider label should include the surah name.
bool showSurahNameInCompactLabel({
  required List<Ayah> orderedAyahs,
  required int index,
  required bool singleSurahPage,
}) {
  if (singleSurahPage) return false;
  final ayah = orderedAyahs[index];
  final count = orderedAyahs.length;

  if (index > 0 && ayah.surahNumber != orderedAyahs[index - 1].surahNumber) {
    return true;
  }
  if (index == count - 1 &&
      ayah.surahNumber != orderedAyahs.first.surahNumber) {
    return true;
  }
  if (index == 0 && ayah.numberInSurah == 1) {
    return true;
  }
  return false;
}

/// Short ayah reference for slider marks and range descriptions.
String localizedCompactAyahReference({
  required Ayah ayah,
  required int indexOnPage,
  required List<Ayah> orderedAyahs,
  required MushafReaderController controller,
  required AppLocalizations l10n,
  required bool isArabic,
  required bool singleSurahPage,
}) {
  if (showSurahNameInCompactLabel(
    orderedAyahs: orderedAyahs,
    index: indexOnPage,
    singleSurahPage: singleSurahPage,
  )) {
    return localizedAyahReference(
      ayah: ayah,
      controller: controller,
      l10n: l10n,
      isArabic: isArabic,
    );
  }
  return localizedAyahNumber(l10n, ayah.numberInSurah);
}

/// Filesystem-safe ayah reference for export filenames (English surah name).
String filenameAyahReference({
  required Ayah ayah,
  required MushafReaderController controller,
}) {
  final surah = controller.getSurahSync(ayah.surahNumber);
  return AyahReferenceLogic.filenameReference(ayah: ayah, surah: surah);
}
