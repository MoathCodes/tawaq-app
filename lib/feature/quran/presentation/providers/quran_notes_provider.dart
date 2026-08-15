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

/// The only writable runtime authority for the persisted Quran-note collection.
@Riverpod(keepAlive: true)
class QuranNotesStore extends _$QuranNotesStore {
  late final Logger _log;
  Future<void> _writeTail = Future<void>.value();

  @override
  Future<Map<int, QuranNote>> build() async {
    _log = ref.read(loggerProvider);
    return ref.read(quranNotesSourceProvider).getAllNotes();
  }

  /// Saves [text] for [ayahId], publishing only after Hive succeeds.
  Future<void> save(int ayahId, String text) => _serialize(() async {
    const logPrefix = '[QuranNotesStore.save] ';
    try {
      final source = ref.read(quranNotesSourceProvider);
      await source.addNote(ayahId, text);
      if (!ref.mounted) return;
      final persisted = await source.getAllNotes();
      if (!ref.mounted) return;
      state = AsyncData(Map.unmodifiable(persisted));
    } catch (e, stackTrace) {
      _log.e('$logPrefix Error', error: e, stackTrace: stackTrace);
      rethrow;
    }
  });

  /// Deletes [ayahId], publishing only after Hive succeeds.
  Future<void> delete(int ayahId) => _serialize(() async {
    const logPrefix = '[QuranNotesStore.delete] ';
    try {
      final source = ref.read(quranNotesSourceProvider);
      await source.deleteNote(ayahId);
      if (!ref.mounted) return;
      final persisted = await source.getAllNotes();
      if (!ref.mounted) return;
      state = AsyncData(Map.unmodifiable(persisted));
    } catch (e, stackTrace) {
      _log.e('$logPrefix Error', error: e, stackTrace: stackTrace);
      rethrow;
    }
  });

  Future<void> _serialize(Future<void> Function() operation) {
    final next = _writeTail.then((_) => operation());
    _writeTail = next.then<void>((_) {}, onError: (_, _) {});
    return next;
  }
}

/// All saved Quran notes with ayah previews, sorted by ayah id.
@riverpod
Future<List<QuranNoteEntry>> quranAllNotes(Ref ref) async {
  final notes = await ref.watch(quranNotesStoreProvider.future);
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
