import 'package:hasanat/feature/quran/data/repository/tafsir_repository.dart';
import 'package:hasanat/feature/quran/data/sources/quran_content_registry.dart';
import 'package:hasanat/feature/quran/domain/models/tafsir.dart';
import 'package:hasanat/feature/quran/domain/models/tafsir_source.dart';

/// Service layer for tafsir-related business logic.
///
/// Acts as an intermediary between providers and the repository,
/// providing a clean API for the presentation layer.
class TafsirService {
  /// Creates a tafsir service.
  TafsirService(this._repository);

  final TafsirRepository _repository;

  /// Gets a tafsir for a specific ayah from the given source.
  Future<Tafsir?> getTafsir(TafsirId source, int suraNo, int ayaNo) async {
    return _repository.getTafsir(source, suraNo, ayaNo);
  }

  /// Gets all tafsir entries for a surah from the given source.
  Future<List<Tafsir>> getTafsirForSura(TafsirId source, int suraNo) async {
    return _repository.getTafsirForSura(source, suraNo);
  }

  /// Returns the list of available tafsir sources.
  List<TafsirId> getAvailableSources() {
    return QuranContentRegistry.tafsirs;
  }

  /// Returns the default tafsir source.
  TafsirId get defaultSource => QuranContentRegistry.defaultTafsir;
}
