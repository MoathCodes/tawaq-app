import 'package:hasanat/feature/quran/data/repository/translation_repository.dart';
import 'package:hasanat/feature/quran/data/sources/quran_content_registry.dart';
import 'package:hasanat/feature/quran/domain/models/translation.dart';
import 'package:hasanat/feature/quran/domain/models/translation_source.dart';

/// Service layer for translation-related business logic.
///
/// Acts as an intermediary between providers and the repository,
/// providing a clean API for the presentation layer.
class TranslationService {
  /// Creates a translation service.
  TranslationService(this._repository);

  final TranslationRepository _repository;

  /// Gets a translation for a specific ayah from the given source.
  Future<Translation?> getTranslation(
    TranslationId source,
    int sura,
    int aya,
  ) async {
    return _repository.getTranslation(source, sura, aya);
  }

  /// Gets all translations for a surah from the given source.
  Future<List<Translation>> getTranslationsForSura(
    TranslationId source,
    int sura,
  ) async {
    return _repository.getTranslationsForSura(source, sura);
  }

  /// Returns the list of available translation sources.
  List<TranslationId> getAvailableSources() {
    return QuranContentRegistry.translations;
  }

  /// Returns the default translation source.
  TranslationId get defaultSource => QuranContentRegistry.defaultTranslation;
}
