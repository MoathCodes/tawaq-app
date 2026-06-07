// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:sqlite3/sqlite3.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_sharh_segment.dart';
import 'package:tawaq/feature/hadith/domain/services/hadith_sharh_normalizer.dart';
import 'package:tawaq/feature/hadith/domain/services/hadith_sharh_segment_tokenizer.dart';
import 'package:tawaq/feature/hadith/domain/services/hadith_sharh_zone_splitter.dart';

void main(List<String> args) {
  final dbPath = args.isNotEmpty ? args[0] : 'cache.db';
  final db = sqlite3.open(dbPath);

  final rows = db.select('''
    SELECT key, body FROM cache_table
    WHERE key LIKE '%/hadith/sharh/%'
    ORDER BY key
  ''');

  final entries = <_SharhEntry>[];
  for (final row in rows) {
    final key = row['key'] as String;
    final body = jsonDecode(row['body'] as String) as Map<String, dynamic>;
    final id = key.split('/').last;
    final sharh = body['sharhMetadata']?['sharh'] as String? ?? '';
    entries.add(
      _SharhEntry(
        id: id,
        hadith: (body['hadith']?['hadith'] as String?) ?? '',
        sharh: sharh,
      ),
    );
  }

  print('=== CORPUS STATS ===');
  print('entries: ${entries.length}');
  if (entries.isEmpty) {
    db.dispose();
    return;
  }

  final lengths = entries.map((e) => e.sharh.length).toList();
  final avgLen = lengths.reduce((a, b) => a + b) / lengths.length;
  print('avg_len: ${avgLen.round()}');

  final familyCounts = <String, int>{};
  for (final entry in entries) {
    final family = RegExp(r'الراوي\s*:').hasMatch(entry.sharh)
        ? 'metadata-rich'
        : 'pure-essay';
    familyCounts[family] = (familyCounts[family] ?? 0) + 1;
  }
  print('format_family counts: $familyCounts');

  print('\n=== ZONE SPLIT (per entry) ===');
  for (final entry in entries) {
    final zones = HadithSharhZoneSplitter.split(entry.sharh);
    print(
      '${entry.id}: matn=${zones.matnPrefix?.length ?? 0} '
      'meta=${zones.metadata?.length ?? 0} '
      'commentary=${zones.commentary.length}',
    );
    if (zones.matnPrefix case final prefix?) {
      print('  prefix: ${_trunc(prefix, 120)}');
    }
  }

  print('\n=== PATTERN COUNTS (across corpus) ===');
  final patterns = <String, int>{
    'أي:': 0,
    'بمعنى:': 0,
    'المراد': 0,
    'ومعناها': 0,
    'ascii_quotes': 0,
    'guillemets': 0,
    'gloss_chains': 0,
    'قال/فقال': 0,
    'وقيل:': 0,
    'وفي هذا الحديث': 0,
    'في الحديث:': 0,
    'وفيه:': 0,
    'أخرجه': 0,
    '((book))': 0,
    'الراوي': 0,
    'المحدث': 0,
    'المصدر': 0,
    'التخريج': 0,
    'brackets': 0,
    'semicolons': 0,
  };

  for (final entry in entries) {
    final text = entry.sharh;
    if (text.contains('أي:')) patterns['أي:'] = patterns['أي:']! + 1;
    if (text.contains('بمعنى:')) patterns['بمعنى:'] = patterns['بمعنى:']! + 1;
    if (text.contains('المراد')) patterns['المراد'] = patterns['المراد']! + 1;
    if (text.contains('ومعناها')) patterns['ومعناها'] = patterns['ومعناها']! + 1;
    if (RegExp('"[^"]+"').hasMatch(text)) {
      patterns['ascii_quotes'] = patterns['ascii_quotes']! + 1;
    }
    if (RegExp('«[^»]+»').hasMatch(text)) {
      patterns['guillemets'] = patterns['guillemets']! + 1;
    }
    if (RegExp(r'"[^"]+"\s*،\s*أي\s*:').hasMatch(text)) {
      patterns['gloss_chains'] = patterns['gloss_chains']! + 1;
    }
    if (RegExp(r'(?:فقال|قال)\s+').hasMatch(text)) {
      patterns['قال/فقال'] = patterns['قال/فقال']! + 1;
    }
    if (text.contains('وقيل:')) patterns['وقيل:'] = patterns['وقيل:']! + 1;
    if (text.contains('وفي هذا الحديث')) {
      patterns['وفي هذا الحديث'] = patterns['وفي هذا الحديث']! + 1;
    }
    if (text.contains('في الحديث:')) {
      patterns['في الحديث:'] = patterns['في الحديث:']! + 1;
    }
    if (text.contains('وفيه:')) patterns['وفيه:'] = patterns['وفيه:']! + 1;
    if (text.contains('أخرجه')) patterns['أخرجه'] = patterns['أخرجه']! + 1;
    if (text.contains('((')) patterns['((book))'] = patterns['((book))']! + 1;
    if (text.contains('الراوي')) patterns['الراوي'] = patterns['الراوي']! + 1;
    if (text.contains('المحدث')) patterns['المحدث'] = patterns['المحدث']! + 1;
    if (text.contains('المصدر')) patterns['المصدر'] = patterns['المصدر']! + 1;
    if (text.contains('التخريج')) patterns['التخريج'] = patterns['التخريج']! + 1;
    if (RegExp(r'\[[^\]]+\]').hasMatch(text)) {
      patterns['brackets'] = patterns['brackets']! + 1;
    }
    patterns['semicolons'] =
        patterns['semicolons']! + ';'.allMatches(text).length;
  }
  for (final entry in patterns.entries) {
    print('${entry.key}: ${entry.value}');
  }

  print('\n=== PIPELINE PREVIEW ===');
  final kindTotals = <HadithSharhSegmentKind, int>{};
  for (final entry in entries.take(3)) {
    final zones = HadithSharhZoneSplitter.split(entry.sharh);
    final normalized = HadithSharhNormalizer.normalize(zones.commentary);
    final segments = HadithSharhSegmentTokenizer.tokenize(zones.commentary);
    for (final segment in segments) {
      kindTotals[segment.kind] = (kindTotals[segment.kind] ?? 0) + 1;
    }
    print(
      '${entry.id}: segments=${segments.length} '
      'preview=${_trunc(normalized, 100)}',
    );
  }
  print(
    'sample_kind_counts: '
    '${kindTotals.map((k, v) => MapEntry(k.name, v))}',
  );

  print('\n=== ISSUE SCAN ===');
  var issueNum = 0;
  for (final entry in entries) {
    final zones = HadithSharhZoneSplitter.split(entry.sharh);
    if (zones.isMetadataRich &&
        RegExp(r'الراوي\s*:').hasMatch(zones.commentary)) {
      issueNum++;
      print('ISSUE $issueNum [HIGH] metadata leaked into commentary (${entry.id})');
    }

    if (zones.isMetadataRich &&
        zones.matnPrefix != null &&
        entry.hadith.trim().startsWith(zones.matnPrefix!.trim().substring(0, 20))) {
      issueNum++;
      print('ISSUE $issueNum [MEDIUM] matn prefix duplicates API hadith (${entry.id})');
    }

    final quoteCount = '"'.allMatches(zones.commentary).length;
    if (quoteCount.isOdd) {
      issueNum++;
      print('ISSUE $issueNum [MEDIUM] unbalanced quotes in commentary (${entry.id})');
    }
  }
  print('issue_count=$issueNum');

  print('\n=== PER-ID NOTES ===');
  for (final entry in entries) {
    final zones = HadithSharhZoneSplitter.split(entry.sharh);
    final family = zones.isMetadataRich ? 'metadata-rich' : 'pure-essay';
    final glossChains =
        RegExp(r'"[^"]+"\s*،\s*أي\s*:').allMatches(zones.commentary).length;
    final waqil = 'وقيل:'.allMatches(zones.commentary).length;
    final ay = 'أي:'.allMatches(zones.commentary).length;
    print(
      '${entry.id}: $family, $ay× أي, $glossChains gloss chains, '
      '$waqil× وقيل, commentary=${zones.commentary.length}',
    );
  }

  db.dispose();
}

class _SharhEntry {
  const _SharhEntry({
    required this.id,
    required this.hadith,
    required this.sharh,
  });

  final String id;
  final String hadith;
  final String sharh;
}

String _trunc(String s, int max) {
  final oneLine = s.replaceAll('\n', r'\n');
  if (oneLine.length <= max) return oneLine;
  return '${oneLine.substring(0, max)}...';
}
