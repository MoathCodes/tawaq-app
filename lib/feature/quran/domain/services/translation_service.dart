import 'package:tawaq/feature/quran/data/models/translation.dart';
import 'package:tawaq/feature/quran/data/repository/translation_repository.dart';
import 'package:tawaq/feature/quran/data/sources/quran_content_registry.dart';
import 'package:tawaq/feature/quran/domain/models/translation_source.dart';

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
    final translation = await _repository.getTranslation(source, sura, aya);
    return translation?.withSourceMetadata(fontFamily: source.fontFamily);
  }

  /// Gets all translations for a surah from the given source.
  Future<List<Translation>> getTranslationsForSura(
    TranslationId source,
    int sura,
  ) async {
    final translations = await _repository.getTranslationsForSura(source, sura);
    return translations
        .map(
          (translation) => translation.withSourceMetadata(
            fontFamily: source.fontFamily,
          ),
        )
        .toList();
  }

  /// Returns the list of available translation sources.
  List<TranslationId> getAvailableSources() {
    return QuranContentRegistry.translations;
  }

  /// Returns the default translation source.
  TranslationId get defaultSource => QuranContentRegistry.defaultTranslation;
}
