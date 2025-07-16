import 'package:mushaf_reader/src/data/models/ayah_model.dart';
import 'package:mushaf_reader/src/data/models/juz_model.dart';
import 'package:mushaf_reader/src/data/models/quran_page_model.dart';
import 'package:mushaf_reader/src/data/repository/quran_repo.dart';

class MushafController {
  static final instance = MushafController._();
  final _repo = QuranRepository();

  MushafController._();

  Future<AyahModel> getAyah(int ayahId) => _repo.getAyah(ayahId);
  Future<AyahModel> getAyahBySurah(int surah, int ayahInSurah) =>
      _repo.getAyahBySurah(surah, ayahInSurah);

  Future<String> getBasmalah() => _repo.getBasmalah();
  Future<JuzModel> getJuz(int number) => _repo.getJuz(number);

  // New APIs
  Future<List<JuzModel>> getJuzs() => _repo.getJuzs();
  Future<QuranPageModel> getPage(int page) => _repo.getPage(page);
  Future<void> init() => _repo.ensureReady();
}
