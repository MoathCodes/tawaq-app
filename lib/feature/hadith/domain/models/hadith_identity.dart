import 'package:dorar_hadith/dorar_hadith.dart';

/// Builds a stable bookmark key for a hadith record.
///
/// Prefers [DetailedHadith.hadithId] when present; otherwise falls back to a
/// composite of book, number, rawi, and text hash.
String hadithStableKey(HadithBase hadith) {
  if (hadith is DetailedHadith) {
    final id = hadith.hadithId;
    if (id != null && id.isNotEmpty) return id;
  }

  return '${hadith.book}|${hadith.numberOrPage}|'
      '${hadith.rawi}|${hadith.hadith.hashCode}';
}
