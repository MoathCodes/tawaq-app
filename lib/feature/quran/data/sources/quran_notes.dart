import 'package:hivez_flutter/hivez_flutter.dart';
import 'package:logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/logging/logger_provider.dart';
import 'package:tawaq/feature/quran/data/models/quran_note.dart';

part 'quran_notes.g.dart';

/// Provides a [QuranNotes] data source for storing ayah notes.
@Riverpod(keepAlive: true)
QuranNotes quranNotesSource(Ref ref) {
  final box = Box<int, QuranNote>('quran_ayah_notes');
  final log = ref.read(loggerProvider);
  ref.onDispose(() async {
    await box.closeBox();
  });
  return QuranNotes(box, log);
}

/// Data source for storing and retrieving Quran ayah notes.
class QuranNotes {
  /// Creates a [QuranNotes] instance.
  const new(this._box, this._log);
  final Box<int, QuranNote> _box;
  final Logger _log;

  /// Adds or updates a note for the given ayah.
  ///
  /// Empty/whitespace [text] deletes the note instead of storing a blank entry.
  /// Existing [QuranNote.createdAt] is preserved; [QuranNote.updatedAt] is
  /// bumped on every write.
  Future<void> addNote(int ayahId, String text) async {
    const logPrefix = '[QuranNotes.addNote] ';
    try {
      if (text.trim().isEmpty) {
        _log.d('$logPrefix Empty text — deleting note for ayahId: $ayahId');
        await deleteNote(ayahId);
        return;
      }

      _log.d('$logPrefix Adding note for ayahId: $ayahId');
      final existing = await _box.get(ayahId);
      final now = DateTime.now();
      final note = QuranNote(
        text: text,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      );
      await _box.put(ayahId, note);
      _log.d('$logPrefix Note saved successfully');
    } catch (e, stackTrace) {
      _log.e('$logPrefix Error', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Retrieves the note for the given ayah, if any.
  Future<QuranNote?> getNote(int ayahId) async {
    const logPrefix = '[QuranNotes.getNote] ';
    try {
      _log.d('$logPrefix Fetching note for ayahId: $ayahId');
      final note = await _box.get(ayahId);
      _log.d('$logPrefix Note ${note == null ? 'missing' : 'found'}');
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

  /// Returns every stored note keyed by global ayah id.
  Future<Map<int, QuranNote>> getAllNotes() async {
    const logPrefix = '[QuranNotes.getAllNotes] ';
    try {
      _log.d('$logPrefix Loading all notes');
      final keys = await _box.getAllKeys();
      final result = <int, QuranNote>{};
      for (final key in keys) {
        final note = await _box.get(key);
        if (note == null || note.text.trim().isEmpty) continue;
        result[key] = note;
      }
      _log.d('$logPrefix Loaded ${result.length} notes');
      return result;
    } catch (e, stackTrace) {
      _log.e('$logPrefix Error', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
