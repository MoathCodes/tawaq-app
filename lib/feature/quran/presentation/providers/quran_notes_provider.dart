import 'package:logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/logging/logger_provider.dart';
import 'package:tawaq/feature/quran/data/models/quran_note.dart';
import 'package:tawaq/feature/quran/data/sources/quran_notes.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/ayah_search_result_item.dart';

part 'quran_notes_provider.g.dart';

/// A note plus ayah metadata for the reflections browser.
class QuranNoteEntry {
  /// Creates a [QuranNoteEntry].
  const QuranNoteEntry({
    required this.ayahId,
    required this.note,
    required this.ayahPreview,
    required this.surahNumber,
    required this.numberInSurah,
  });

  /// Global Mushaf ayah id (1–6236).
  final int ayahId;

  /// Persisted note payload.
  final QuranNote note;

  /// Short Uthmani/plain preview of the ayah text.
  final String ayahPreview;

  /// 1-based surah number.
  final int surahNumber;

  /// 1-based ayah number within the surah.
  final int numberInSurah;
}

/// Provider for managing Quran notes for a specific ayah.
///
/// Pass in the ayahId to get/set the note for that ayah.
/// When ayahId is null, returns null and operations are no-ops.
@riverpod
class QuranNotesNotifier extends _$QuranNotesNotifier {
  late final Logger _log;
  int? _ayahId;

  @override
  FutureOr<QuranNote?> build(int? ayahId) async {
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
  ///
  /// Empty/whitespace text deletes the note.
  Future<void> addNote(String note) async {
    const logPrefix = '[QuranNotesNotifier.addNote] ';
    final ayahId = _ayahId;

    if (ayahId == null) {
      _log.w('$logPrefix No ayahId set, cannot add note');
      return;
    }

    try {
      _log.d('$logPrefix Adding note for ayahId: $ayahId');
      final source = ref.read(quranNotesSourceProvider);
      await source.addNote(ayahId, note);
      if (!ref.mounted) return;
      if (note.trim().isEmpty) {
        state = const AsyncData(null);
      } else {
        state = AsyncData(await source.getNote(ayahId));
      }
      ref.invalidate(quranAllNotesProvider);
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
      ref.invalidate(quranAllNotesProvider);
      _log.d('$logPrefix Note deleted successfully');
    } catch (e, stackTrace) {
      if (!ref.mounted) return;
      _log.e('$logPrefix Error', error: e, stackTrace: stackTrace);
      state = AsyncError(e, stackTrace);
    }
  }
}

/// All saved Quran notes with ayah previews, sorted by ayah id.
@riverpod
Future<List<QuranNoteEntry>> quranAllNotes(Ref ref) async {
  final notes = await ref.watch(quranNotesSourceProvider).getAllNotes();
  if (notes.isEmpty) return const [];

  final controller = ref.watch(quranMushafControllerProvider);
  final ids = notes.keys.toList()..sort();
  final ayahs = await Future.wait(ids.map(controller.getAyah));

  return [
    for (var i = 0; i < ids.length; i++)
      QuranNoteEntry(
        ayahId: ids[i],
        note: notes[ids[i]]!,
        ayahPreview: ayahSearchPreviewText(ayahs[i]),
        surahNumber: ayahs[i].surahNumber,
        numberInSurah: ayahs[i].numberInSurah,
      ),
  ];
}
