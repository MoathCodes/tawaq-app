// ignore_for_file: avoid_print
/// Script to generate the `glyph` attribute for each ayah in quran.json
/// using line break positions from data.json.
///
/// Run with: `dart run tool/generate_ayah_glyphs.dart`
///
/// This script:
/// 1. Reads data.json (word-level glyph data with line numbers)
/// 2. Reads quran.json (ayah-level data with code_v4)
/// 3. Rebuilds each ayah's glyph string with correct line breaks
/// 4. Handles leading newlines when an ayah starts on a new line
/// 5. Creates a backup of quran.json before modifying
/// 6. Writes the updated quran.json with the new `glyph` field
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

Future<void> main() async {
  final projectRoot = Directory.current.path;
  final dataJsonPath = p.join(projectRoot, 'assets', 'jsons', 'data.json');
  final quranJsonPath = p.join(projectRoot, 'assets', 'jsons', 'quran.json');
  final backupPath = p.join(projectRoot, 'assets', 'jsons', 'quran.json.bak');

  print('Reading data.json...');
  final dataJson =
      json.decode(File(dataJsonPath).readAsStringSync()) as List<dynamic>;

  print('Reading quran.json...');
  final quranJson =
      json.decode(File(quranJsonPath).readAsStringSync())
          as Map<String, dynamic>;

  // Build glyph map and page context map
  print('Building glyph map from data.json...');
  final glyphMap = _buildGlyphMap(dataJson);
  final pageContext = _buildPageContext(dataJson);

  // Process each ayah in quran.json
  print('Processing ayahs...');
  final data = quranJson['data'] as Map<String, dynamic>;
  final surahsData = data['surahs'] as List<dynamic>;

  var totalAyahs = 0;
  var warningsCount = 0;

  for (final surah in surahsData) {
    final surahNumber = surah['number'] as int;
    final ayahs = surah['ayahs'] as List<dynamic>;

    for (final ayah in ayahs) {
      final ayahNumberInSurah = ayah['numberInSurah'] as int;
      final codeV4 = ayah['code_v4'] as String? ?? '';

      // Strip existing newlines to get raw characters
      final rawChars = codeV4.replaceAll('\n', '');

      // Get glyph entries for this ayah
      final key = '$surahNumber:$ayahNumberInSurah';
      final glyphEntries = glyphMap[key];

      if (glyphEntries == null || glyphEntries.isEmpty) {
        print('  Warning: No glyph data found for $key');
        warningsCount++;
        // Just copy code_v4 as glyph
        ayah['glyph'] = codeV4;
        totalAyahs++;
        continue;
      }

      // Validate character count matches glyph count
      if (rawChars.length != glyphEntries.length) {
        print(
          '  Warning: Character count mismatch for $key: '
          '${rawChars.length} chars vs ${glyphEntries.length} glyphs',
        );
        warningsCount++;
      }

      // Check if this ayah needs a leading newline
      final needsLeadingNewline = _needsLeadingNewline(
        surahNumber,
        ayahNumberInSurah,
        glyphEntries,
        pageContext,
      );

      // Build the glyph string with correct line breaks
      final glyph = _buildGlyphString(
        rawChars,
        glyphEntries,
        needsLeadingNewline,
      );
      ayah['glyph'] = glyph;
      totalAyahs++;
    }
  }

  // Create backup
  print('Creating backup at $backupPath...');
  File(quranJsonPath).copySync(backupPath);

  // Write updated quran.json with proper formatting
  print('Writing updated quran.json...');
  const encoder = JsonEncoder.withIndent('  ');
  File(quranJsonPath).writeAsStringSync(encoder.convert(quranJson));

  print('');
  print('Done!');
  print('  Total ayahs processed: $totalAyahs');
  print('  Warnings: $warningsCount');
  print('  Backup created: $backupPath');
}

/// Builds a map of "surah:ayah" -> list of glyph entries sorted by order.
///
/// Filters for mushaf_id == 2 (Madinah Mushaf) and includes only
/// glyph_type_id 1-5 (words, ayah end, pause, hizb, sajdah).
/// Excludes glyph_type_id 6 (surah headers) and 8 (basmalah).
Map<String, List<Map<String, dynamic>>> _buildGlyphMap(List<dynamic> dataJson) {
  final map = <String, List<Map<String, dynamic>>>{};

  for (final entry in dataJson) {
    final e = entry as Map<String, dynamic>;

    // Filter by mushaf_id == 2
    final mushafId = e['mushaf_id'] as int?;
    if (mushafId != 2) continue;

    // Skip entries without ayah_number (surah headers, standalone basmalah)
    final ayahNumber = e['ayah_number'] as int?;
    if (ayahNumber == null) continue;

    // Include only glyph types 1-5
    final glyphTypeId = e['glyph_type_id'] as int?;
    if (glyphTypeId == null || glyphTypeId < 1 || glyphTypeId > 5) continue;

    final surahNumber = e['sura_number'] as int;
    final key = '$surahNumber:$ayahNumber';

    map.putIfAbsent(key, () => []);
    map[key]!.add(e);
  }

  // Sort each list by order
  for (final entries in map.values) {
    entries.sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));
  }

  return map;
}

/// Builds the glyph string by inserting newlines at line_number transitions.
String _buildGlyphString(
  String rawChars,
  List<Map<String, dynamic>> glyphEntries,
  bool needsLeadingNewline,
) {
  if (rawChars.isEmpty) return '';

  final buffer = StringBuffer();

  // Add leading newline if needed
  if (needsLeadingNewline) {
    buffer.write('\n');
  }

  int? previousLineNumber;

  // Use the minimum of rawChars length and glyphEntries length
  // to handle mismatches gracefully
  final length = rawChars.length < glyphEntries.length
      ? rawChars.length
      : glyphEntries.length;

  for (var i = 0; i < length; i++) {
    final currentLineNumber = glyphEntries[i]['line_number'] as int;

    // Insert newline when line number changes (but not before first char)
    if (previousLineNumber != null && currentLineNumber != previousLineNumber) {
      buffer.write('\n');
    }

    buffer.write(rawChars[i]);
    previousLineNumber = currentLineNumber;
  }

  // If there are remaining characters in rawChars (mismatch case),
  // append them without additional line breaks
  if (rawChars.length > length) {
    buffer.write(rawChars.substring(length));
  }

  return buffer.toString();
}

/// Builds page context: for each page, track all glyphs sorted by order.
/// This helps determine if an ayah needs a leading newline.
///
/// Returns a map of page_number -> list of (order, line_number, surah, ayah)
/// sorted by order, including ALL glyph types (headers, basmalah, etc.)
Map<int, List<_PageGlyph>> _buildPageContext(List<dynamic> dataJson) {
  final map = <int, List<_PageGlyph>>{};

  for (final entry in dataJson) {
    final e = entry as Map<String, dynamic>;

    // Filter by mushaf_id == 2
    final mushafId = e['mushaf_id'] as int?;
    if (mushafId != 2) continue;

    final pageNumber = e['page_number'] as int;
    final order = e['order'] as int;
    final lineNumber = e['line_number'] as int;
    final surahNumber = e['sura_number'] as int?;
    final ayahNumber = e['ayah_number'] as int?;
    final glyphTypeId = e['glyph_type_id'] as int?;

    map.putIfAbsent(pageNumber, () => []);
    map[pageNumber]!.add(
      _PageGlyph(
        order: order,
        lineNumber: lineNumber,
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        glyphTypeId: glyphTypeId,
      ),
    );
  }

  // Sort each page's glyphs by order
  for (final glyphs in map.values) {
    glyphs.sort((a, b) => a.order.compareTo(b.order));
  }

  return map;
}

/// Determines if an ayah needs a leading newline.
///
/// An ayah needs a leading newline if:
/// - The glyph immediately before this ayah's first glyph (on the same page)
///   is on a different line number.
/// - Only considers ayah content glyphs (types 1-5), not surah headers (6)
///   or basmalah (8) since those are rendered separately.
bool _needsLeadingNewline(
  int surahNumber,
  int ayahNumber,
  List<Map<String, dynamic>> glyphEntries,
  Map<int, List<_PageGlyph>> pageContext,
) {
  if (glyphEntries.isEmpty) return false;

  final firstGlyph = glyphEntries.first;
  final pageNumber = firstGlyph['page_number'] as int;
  final firstOrder = firstGlyph['order'] as int;
  final firstLineNumber = firstGlyph['line_number'] as int;

  final pageGlyphs = pageContext[pageNumber];
  if (pageGlyphs == null || pageGlyphs.isEmpty) return false;

  // Find the glyph immediately before this ayah's first glyph
  // Only consider ayah content glyphs (types 1-5), not headers (6) or basmalah (8)
  _PageGlyph? previousGlyph;
  for (final glyph in pageGlyphs) {
    if (glyph.order >= firstOrder) break;
    // Only consider ayah content glyphs for line break calculation
    final glyphType = glyph.glyphTypeId;
    if (glyphType != null && glyphType >= 1 && glyphType <= 5) {
      previousGlyph = glyph;
    }
  }

  // If there's no previous ayah content glyph on this page, no leading newline needed
  if (previousGlyph == null) return false;

  // If previous glyph is on a different line, we need a leading newline
  return previousGlyph.lineNumber != firstLineNumber;
}

/// Helper class to store page glyph context
class _PageGlyph {
  final int order;
  final int lineNumber;
  final int? surahNumber;
  final int? ayahNumber;
  final int? glyphTypeId;

  _PageGlyph({
    required this.order,
    required this.lineNumber,
    this.surahNumber,
    this.ayahNumber,
    this.glyphTypeId,
  });
}
