import 'package:mushaf_reader/core/performance_utils.dart';
import 'package:mushaf_reader/src/data/models/ayah_model.dart';
import 'package:mushaf_reader/src/data/models/juz_model.dart';
import 'package:mushaf_reader/src/data/models/quran_page_model.dart';
import 'package:mushaf_reader/src/data/repository/quran_repo.dart';

class MushafController {
  static final instance = MushafController._();
  final _repo = QuranRepository();

  // Flag to track initialization
  bool _isPreloaded = false;

  MushafController._();

  /// Clear caches to free memory if needed
  void clearCaches() {
    PerformanceUtils.clearCaches();
  }

  Future<AyahModel> getAyah(int ayahId) => _repo.getAyah(ayahId);

  Future<AyahModel> getAyahBySurah(int surah, int ayahInSurah) =>
      _repo.getAyahBySurah(surah, ayahInSurah);
  Future<String> getBasmalah() => _repo.getBasmalah();

  Future<JuzModel> getJuz(int number) => _repo.getJuz(number);
  // New APIs
  Future<List<JuzModel>> getJuzs() => _repo.getJuzs();

  Future<QuranPageModel> getPage(int page) => _repo.getPage(page);

  Future<void> init() async {
    await _repo.ensureReady();

    // Preload performance caches if not already done
    if (!_isPreloaded) {
      PerformanceUtils.preloadPageNumbers();
      PerformanceUtils.preloadFontFamilies();
      _isPreloaded = true;
    }
  }

  /// Preload pages for better performance (optional)
  Future<void> preloadPages(List<int> pageNumbers) async {
    await init(); // Ensure repository is ready

    // Preload pages in parallel batches to avoid overwhelming the system
    const batchSize = 10;
    for (int i = 0; i < pageNumbers.length; i += batchSize) {
      final batch = pageNumbers.skip(i).take(batchSize);
      await Future.wait(batch.map((page) => getPage(page)));
    }
  }
}
