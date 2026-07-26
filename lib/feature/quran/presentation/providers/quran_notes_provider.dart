import 'package:logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/logging/logger_provider.dart';
import 'package:tawaq/feature/quran/data/sources/quran_notes.dart';

part 'quran_notes_provider.g.dart';

/// Provider for managing Quran notes for a specific ayah.
///
/// Pass in the ayahId to get/set the note for that ayah.
/// When ayahId is null, returns null and operations are no-ops.
@riverpod
class QuranNotesNotifier extends _$QuranNotesNotifier {
  late final Logger _log;
  int? _ayahId;

  @override
  FutureOr<String?> build(int? ayahId) async {
    _log = ref.read(loggerProvider);
    _ayahId = ayahId;
    const logPrefix = '[QuranNotesNotifier.build] ';

    if (ayahId == null) {
      _log.d('$logPrefix No ayahId provided');
      return null;
    }

    _log.d('$logPrefix Loading note for ayahId: $ayahId');
    final note = await ref.read(quranNotesSourceProvider).getNote(ayahId);
    if (!ref.mounted) return null;
    return note;
  }

  /// Adds or updates a note for the current ayah.
  Future<void> addNote(String note) async {
    const logPrefix = '[QuranNotesNotifier.addNote] ';
    final ayahId = _ayahId;

    if (ayahId == null) {
      _log.w('$logPrefix No ayahId set, cannot add note');
      return;
    }

    try {
      _log.d('$logPrefix Adding note for ayahId: $ayahId');
      await ref.read(quranNotesSourceProvider).addNote(ayahId, note);
      if (!ref.mounted) return;
      state = AsyncData(note);
      _log.d('$logPrefix Note added successfully');
    } catch (e, stackTrace) {
      if (!ref.mounted) return;
      _log.e('$logPrefix Error', error: e, stackTrace: stackTrace);
      state = AsyncError(e, stackTrace);
    }
  }

  /// Deletes the note for the current ayah.
  Future<void> deleteNote() async {
    const logPrefix = '[QuranNotesNotifier.deleteNote] ';
    final ayahId = _ayahId;

    if (ayahId == null) {
      _log.w('$logPrefix No ayahId set, cannot delete note');
      return;
    }

    try {
      _log.d('$logPrefix Deleting note for ayahId: $ayahId');
      await ref.read(quranNotesSourceProvider).deleteNote(ayahId);
      if (!ref.mounted) return;
      state = const AsyncData(null);
      _log.d('$logPrefix Note deleted successfully');
    } catch (e, stackTrace) {
      if (!ref.mounted) return;
      _log.e('$logPrefix Error', error: e, stackTrace: stackTrace);
      state = AsyncError(e, stackTrace);
    }
  }
}
