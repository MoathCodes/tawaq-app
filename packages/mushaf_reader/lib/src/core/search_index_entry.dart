/// Parsed [search_index.hive] value (`"surahNumber|normalizedText"`).
typedef SearchIndexEntry = ({int surahNumber, String normalizedText});

/// Parses a [search_index.hive] entry. Returns null when [raw] is invalid.
SearchIndexEntry? parseSearchIndexEntry(String raw) {
  if (raw.isEmpty) return null;

  final separator = raw.indexOf('|');
  if (separator <= 0 || separator >= raw.length - 1) return null;

  final surahNumber = int.tryParse(raw.substring(0, separator));
  if (surahNumber == null) return null;

  final normalizedText = raw.substring(separator + 1);
  if (normalizedText.isEmpty) return null;

  return (surahNumber: surahNumber, normalizedText: normalizedText);
}

/// Encodes a search index entry for [search_index.hive] generation.
String encodeSearchIndexEntry({
  required int surahNumber,
  required String normalizedText,
}) {
  return '$surahNumber|$normalizedText';
}
