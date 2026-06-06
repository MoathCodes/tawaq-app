import 'package:hivez_flutter/hivez_flutter.dart';
import 'package:logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/logging/logger_provider.dart';

part 'quran_notes.g.dart';

/// Provides a [QuranNotes] data source for storing ayah notes.
@riverpod
QuranNotes quranNotesSource(Ref ref) {
  final box = Box<int, String>('quran_notes');
  final log = ref.read(loggerProvider);
  ref.onDispose(() async {
    await box.closeBox();
  });
  return QuranNotes(box, log);
}

/// Data source for storing and retrieving Quran ayah notes.
class QuranNotes {
  /// Creates a [QuranNotes] instance.
  const QuranNotes(this._box, this._log);
  final Box<int, String> _box;
  final Logger _log;

  /// Adds or updates a note for the given ayah.
  Future<void> addNote(int ayahId, String note) async {
    const logPrefix = '[QuranNotes.addNote] ';
    try {
      _log.d('$logPrefix Adding note for ayahId: $ayahId');
      await _box.put(ayahId, note);
      _log.d('$logPrefix Note saved successfully');
    } catch (e, stackTrace) {
      _log.e('$logPrefix Error', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Retrieves the note for the given ayah, if any.
  Future<String?> getNote(int ayahId) async {
    const logPrefix = '[QuranNotes.getNote] ';
    try {
      _log.d('$logPrefix Fetching note for ayahId: $ayahId');
      final note = _box.get(ayahId);
      _log.d('$logPrefix Note ${'found'}');
      return note;
    } catch (e, stackTrace) {
      _log.e('$logPrefix Error', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Deletes the note for the given ayah.
  Future<void> deleteNote(int ayahId) async {
    const logPrefix = '[QuranNotes.deleteNote] ';
    try {
      _log.d('$logPrefix Deleting note for ayahId: $ayahId');
      await _box.delete(ayahId);
      _log.d('$logPrefix Note deleted successfully');
    } catch (e, stackTrace) {
      _log.e('$logPrefix Error', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
