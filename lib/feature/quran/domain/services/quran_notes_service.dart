import 'package:logger/logger.dart';
import 'package:tawaq/feature/quran/data/repository/quran_notes_repo.dart';

/// Service for managing Quran ayah notes.
class QuranNotesService {
  /// Creates a [QuranNotesService] instance.
  const QuranNotesService(this._repo, this._log);
  final QuranNotesRepo _repo;
  final Logger _log;

  /// Adds or updates a note for the given ayah.
  Future<void> addNote(int ayahId, String note) async {
    const logPrefix = '[QuranNotesService.addNote] ';
    try {
      _log.d('$logPrefix Adding note for ayahId: $ayahId');
      await _repo.addNote(ayahId, note);
    } catch (e, stackTrace) {
      _log.e('$logPrefix Error', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Retrieves the note for the given ayah, if any.
  Future<String?> getNote(int ayahId) async {
    const logPrefix = '[QuranNotesService.getNote] ';
    try {
      _log.d('$logPrefix Fetching note for ayahId: $ayahId');
      return _repo.getNote(ayahId);
    } catch (e, stackTrace) {
      _log.e('$logPrefix Error', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Deletes the note for the given ayah.
  Future<void> deleteNote(int ayahId) async {
    const logPrefix = '[QuranNotesService.deleteNote] ';
    try {
      _log.d('$logPrefix Deleting note for ayahId: $ayahId');
      await _repo.deleteNote(ayahId);
    } catch (e, stackTrace) {
      _log.e('$logPrefix Error', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
