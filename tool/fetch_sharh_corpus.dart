// ignore_for_file: avoid_print

import 'dart:io';

import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:sqlite3/sqlite3.dart';

/// Fetches additional sharh pages from Dorar.net and caches them in [cache.db].
///
/// Usage (from project root):
/// ```bash
/// dart run tool/fetch_sharh_corpus.dart [target_count] [cache.db path]
/// ```
Future<void> main(List<String> args) async {
  final targetCount = int.tryParse(args.isNotEmpty ? args[0] : '12') ?? 12;
  final dbPath = args.length > 1 ? args[1] : 'cache.db';

  final existingIds = _loadExistingSharhIds(dbPath);
  print('Existing sharh entries: ${existingIds.length}');

  const searchTerms = [
    'الصلاة',
    'السفر',
    'الصحابة',
    'النية',
    'الصيام',
    'الزكاة',
    'التوكل',
    'الصبر',
    'الدعاء',
    'البر',
    'الحياء',
    'الصدقة',
  ];

  final candidateIds = <String>[];
  final perTermCounts = <String, int>{};
  const maxPerTerm = 3;

  await DorarClient.use((client) async {
    for (final term in searchTerms) {
      if (candidateIds.length >= targetCount) break;

      print('Searching: $term');
      final results = await client.searchHadithDetailed(
        HadithSearchParams(value: term),
      );

      var termAdded = 0;
      for (final hadith in results.data) {
        if (candidateIds.length >= targetCount || termAdded >= maxPerTerm) break;

        final id = hadith.sharhMetadata?.id;
        if (id == null || existingIds.contains(id) || candidateIds.contains(id)) {
          continue;
        }
        candidateIds.add(id);
        termAdded++;
        perTermCounts[term] = (perTermCounts[term] ?? 0) + 1;
        print('  candidate $id (${hadith.mohdith})');
      }
    }

    print('\nFetching ${candidateIds.length} new sharhs...');
    var fetched = 0;
    for (final id in candidateIds) {
      try {
        await client.getSharhById(id);
        fetched++;
        print('  fetched $id ($fetched/${candidateIds.length})');
      } on DorarException catch (e) {
        print('  failed $id: $e');
      }
    }

    final total = _loadExistingSharhIds(dbPath).length;
    print('\nAdded $fetched new sharhs (corpus total: $total)');
  });
}

Set<String> _loadExistingSharhIds(String dbPath) {
  final file = File(dbPath);
  if (!file.existsSync()) return {};

  final db = sqlite3.open(dbPath);
  try {
    final rows = db.select('''
      SELECT key FROM cache_table
      WHERE key LIKE '%/hadith/sharh/%'
    ''');
    return rows.map((row) => (row['key'] as String).split('/').last).toSet();
  } finally {
    db.dispose();
  }
}
