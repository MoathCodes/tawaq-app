// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mushaf_reader/src/data/hive/hive_adapters.dart';
import 'package:mushaf_reader/src/data/models/ayah.dart';
import 'package:path/path.dart' as p;

/// Strips HTML tags from a word (e.g., <span class="marker">ﭕ</span> -> ﭕ)
/// Also converts <br> to newline.
String _stripHtml(String word) {
  // First, replace <br> with newline
  var result = word.replaceAll('<br>', '\n');
  // Remove <span...> and </span> tags
  result = result
      .replaceAll(RegExp(r'<span[^>]*>'), '')
      .replaceAll('</span>', '');
  return result;
}

/// Builds glyph text from words array, replacing <br> with newlines.
String _buildGlyphFromWords(List<dynamic> words) {
  final buffer = StringBuffer();
  for (final word in words) {
    final w = word as String;
    if (w.isEmpty) continue;
    if (w == '<br>') {
      buffer.write('\n');
    } else {
      buffer.write(_stripHtml(w));
    }
  }
  return buffer.toString();
}

void main() {
  group('Glyph Generation Tests', () {
    late Map<String, dynamic> quranFullJson;
    late List<dynamic> pagesData;
    late Box<Ayah> ayahsBox;

    setUpAll(() async {
      // Find project root (navigate up from test directory)
      var dir = Directory.current;
      while (!File(p.join(dir.path, 'pubspec.yaml')).existsSync()) {
        dir = dir.parent;
      }
      final projectRoot = dir.path;

      // Read quran_full.json
      final quranFullPath = p.join(
        projectRoot,
        'assets',
        'jsons',
        'quran_full.json',
      );
      quranFullJson =
          json.decode(File(quranFullPath).readAsStringSync())
              as Map<String, dynamic>;
      final fullData = quranFullJson['data'] as Map<String, dynamic>;
      pagesData = fullData['pages'] as List<dynamic>;

      // Initialize Hive
      final hivePath = p.join(projectRoot, 'assets', 'hive');
      Hive.init(hivePath);
      Hive.registerAdapter(AyahAdapter());
      ayahsBox = await Hive.openBox<Ayah>('ayahs');
    });

    tearDownAll(() async {
      await ayahsBox.close();
    });

    test('Compare glyphs from JSON vs Hive for all pages', () async {
      final mismatches = <String>[];
      var totalAyahs = 0;
      var matchedAyahs = 0;

      for (final page in pagesData) {
        final pageIndex = page['index'] as int;
        final ayas = page['ayas'] as List<dynamic>;

        for (final aya in ayas) {
          final id = aya['id'] as int;
          // Skip special entries (surah name, basmalah, negative IDs)
          if (id < 1) continue;
          if (aya['isSurahName'] == true) continue;
          if (aya['isBasmala'] == true) continue;

          totalAyahs++;

          final words = aya['words'] as List<dynamic>;
          final expectedGlyph = _buildGlyphFromWords(words);

          final storedAyah = ayahsBox.get(id);
          if (storedAyah == null) {
            mismatches.add('Page $pageIndex, Ayah $id: NOT FOUND in Hive');
            continue;
          }

          final storedGlyph = storedAyah.text;

          if (expectedGlyph == storedGlyph) {
            matchedAyahs++;
          } else {
            // Show details about the mismatch
            final expectedNewlines = expectedGlyph.split('\n').length - 1;
            final storedNewlines = storedGlyph.split('\n').length - 1;

            if (expectedNewlines != storedNewlines) {
              mismatches.add(
                'Page $pageIndex, Ayah $id: '
                'newlines differ (expected: $expectedNewlines, got: $storedNewlines)\n'
                '  Expected: ${expectedGlyph.replaceAll('\n', '\\n')}\n'
                '  Got:      ${storedGlyph.replaceAll('\n', '\\n')}',
              );
            } else {
              mismatches.add(
                'Page $pageIndex, Ayah $id: content differs\n'
                '  Expected: ${expectedGlyph.replaceAll('\n', '\\n')}\n'
                '  Got:      ${storedGlyph.replaceAll('\n', '\\n')}',
              );
            }
          }
        }
      }

      // Print summary
      print('');
      print('=== Glyph Comparison Summary ===');
      print('Total ayahs checked: $totalAyahs');
      print('Matched: $matchedAyahs');
      print('Mismatches: ${mismatches.length}');

      if (mismatches.isNotEmpty) {
        print('');
        print('=== First 20 Mismatches ===');
        for (final m in mismatches.take(20)) {
          print(m);
          print('---');
        }
      }

      expect(
        mismatches,
        isEmpty,
        reason: 'Found ${mismatches.length} mismatches',
      );
    });

    test('Verify page 448 ayahs have correct line breaks', () async {
      // Find page 448
      final page448 = pagesData.firstWhere((p) => p['index'] == 448);
      final ayas = page448['ayas'] as List<dynamic>;

      print('');
      print('=== Page 448 Ayah Analysis ===');

      for (final aya in ayas) {
        final id = aya['id'] as int;
        if (id < 1) continue;

        final ayaNum = aya['aya'];
        final words = aya['words'] as List<dynamic>;
        final expectedGlyph = _buildGlyphFromWords(words);
        final storedAyah = ayahsBox.get(id);
        final storedGlyph = storedAyah?.text ?? '';

        final expectedNewlines = expectedGlyph.split('\n').length - 1;

        final hasLeadingBr = words.isNotEmpty && words.first == '<br>';
        final status = expectedGlyph == storedGlyph ? '✓' : '✗';

        print(
          '$status Ayah $ayaNum (id=$id): '
          '$expectedNewlines newlines, '
          'leading <br>: $hasLeadingBr, '
          'match: ${expectedGlyph == storedGlyph}',
        );

        if (expectedGlyph != storedGlyph) {
          print('  Expected: ${expectedGlyph.replaceAll('\n', '\\n')}');
          print('  Got:      ${storedGlyph.replaceAll('\n', '\\n')}');
        }
      }
    });

    test('Build full page 448 text and count lines', () async {
      // Build page text by concatenating ayahs in order
      final page448 = pagesData.firstWhere((p) => p['index'] == 448);
      final ayas = page448['ayas'] as List<dynamic>;

      // Build from JSON
      final jsonBuffer = StringBuffer();
      for (final aya in ayas) {
        final id = aya['id'] as int;
        if (id < 1) continue;
        final words = aya['words'] as List<dynamic>;
        jsonBuffer.write(_buildGlyphFromWords(words));
      }
      final jsonPageText = jsonBuffer.toString();

      // Build from Hive (simulating what repository does)
      final hiveBuffer = StringBuffer();
      for (final aya in ayas) {
        final id = aya['id'] as int;
        if (id < 1) continue;
        final storedAyah = ayahsBox.get(id);
        hiveBuffer.write(storedAyah?.text ?? '');
      }
      final hivePageText = hiveBuffer.toString();

      final jsonLines = jsonPageText.split('\n').length;
      final hiveLines = hivePageText.split('\n').length;

      print('');
      print('=== Page 448 Full Text Analysis ===');
      print('Expected lines from JSON: $jsonLines');
      print('Lines from Hive: $hiveLines');
      print('Expected total newlines: ${jsonLines - 1}');
      print('Actual total newlines: ${hiveLines - 1}');
      print('');
      print('Page declares ${page448['lines']} lines');

      expect(
        jsonPageText,
        equals(hivePageText),
        reason: 'Page text from JSON should match Hive',
      );
      expect(
        hiveLines,
        equals(page448['lines'] + 1),
        reason: 'Number of lines should match page declaration',
      );
    });
  });
}
