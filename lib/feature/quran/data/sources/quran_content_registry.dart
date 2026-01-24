import 'package:hasanat/feature/quran/domain/models/tafsir_source.dart';
import 'package:hasanat/feature/quran/domain/models/translation_source.dart';

/// Central registry for available Quran translation and tafsir sources.
///
/// To add a new translation or tafsir:
/// 1. Place the SQLite database file in `assets/database/`
/// 2. Add a new enum value to [TranslationId] or [TafsirId]
class QuranContentRegistry {
  QuranContentRegistry._();

  /// All available translation sources.
  static List<TranslationId> get translations => TranslationId.values;

  /// All available tafsir sources.
  static List<TafsirId> get tafsirs => TafsirId.values;

  /// Default translation source.
  static TranslationId get defaultTranslation =>
      TranslationId.saheehInternational;

  /// Default tafsir source.
  static TafsirId get defaultTafsir => TafsirId.tafseerMouaser;
}
