import 'package:tawaq/feature/quran/domain/models/tafsir_source.dart';
import 'package:tawaq/feature/quran/domain/models/translation_source.dart';

/// Central registry for available Quran translation and tafsir sources.
///
/// To add a new translation or tafsir:
/// 1. Place the SQLite database file in `assets/database/`
/// 2. Run `dart run build_runner build` to regenerate `assets.gen.dart`
/// 3. Add a new enum value to [TranslationId] or [TafsirId]
/// 4. Add a switch arm in [TranslationId.databasePath] or
///    [TafsirDatabasePaths.databasePath] referencing the new `Assets.database.*`
///    getter
/// 5. Set [TranslationId.fontFamily] for the new source (or `null` for theme default)
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
