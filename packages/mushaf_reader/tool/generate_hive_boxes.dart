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
library;

import 'dart:convert';
import 'dart:io';

import 'package:hive_ce/hive.dart';
import 'package:mushaf_reader/src/data/hive/hive_adapters.dart';
import 'package:mushaf_reader/src/data/models/ayah_model.dart';
import 'package:mushaf_reader/src/data/models/juz_model.dart';
import 'package:mushaf_reader/src/data/models/page_layouts.dart';
import 'package:mushaf_reader/src/data/models/surah_model.dart';
import 'package:mushaf_reader/src/data/surah_metadata.dart';
import 'package:path/path.dart' as p;

Future<void> main() async {
  final projectRoot = Directory.current.path;
  final quranJsonPath = p.join(projectRoot, 'assets', 'jsons', 'quran.json');
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
    ..registerAdapter(JuzModelAdapter())
    ..registerAdapter(AyahModelAdapter())
    ..registerAdapter(PageLayoutsAdapter())
    ..registerAdapter(SurahModelAdapter());

  print('Reading JSON files...');
  final quranJson =
      json.decode(File(quranJsonPath).readAsStringSync())
          as Map<String, dynamic>;
  final hafsJson =
      json.decode(File(hafsJsonPath).readAsStringSync()) as List<dynamic>;

  final data = quranJson['data'] as Map<String, dynamic>;
  final surahsData = data['surahs'] as List<dynamic>;
  final juzsData = data['juzs'] as List<dynamic>;
  final basmalahData = data['basmalah'] as List<dynamic>;

  // Generate Surahs box
  print('Generating surahs.hive...');
  await _generateSurahsBox(surahsData);

  // Generate Ayahs box
  print('Generating ayahs.hive...');
  await _generateAyahsBox(surahsData);

  // Generate Juzs box
  print('Generating juzs.hive...');
  await _generateJuzsBox(juzsData);

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
    final size = (file as File).lengthSync();
    print(
      '  - ${p.basename(file.path)}: ${(size / 1024).toStringAsFixed(1)} KB',
    );
  }
}

/// Converts a U+XXXX code point string to the actual character.
String codePointToChar(String code) {
  final hex = code.toUpperCase().replaceAll('U+', '');
  return String.fromCharCode(int.parse(hex, radix: 16));
}

Future<void> _generateAyahsBox(List<dynamic> surahsData) async {
  final box = await Hive.openBox<AyahModel>('ayahs');

  var count = 0;
  for (final s in surahsData) {
    final surahNumber = s['number'] as int;
    final ayahs = s['ayahs'] as List<dynamic>;

    for (final a in ayahs) {
      final ayahId = a['number'] as int;
      final glyph = a['glyph'] as String? ?? a['code_v4'] as String? ?? '';

      final ayah = AyahModel(
        id: ayahId,
        juz: a['juz'] as int,
        page: a['page'] as int,
        surah: surahNumber,
        numberInSurah: a['numberInSurah'] as int,
        text: glyph,
      );

      await box.put(ayahId, ayah);
      count++;
    }
  }

  await box.close();
  print('  - $count ayahs written');
}

Future<void> _generateJuzsBox(List<dynamic> juzsData) async {
  final box = await Hive.openBox<JuzModel>('juzs');

  for (final j in juzsData) {
    final number = j['number'] as int;
    final codeV4 = j['code_v4'] as String?;
    final glyph = codeV4 != null ? codePointToChar(codeV4) : '';

    final juz = JuzModel(number: number, glyph: glyph);
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
  final box = await Hive.openBox<SurahModel>('surahs');

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
    final hasBasmalah = s['hasBasmallah'] as bool? ?? (surahNumber != 9);

    final surah = SurahModel(
      number: surahNumber,
      glyph: glyph,
      hasBasmalah: hasBasmalah,
      nameArabic: meta['nameArabic'] as String?,
      nameEnglish: meta['nameEnglish'] as String?,
      startPage: meta['startPage'] as int?,
    );

    await box.put(surahNumber, surah);
  }

  final count = box.length;
  await box.close();
  print('  - $count surahs written');
}
