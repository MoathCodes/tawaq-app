import 'package:mushaf_reader/src/data/models/ayah_model.dart';
import 'package:mushaf_reader/src/data/models/juz_model.dart';
import 'package:mushaf_reader/src/data/models/quran_page_model.dart';
import 'package:mushaf_reader/src/data/models/surah_model.dart';

/// Abstract interface for Quran data access.
///
/// This interface defines the contract for retrieving Quran data,
/// allowing for different implementations (e.g., Hive, JSON, network).
///
/// The default implementation is [HiveQuranRepository] which uses
/// pre-populated Hive boxes for efficient data access.
///
/// ## Lifecycle
///
/// 1. Call [ensureReady] before any data access to initialize the repository
/// 2. Use the data access methods as needed
/// 3. Call [dispose] when done to release resources
///
/// ## Example
///
/// ```dart
/// class MyQuranRepository implements IQuranRepository {
///   @override
///   Future<void> ensureReady() async {
///     // Initialize database connection
///   }
///
///   @override
///   Future<QuranPageModel> getPage(int page) async {
///     // Fetch and return page data
///   }
///
///   // ... implement other methods
/// }
/// ```
///
/// See also:
/// - [HiveQuranRepository], the Hive-based implementation
/// - [MushafController], which uses this interface
abstract class IQuranRepository {
  /// Releases resources held by the repository.
  ///
  /// Call this method when the repository is no longer needed to
  /// close database connections and clear caches.
  void dispose();

  /// Ensures the repository is initialized and ready for data access.
  ///
  /// This method must be called before any other data access methods.
  /// It handles:
  /// - Database initialization and connection
  /// - Asset copying (for native platforms)
  /// - Cache pre-population
  ///
  /// This method is idempotent - calling it multiple times is safe
  /// and subsequent calls will return immediately if already initialized.
  ///
  /// Throws a [StateError] if initialization fails.
  Future<void> ensureReady();

  /// Retrieves all 114 Surahs.
  ///
  /// Returns a list of [SurahModel] objects ordered by Surah number.
  /// Useful for building surah index navigation.
  Future<List<SurahModel>> getAllSurahs();

  /// Retrieves an Ayah by its global unique ID.
  ///
  /// [ayahId] must be in the range 1-6236.
  ///
  /// [removeNewLines] controls whether newline characters in the glyph
  /// text are removed. Defaults to `true` for inline display.
  ///
  /// Throws an [ArgumentError] if the Ayah is not found.
  Future<AyahModel> getAyah(int ayahId, [bool removeNewLines = true]);

  /// Retrieves an Ayah by its Surah and verse number.
  ///
  /// [surah] must be in the range 1-114.
  /// [ayahInSurah] must be a valid verse number for the given Surah.
  ///
  /// [removeNewLines] controls whether newline characters in the glyph
  /// text are removed. Defaults to `true` for inline display.
  ///
  /// Throws an [ArgumentError] if the Ayah is not found.
  Future<AyahModel> getAyahBySurah(
    int surah,
    int ayahInSurah, [
    bool removeNewLines = true,
  ]);

  /// Retrieves the Basmalah glyph text.
  ///
  /// Returns the QCF4-encoded glyph for "Bismillah ir-Rahman ir-Raheem"
  /// to be displayed at the start of Surahs.
  ///
  /// This should be rendered with the Basmalah font (QCF4_BSML).
  Future<String> getBasmalah();

  /// Gets the Basmalah glyph synchronously from cache.
  ///
  /// Returns null if not cached. Call [ensureReady] first.
  String? getBasmalahSync();

  /// Retrieves a Juz by its number.
  ///
  /// [number] must be in the range 1-30.
  ///
  /// Returns the [JuzModel] with the display glyph.
  Future<JuzModel> getJuz(int number);

  /// Retrieves all 30 Juzs.
  ///
  /// Returns a list of [JuzModel] objects ordered by Juz number.
  /// Useful for building navigation or index views.
  Future<List<JuzModel>> getJuzs();

  /// Gets all Juzs synchronously from cache.
  ///
  /// Returns empty map if not cached. Call [ensureReady] first.
  Map<int, JuzModel> getJuzsSync();

  /// Gets the first page of a specific Juz.
  ///
  /// [juzNumber] must be in the range 1-30.
  ///
  /// Returns the page number (1-604) where the Juz begins.
  Future<int> getJuzStartPage(int juzNumber);

  /// Gets a Juz synchronously from cache.
  ///
  /// Returns null if not cached. Call [ensureReady] first.
  JuzModel? getJuzSync(int number);

  /// Retrieves a complete Mushaf page with all content and layout data.
  ///
  /// [page] must be in the range 1-604.
  ///
  /// Returns a [QuranPageModel] containing:
  /// - The concatenated glyph text
  /// - Line layout information
  /// - Surah blocks with Ayah fragments
  /// - Juz number
  Future<QuranPageModel> getPage(int page);

  // ============================================================
  // Sync methods for cached data access
  // ============================================================

  /// Gets the page number for a specific Ayah.
  ///
  /// [ayahId] must be in the range 1-6236.
  ///
  /// Returns the page number (1-604) where the Ayah appears.
  Future<int> getPageForAyah(int ayahId);

  /// Gets the start page for a specific Surah.
  ///
  /// [surahNumber] must be in the range 1-114.
  ///
  /// Returns the page number (1-604) where the Surah begins.
  Future<int> getStartPageForSurah(int surahNumber);

  /// Retrieves a Surah by its number.
  ///
  /// [surahNumber] must be in the range 1-114.
  ///
  /// Returns null if the Surah is not found.
  Future<SurahModel?> getSurah(int surahNumber);

  /// Gets all Surahs synchronously from cache.
  ///
  /// Returns empty list if not cached. Call [ensureReady] first.
  List<SurahModel> getSurahsSync();
}
