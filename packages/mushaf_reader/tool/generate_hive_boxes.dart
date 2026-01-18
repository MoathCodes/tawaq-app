// ignore_for_file: avoid_print
/// Script to generate pre-populated Hive boxes from JSON data.
///
/// Run with: `dart run tool/generate_hive_boxes.dart`
///
/// This creates the following `.hive` files in `assets/hive/`:
/// - `ayahs.hive` - All 6236 ayahs keyed by ayah ID
/// - `surahs.hive` - All 114 surahs keyed by surah number
/// - `juzs.hive` - All 30 juzs keyed by juz number
/// - `pageLayouts.hive` - Page layouts keyed by page number (1-604)
/// - `metadata.hive` - Key-value metadata (e.g., basmalah glyph)
/// - `manifest.json` - MD5 hashes for versioning
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:hive_ce/hive.dart';
import 'package:mushaf_reader/src/data/hive/hive_adapters.dart';
import 'package:mushaf_reader/src/data/models/ayah.dart';
import 'package:mushaf_reader/src/data/models/juz.dart';
import 'package:mushaf_reader/src/data/models/page_layouts.dart';
import 'package:mushaf_reader/src/data/models/revelation_type.dart';
import 'package:mushaf_reader/src/data/models/surah.dart';
import 'package:mushaf_reader/src/data/surah_metadata.dart';
import 'package:path/path.dart' as p;

Future<void> main() async {
  final projectRoot = Directory.current.path;
  final quranJsonPath = p.join(projectRoot, 'assets', 'jsons', 'quran.json');
  final quranFullJsonPath = p.join(
    projectRoot,
    'assets',
    'jsons',
    'quran_full.json',
  );
  final hafsJsonPath = p.join(
    projectRoot,
    'assets',
    'jsons',
    'quran_hafs.json',
  );
  final hiveOutputDir = p.join(projectRoot, 'assets', 'hive');

  // Create output directory
  final outputDir = Directory(hiveOutputDir);
  if (outputDir.existsSync()) {
    outputDir.deleteSync(recursive: true);
  }
  outputDir.createSync(recursive: true);

  // Initialize Hive with output directory
  Hive.init(hiveOutputDir);

  // Register adapters
  Hive
    ..registerAdapter(JuzAdapter())
    ..registerAdapter(AyahAdapter())
    ..registerAdapter(PageLayoutsAdapter())
    ..registerAdapter(SurahAdapter())
    ..registerAdapter(RevelationTypeAdapter());

  print('Reading JSON files...');
  final quranJson =
      json.decode(File(quranJsonPath).readAsStringSync())
          as Map<String, dynamic>;
  final quranFullJson =
      json.decode(File(quranFullJsonPath).readAsStringSync())
          as Map<String, dynamic>;
  final hafsJson =
      json.decode(File(hafsJsonPath).readAsStringSync()) as List<dynamic>;

  final data = quranJson['data'] as Map<String, dynamic>;
  final surahsData = data['surahs'] as List<dynamic>;
  final juzsData = data['juzs'] as List<dynamic>;
  final basmalahData = data['basmalah'] as List<dynamic>;

  // Extract pages from quran_full.json
  final fullData = quranFullJson['data'] as Map<String, dynamic>;
  final pagesData = fullData['pages'] as List<dynamic>;

  // Generate Surahs box
  print('Generating surahs.hive...');
  await _generateSurahsBox(surahsData);

  // Generate Ayahs box using quran_full.json for word-level glyph construction
  print('Generating ayahs.hive...');
  await _generateAyahsBox(surahsData, pagesData);

  // Generate Juzs box (needs surahsData to calculate start page/ayah)
  print('Generating juzs.hive...');
  await _generateJuzsBox(juzsData, surahsData);

  // Generate PageLayouts box
  print('Generating pageLayouts.hive...');
  await _generatePageLayoutsBox(hafsJson);

  // Generate Metadata box
  print('Generating metadata.hive...');
  await _generateMetadataBox(basmalahData);

  await Hive.close();

  print('Done! Hive boxes generated in $hiveOutputDir');
  print('');
  print('Generated files:');
  for (final file in outputDir.listSync()) {
    if (file is! File) continue;
    final size = file.lengthSync();
    print(
      '  - ${p.basename(file.path)}: ${(size / 1024).toStringAsFixed(1)} KB',
    );
  }

  // Generate manifest.json with MD5 hashes for versioning
  print('');
  print('Generating manifest.json...');
  await _generateManifest(hiveOutputDir);
}

/// Generates a manifest.json file with MD5 hashes of all .hive files.
///
/// This manifest is used at runtime to detect when boxes need to be
/// re-copied from assets (e.g., after library update).
Future<void> _generateManifest(String hiveDir) async {
  final manifest = <String, String>{};
  final dir = Directory(hiveDir);

  for (final file in dir.listSync()) {
    if (file is! File) continue;
    final name = p.basename(file.path);
    if (!name.endsWith('.hive')) continue;

    // Compute MD5 hash
    final bytes = await file.readAsBytes();
    final hash = md5.convert(bytes).toString();
    manifest[name] = hash;

    print('  - $name: $hash');
  }

  final manifestPath = p.join(hiveDir, 'manifest.json');
  await File(
    manifestPath,
  ).writeAsString(const JsonEncoder.withIndent('  ').convert(manifest));
  print('  - manifest.json written');
}

/// Converts a U+XXXX code point string to the actual character.
String codePointToChar(String code) {
  final hex = code.toUpperCase().replaceAll('U+', '');
  return String.fromCharCode(int.parse(hex, radix: 16));
}

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

Future<void> _generateAyahsBox(
  List<dynamic> surahsData,
  List<dynamic> pagesData,
) async {
  final box = await Hive.openBox<Ayah>('ayahs');

  // Build a map of ayah ID -> glyph text from quran_full.json
  final ayahGlyphs = <int, String>{};
  for (final page in pagesData) {
    final ayas = page['ayas'] as List<dynamic>;
    for (final aya in ayas) {
      final id = aya['id'] as int;
      // Skip special entries (surah name, basmalah, negative IDs)
      if (id < 1) continue;
      if (aya['isSurahName'] == true) continue;
      if (aya['isBasmala'] == true) continue;

      final words = aya['words'] as List<dynamic>;
      final glyph = _buildGlyphFromWords(words);
      ayahGlyphs[id] = glyph;
    }
  }

  var count = 0;
  for (final s in surahsData) {
    final surahNumber = s['number'] as int;
    final ayahs = s['ayahs'] as List<dynamic>;

    for (final a in ayahs) {
      final ayahId = a['number'] as int;
      // Use glyph from quran_full.json, fallback to code_v4/glyph from quran.json
      final glyph =
          ayahGlyphs[ayahId] ??
          a['glyph'] as String? ??
          a['code_v4'] as String? ??
          '';

      // Extract new fields
      final textPlain = a['aya_text_emlaey'] as String?;
      final manzil = a['manzil'] as int?;
      final ruku = a['ruku'] as int?;
      final hizbQuarter = a['hizbQuarter'] as int?;
      // sajda can be false (bool) or an object with details (means true)
      final sajdaValue = a['sajda'];
      final sajda = sajdaValue is bool ? sajdaValue : (sajdaValue != null);
      final pageInSurah = a['pageInSurah'] as int?;

      final ayah = Ayah(
        ayahId: ayahId,
        juz: a['juz'] as int,
        page: a['page'] as int,
        surahNumber: surahNumber,
        numberInSurah: a['numberInSurah'] as int,
        text: glyph,
        textPlain: textPlain,
        manzil: manzil,
        ruku: ruku,
        hizbQuarter: hizbQuarter,
        sajda: sajda,
        pageInSurah: pageInSurah,
      );

      await box.put(ayahId, ayah);
      count++;
    }
  }

  await box.close();
  print('  - $count ayahs written');
}

Future<void> _generateJuzsBox(
  List<dynamic> juzsData,
  List<dynamic> surahsData,
) async {
  final box = await Hive.openBox<Juz>('juzs');

  // Build a map of juz number -> first ayah info (for startPage, startAyahId)
  final juzFirstAyah = <int, Map<String, int>>{};
  for (final s in surahsData) {
    final ayahs = s['ayahs'] as List<dynamic>;
    for (final a in ayahs) {
      final juzNum = a['juz'] as int;
      final ayahId = a['number'] as int;
      final page = a['page'] as int;
      // Only store if this is the first ayah we've seen for this juz
      if (!juzFirstAyah.containsKey(juzNum)) {
        juzFirstAyah[juzNum] = {'ayahId': ayahId, 'page': page};
      }
    }
  }

  for (final j in juzsData) {
    final number = j['number'] as int;
    final codeV4 = j['code_v4'] as String?;
    final glyph = codeV4 != null ? codePointToChar(codeV4) : '';

    final firstAyah = juzFirstAyah[number];
    final juz = Juz(
      number: number,
      glyph: glyph,
      startPage: firstAyah?['page'],
      startAyahId: firstAyah?['ayahId'],
    );
    await box.put(number, juz);
  }

  final count = box.length;
  await box.close();
  print('  - $count juzs written');
}

Future<void> _generateMetadataBox(List<dynamic> basmalahData) async {
  final box = await Hive.openBox<String>('metadata');

  // Basmalah glyph is array of code points in reverse order
  final basmalahGlyph = basmalahData.reversed
      .map((e) => codePointToChar(e as String))
      .join();

  await box.put('basmalah', basmalahGlyph);

  await box.close();
  print('  - metadata written (basmalah glyph)');
}

Future<void> _generatePageLayoutsBox(List<dynamic> hafsData) async {
  // Group layouts by page number
  final layoutsByPage = <int, List<PageLayouts>>{};

  for (final entry in hafsData) {
    final page = entry['page'] as int;
    final ayahId = entry['id'] as int;
    final lineStart = entry['line_start'] as int;
    final lineEnd = entry['line_end'] as int;

    final layout = PageLayouts(
      page: page,
      ayahId: ayahId,
      lineStart: lineStart,
      lineEnd: lineEnd,
    );

    (layoutsByPage[page] ??= []).add(layout);
  }

  // Open box and store layouts with compound keys (page_index)
  final box = await Hive.openBox<PageLayouts>('pagelayouts');

  for (final entry in layoutsByPage.entries) {
    final page = entry.key;
    final layouts = entry.value;
    for (var i = 0; i < layouts.length; i++) {
      await box.put('${page}_$i', layouts[i]);
    }
  }

  final count = box.length;
  await box.close();
  print('  - $count layout entries written (${layoutsByPage.length} pages)');
}

Future<void> _generateSurahsBox(List<dynamic> surahsData) async {
  final box = await Hive.openBox<Surah>('surahs');

  for (final s in surahsData) {
    final surahNumber = s['number'] as int;

    // Get metadata from surah_metadata.dart
    final meta = surahMetadata.firstWhere(
      (m) => m['number'] == surahNumber,
      orElse: () => <String, dynamic>{},
    );

    // code_v4 for surahs is in U+XXXX format
    final codeV4 = s['code_v4'] as String?;
    final glyph = codeV4 != null ? codePointToChar(codeV4) : '';

    // hasBasmallah (note: JSON has typo "hasBasmallah")
    final hasBasmalah =
        s['hasBasmallah'] as bool? ?? (surahNumber != 9 || surahNumber != 1);

    // Parse revelationType from JSON string to enum
    final revelationTypeStr = s['revelationType'] as String?;
    RevelationType? revelationType;
    if (revelationTypeStr != null) {
      revelationType = revelationTypeStr.toLowerCase() == 'meccan'
          ? RevelationType.meccan
          : RevelationType.medinan;
    }

    // Get ayah count from the ayahs array length
    final ayahsList = s['ayahs'] as List<dynamic>?;
    final ayahCount = ayahsList?.length;

    // Get English translation of surah name meaning
    final englishNameTranslation = s['englishNameTranslation'] as String?;

    final surah = Surah(
      number: surahNumber,
      glyph: glyph,
      hasBasmalah: hasBasmalah,
      nameArabic: meta['nameArabic'] as String?,
      nameEnglish: meta['nameEnglish'] as String?,
      startPage: meta['startPage'] as int?,
      revelationType: revelationType,
      englishNameTranslation: englishNameTranslation,
      ayahCount: ayahCount,
    );

    await box.put(surahNumber, surah);
  }

  final count = box.length;
  await box.close();
  print('  - $count surahs written');
}
