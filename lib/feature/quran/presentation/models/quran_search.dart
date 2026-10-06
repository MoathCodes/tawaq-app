import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/feature/quran/domain/services/quran_search_query.dart';

enum QuranSearchKind { surah, juz, hizb, ayah }

/// A navigation destination, separate from the unchanged source text.
class QuranSearchResult {
  const new(this.kind, this.number, {this.surah, this.ayah});
  final QuranSearchKind kind;
  final int number;
  final Surah? surah;
  final Ayah? ayah;
}

/// Searches cached navigation metadata and the repository's bounded text index.
class QuranSearch {
  new(this.controller);
  final MushafReaderController controller;

  Future<List<QuranSearchResult>> search(String input) async {
    final query = normalizeQuranSearchQuery(input);
    if (query.isEmpty) return [];
    final surahs = await controller.getAllSurahs();
    final reference = RegExp(r'^(\d+)\s*[:：/]\s*(\d+)$').firstMatch(query);
    if (reference != null) {
      return await _ayah(
        surahs,
        int.parse(reference[1]!),
        int.parse(reference[2]!),
      );
    }
    final division = RegExp(
      r'^(juz|juz\x27|جزء|الجزء|حزب|الحزب|hizb|surah|sura|سورة|سوره)(?:\s+|(?=\d)|$)(.*)$',
    ).firstMatch(query);
    final prefix = division?[1];
    final term = division?[2]?.trim() ?? query;
    final kind = switch (prefix) {
      'juz' || "juz'" || 'جزء' || 'الجزء' => QuranSearchKind.juz,
      'hizb' || 'حزب' || 'الحزب' => QuranSearchKind.hizb,
      'surah' || 'sura' || 'سورة' || 'سوره' => QuranSearchKind.surah,
      _ => null,
    };
    final number = int.tryParse(term);
    final results = <QuranSearchResult>[];
    if (kind == null || kind == QuranSearchKind.surah) {
      results.addAll(
        (number == null
                ? searchSurahs(surahs, term)
                : surahs.where((s) => s.number == number))
            .take(6)
            .map(
              (s) =>
                  QuranSearchResult(QuranSearchKind.surah, s.number, surah: s),
            ),
      );
    }
    if (kind == QuranSearchKind.juz ||
        kind == QuranSearchKind.hizb ||
        (kind == null && number != null)) {
      for (final type in [QuranSearchKind.juz, QuranSearchKind.hizb]) {
        if (kind != null && kind != type) continue;
        final max = type == QuranSearchKind.juz ? 30 : 60;
        if (number != null && number >= 1 && number <= max) {
          final startId = type == QuranSearchKind.juz
              ? (await controller.getJuz(number)).startAyahId
              : (await controller.getHizb(number)).startAyahId;
          final ayah = startId == null
              ? null
              : await controller.getAyah(startId);
          results.add(
            QuranSearchResult(
              type,
              number,
              ayah: ayah,
              surah: ayah == null
                  ? null
                  : surahs
                        .where((s) => s.number == ayah.surahNumber)
                        .firstOrNull,
            ),
          );
        }
      }
    }
    if ((kind != null && kind != QuranSearchKind.surah) || number != null) {
      return results;
    }
    // Named references, e.g. "Al-Baqarah 255" or "البقرة ٢٥٥".
    final named = RegExp(r'^(.+?)\s+(\d+)$').firstMatch(term);
    if (named != null) {
      final matches = searchSurahs(surahs, named[1]!).toList();
      if (matches.length == 1) {
        return await _ayah(surahs, matches.single.number, int.parse(named[2]!));
      }
    }
    if (kind == QuranSearchKind.surah) return results;
    if (query.length >= 2) {
      final ayahs = await controller.searchAyahs(input, maxResults: 20);
      results.addAll(
        ayahs.map(
          (ayah) => QuranSearchResult(
            QuranSearchKind.ayah,
            ayah.numberInSurah,
            ayah: ayah,
            surah: controller.getSurahSync(ayah.surahNumber),
          ),
        ),
      );
    }
    return results;
  }

  Future<List<QuranSearchResult>> _ayah(
    List<Surah> surahs,
    int surah,
    int number,
  ) async {
    final metadata = surahs.where((s) => s.number == surah).firstOrNull;
    if (metadata == null ||
        number < 1 ||
        (metadata.ayahCount != null && number > metadata.ayahCount!)) {
      return [];
    }
    final ayah = await controller.getAyahBySurah(surah, number);
    return [
      QuranSearchResult(
        QuranSearchKind.ayah,
        number,
        ayah: ayah,
        surah: metadata,
      ),
    ];
  }
}
