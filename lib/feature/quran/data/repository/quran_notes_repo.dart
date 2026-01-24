import 'package:hasanat/core/logging/logger_provider.dart';
import 'package:hasanat/feature/quran/data/sources/quran_notes.dart';
import 'package:logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'quran_notes_repo.g.dart';

/// Provides a [QuranNotesRepo] instance for managing Quran notes.
@riverpod
QuranNotesRepo quranNotesRepo(Ref ref) {
  final notes = ref.read(quranNotesProvider);
  final log = ref.read(loggerProvider);
  return QuranNotesRepo(notes, log);
}

/// Repository for managing Quran ayah notes.
class QuranNotesRepo {
  /// Creates a [QuranNotesRepo] instance.
  const QuranNotesRepo(this._quranNotes, this._log);
  final QuranNotes _quranNotes;
  final Logger _log;

  /// Adds or updates a note for the given ayah.
  Future<void> addNote(int ayahId, String note) async {
    const logPrefix = '[QuranNotesRepo.addNote] ';
    try {
      _log.d('$logPrefix Adding note for ayahId: $ayahId');
      await _quranNotes.addNote(ayahId, note);
    } catch (e, stackTrace) {
      _log.e('$logPrefix Error', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Retrieves the note for the given ayah, if any.
  Future<String?> getNote(int ayahId) async {
    const logPrefix = '[QuranNotesRepo.getNote] ';
    try {
      _log.d('$logPrefix Fetching note for ayahId: $ayahId');
      return _quranNotes.getNote(ayahId);
    } catch (e, stackTrace) {
      _log.e('$logPrefix Error', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Deletes the note for the given ayah.
  Future<void> deleteNote(int ayahId) async {
    const logPrefix = '[QuranNotesRepo.deleteNote] ';
    try {
      _log.d('$logPrefix Deleting note for ayahId: $ayahId');
      await _quranNotes.deleteNote(ayahId);
    } catch (e, stackTrace) {
      _log.e('$logPrefix Error', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
