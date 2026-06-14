import 'package:tawaq/feature/quran/domain/models/tafsir_source.dart';
import 'package:tawaq/gen/assets.gen.dart';

/// Asset paths for bundled tafsir SQLite databases.
extension TafsirDatabasePaths on TafsirId {
  /// Asset path to the SQLite database file.
  String get databasePath {
    return switch (this) {
      TafsirId.tafseerMouaser => Assets.database.tafseerAr.tafseerMouaser,
      TafsirId.baghawi => Assets.database.tafseerAr.quraanBa,
      TafsirId.ibnKathir => Assets.database.tafseerAr.quraanIK,
      TafsirId.asSadi => Assets.database.tafseerAr.quraanAS,
    };
  }
}
