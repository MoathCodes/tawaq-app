import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_models.dart';
import 'package:tawaq/feature/quran/domain/services/ayah_reference_logic.dart';
import 'package:tawaq/l10n/app_localizations.dart';

/// Localized label for a repeat count (1, 2, or N times).
String repeatCountLabel(AppLocalizations l10n, int count) {
  return switch (count) {
    1 => l10n.quranRangeRepeatOnce,
    2 => l10n.quranRangeRepeatTwice,
    _ => l10n.quranRangeRepeatTimes(count),
  };
}

/// Converts Hindu-Arabic numerals (٠-٩) to standard and strips non-digits.
String normalizeAyahInput(String input) {
  return input
      .replaceAll('٠', '0')
      .replaceAll('١', '1')
      .replaceAll('٢', '2')
      .replaceAll('٣', '3')
      .replaceAll('٤', '4')
      .replaceAll('٥', '5')
      .replaceAll('٦', '6')
      .replaceAll('٧', '7')
      .replaceAll('٨', '8')
      .replaceAll('٩', '9')
      .replaceAll(RegExp('[^0-9]'), '');
}

/// Formats a global range for display in the player chrome.
///
/// A null [to] means the range is open-ended and continues to the end of the
/// Quran.
String formatAyahRangeLabel({
  required MushafReaderController mushaf,
  required AppLocalizations l10n,
  required AyahReference from,
  required AyahReference? to,
}) {
  String refLabel(AyahReference r) {
    final name = AyahReferenceLogic.surahName(
      mushaf.getSurahSync(r.surah),
      r.surah,
      preferArabic: l10n.localeName.startsWith('ar'),
      fallbackName: '',
    );
    return name.isEmpty ? '' : '$name · ${r.ayah}';
  }

  if (to == null) {
    final fromLabel = refLabel(from);
    return fromLabel.isEmpty
        ? ''
        : '$fromLabel → ${l10n.quranRangePresetContinueFromHere}';
  }

  if (from.surah == to.surah && from.ayah == to.ayah) {
    return refLabel(from);
  }
  if (from.surah == to.surah) {
    final name = AyahReferenceLogic.surahName(
      mushaf.getSurahSync(from.surah),
      from.surah,
      preferArabic: l10n.localeName.startsWith('ar'),
      fallbackName: '',
    );
    return name.isEmpty ? '' : '$name · ${from.ayah}–${to.ayah}';
  }
  final fromLabel = refLabel(from);
  final toLabel = refLabel(to);
  if (fromLabel.isEmpty || toLabel.isEmpty) return '';
  return '$fromLabel → $toLabel';
}
