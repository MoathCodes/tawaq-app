// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:sqlite3/sqlite3.dart';
import 'package:tawaq/feature/hadith/domain/services/hadith_sharh_zone_splitter.dart';

void main(List<String> args) {
  final dbPath = args.isNotEmpty ? args[0] : 'cache.db';
  final outputPath = args.length > 1
      ? args[1]
      : 'test/fixtures/hadith_sharh_samples.json';

  final db = sqlite3.open(dbPath);
  final rows = db.select('''
    SELECT key, body FROM cache_table
    WHERE key LIKE '%/hadith/sharh/%'
    ORDER BY key
  ''');

  final fixtures = <Map<String, dynamic>>[];
  for (final row in rows) {
    final key = row['key'] as String;
    final body = jsonDecode(row['body'] as String) as Map<String, dynamic>;
    final id = key.split('/').last;
    final sharh = body['sharhMetadata']?['sharh'] as String? ?? '';
    final zones = HadithSharhZoneSplitter.split(sharh);
    final formatFamily =
        zones.isMetadataRich ? 'metadata-rich' : 'pure-essay';

    fixtures.add({
      'id': id,
      'hadith': body['hadith'],
      'sharh': sharh,
      'format_family': formatFamily,
      'zones': {
        'matn_prefix': zones.matnPrefix,
        'metadata': zones.metadata,
        'commentary': zones.commentary,
      },
      'pattern_flags': _patternFlags(sharh, zones.commentary),
    });
  }

  db.dispose();

  final file = File(outputPath);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(fixtures),
  );
  print('Exported ${fixtures.length} entries to $outputPath');
}

Map<String, dynamic> _patternFlags(String raw, String commentary) {
  return {
    'has_rawi': RegExp(r'الراوي\s*:').hasMatch(raw),
    'has_ay_gloss': commentary.contains('أي:'),
    'has_gloss_chain': RegExp(r'"[^"]+"\s*،\s*أي\s*:').hasMatch(commentary),
    'has_waqil': commentary.contains('وقيل:'),
    'has_section_lead': RegExp(r'وفي هذا الحديث|في الحديث:|وفيه:')
        .hasMatch(commentary),
    'has_ascii_quote': RegExp(r'"[^"]+"').hasMatch(commentary),
    'has_guillemet': RegExp(r'«[^»]+»').hasMatch(commentary),
    'has_bracket': RegExp(r'\[[^\]]+\]').hasMatch(commentary),
    'has_scholar_lead': RegExp(r'(?:فقال|قال)\s+').hasMatch(commentary),
  };
}
