/// Ranks ayah numbers in `1..ayahCount` by relevance to [query].
Iterable<int> searchAyahNumbers({
  required int ayahCount,
  required String query,
}) {
  if (query.isEmpty) {
    return List.generate(ayahCount, (i) => i + 1);
  }

  final normalized = query.trim();
  final queryNum = int.tryParse(normalized);
  final results = <(int, int)>[];

  for (var ayah = 1; ayah <= ayahCount; ayah++) {
    final ayahStr = ayah.toString();
    var score = 0;
    if (queryNum != null && ayah == queryNum) {
      score = 100;
    } else if (ayahStr == normalized) {
      score = 95;
    } else if (ayahStr.startsWith(normalized)) {
      score = 80;
    }
    if (score > 0) results.add((ayah, score));
  }

  results.sort((a, b) {
    final scoreCompare = b.$2.compareTo(a.$2);
    if (scoreCompare != 0) return scoreCompare;
    return a.$1.compareTo(b.$1);
  });

  return results.map((e) => e.$1);
}
