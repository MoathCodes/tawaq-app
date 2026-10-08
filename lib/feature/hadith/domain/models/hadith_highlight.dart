import 'package:tawaq/core/text/arabic_search_normalize.dart';

/// Exact UTF-16 source ranges for normalized query matches; source stays intact.
List<({int start, int end})> hadithQueryRanges(String source, String query) {
  final needle = normalizeArabicForSearch(query.trim()).toLowerCase();
  if (needle.isEmpty) return const [];
  final normalized = StringBuffer();
  final starts = <int>[];
  var offset = 0;
  for (final rune in source.runes) {
    final original = String.fromCharCode(rune);
    final folded = normalizeArabicForSearch(original).toLowerCase();
    normalized.write(folded);
    for (var i = 0; i < folded.length; i++) {
      starts.add(offset);
    }
    offset += original.length;
  }
  final haystack = normalized.toString();
  final matches = <({int start, int end})>[];
  var from = 0;
  while (from <= haystack.length - needle.length) {
    final found = haystack.indexOf(needle, from);
    if (found < 0) break;
    final after = found + needle.length;
    matches.add((
      start: starts[found],
      end: after < starts.length ? starts[after] : source.length,
    ));
    from = after;
  }
  return matches;
}
