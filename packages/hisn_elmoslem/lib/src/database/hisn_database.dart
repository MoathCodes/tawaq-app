import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

import '../utils/database_path.dart';

/// Bundled SQLite database names.
abstract final class HisnDatabaseNames {
  /// Main Hisn al-Muslim content database.
  static const hisn = 'hisn_elmoslem.db';

  /// Commentary / sharh database.
  static const commentary = 'commentary.db';

  /// Known weak or fabricated hadith warnings.
  static const fakeHadith = 'fake_hadith.db';

  /// Uthmani Quranic text for resolving [QuranText] placeholders.
  static const uthmani = 'quran.ar.uthmani.v2.db';
}

/// Opens read-only SQLite databases bundled with the package.
final class HisnDatabase {
  HisnDatabase._({
    required Database hisn,
    required Database commentary,
    required Database fakeHadith,
    required Database uthmani,
  })  : hisn = hisn,
        commentary = commentary,
        fakeHadith = fakeHadith,
        uthmani = uthmani;

  /// Main content database (`titles`, `contents`).
  final Database hisn;

  /// Commentary database.
  final Database commentary;

  /// Fake hadith database.
  final Database fakeHadith;

  /// Uthmani Quran text database.
  final Database uthmani;

  /// Opens all bundled databases from the package asset layout.
  static Future<HisnDatabase> open() async {
    final directory = await resolveDatabaseDirectory();
    return openFromDirectory(directory);
  }

  /// Opens databases from [directory] containing the bundled `.db` files.
  static Future<HisnDatabase> openFromDirectory(String directory) async {
    final hisnPath = p.join(directory, HisnDatabaseNames.hisn);
    final commentaryPath = p.join(directory, HisnDatabaseNames.commentary);
    final fakeHadithPath = p.join(directory, HisnDatabaseNames.fakeHadith);
    final uthmaniPath = p.join(directory, HisnDatabaseNames.uthmani);

    return HisnDatabase._(
      hisn: sqlite3.open(hisnPath, mode: OpenMode.readOnly),
      commentary: sqlite3.open(commentaryPath, mode: OpenMode.readOnly),
      fakeHadith: sqlite3.open(fakeHadithPath, mode: OpenMode.readOnly),
      uthmani: sqlite3.open(uthmaniPath, mode: OpenMode.readOnly),
    );
  }

  /// Opens all bundled databases (legacy alias).
  static Future<HisnDatabase> openFromPaths({
    required String hisnPath,
    required String commentaryPath,
    required String fakeHadithPath,
    required String uthmaniPath,
  }) async {
    return HisnDatabase._(
      hisn: sqlite3.open(hisnPath, mode: OpenMode.readOnly),
      commentary: sqlite3.open(commentaryPath, mode: OpenMode.readOnly),
      fakeHadith: sqlite3.open(fakeHadithPath, mode: OpenMode.readOnly),
      uthmani: sqlite3.open(uthmaniPath, mode: OpenMode.readOnly),
    );
  }

  /// Closes all open database handles.
  void close() {
    hisn.close();
    commentary.close();
    fakeHadith.close();
    uthmani.close();
  }
}
