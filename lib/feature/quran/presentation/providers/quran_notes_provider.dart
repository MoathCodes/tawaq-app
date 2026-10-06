import 'dart:async';
import 'dart:collection';

import 'package:logger/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  const new({
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

/// Status of the actual reflection write, including retained failed drafts.
enum QuranNoteSaveStatus { pending, saving, saved, failed }

/// An editor draft owned by the notes store until its write succeeds.
class QuranNoteDraft {
  const new(this.text, this.status);
  final String text;
  final QuranNoteSaveStatus status;
}

/// Persisted notes and transient write state share one runtime owner.
class QuranNotesState extends MapBase<int, QuranNote> {
  QuranNotesState(
    Map<int, QuranNote> notes, [
    Map<int, QuranNoteDraft> drafts = const {},
  ]) : _notes = notes is QuranNotesState
           ? notes._notes
           : Map.unmodifiable(notes),
       drafts = Map.unmodifiable(drafts);
  final Map<int, QuranNote> _notes;

  /// Identity changes only when the persisted collection changes.
  Map<int, QuranNote> get persisted => _notes;
  final Map<int, QuranNoteDraft> drafts;
  @override
  QuranNote? operator [](Object? key) => _notes[key];
  @override
  Iterable<int> get keys => _notes.keys;
  @override
  void operator []=(int key, QuranNote value) =>
      throw UnsupportedError('Immutable notes');
  @override
  void clear() => throw UnsupportedError('Immutable notes');
  @override
  QuranNote? remove(Object? key) => throw UnsupportedError('Immutable notes');
}

/// The only writable runtime authority for Quran notes and their drafts.
@Riverpod(keepAlive: true)
class QuranNotesStore extends _$QuranNotesStore {
  late final Logger _log;
  Future<void> _writeTail = Future<void>.value();
  final _debounces = <int, Timer>{};

  @override
  Future<QuranNotesState> build() async {
    _log = ref.read(loggerProvider);
    ref.onDispose(() {
      for (final timer in _debounces.values) {
        timer.cancel();
      }
    });
    return QuranNotesState(
      await ref.read(quranNotesSourceProvider).getAllNotes(),
    );
  }

  /// Retains a draft immediately; the debounce only schedules the write.
  void edit(int ayahId, String text) {
    final current = state.requireValue;
    final draft = QuranNoteDraft(text, QuranNoteSaveStatus.pending);
    state = AsyncData(
      QuranNotesState(current, {...current.drafts, ayahId: draft}),
    );
    _debounces.remove(ayahId)?.cancel();
    _debounces[ayahId] = Timer(const Duration(milliseconds: 500), () {
      _debounces.remove(ayahId);
      unawaited(flushAyah(ayahId).catchError((Object _) {}));
    });
  }

  /// Flushes an editor before leaving; failures remain visible on reopening.
  Future<void> flushAyah(int ayahId) async {
    _debounces.remove(ayahId)?.cancel();
    final draft = state.value?.drafts[ayahId];
    if (draft != null && draft.status != QuranNoteSaveStatus.saved) {
      await save(ayahId, draft.text);
    }
  }

  /// A quit boundary waits for all pending drafts and acknowledged writes.
  Future<void> flush() async {
    await future;
    // Edits arriving during an acknowledged write also belong to this quit
    // boundary. Do not close over a single, potentially stale draft snapshot.
    while (true) {
      final pending = state.requireValue.drafts.entries
          .where((entry) => entry.value.status != QuranNoteSaveStatus.saved)
          .map((entry) => entry.key)
          .toList();
      if (pending.isEmpty) break;
      for (final id in pending) {
        await flushAyah(id);
      }
    }
    await _writeTail;
  }

  /// Publishes saved status only after the source's durable operation succeeds.
  Future<void> save(int ayahId, String text) {
    _debounces.remove(ayahId)?.cancel();
    final current = state.requireValue;
    final draft = QuranNoteDraft(text, QuranNoteSaveStatus.saving);
    state = AsyncData(
      QuranNotesState(current, {...current.drafts, ayahId: draft}),
    );
    return _serialize(() async {
      try {
        final source = ref.read(quranNotesSourceProvider);
        await source.addNote(ayahId, text);
        final persisted = await source.getAllNotes();
        if (!ref.mounted) return;
        final latest = state.requireValue;
        final drafts = Map.of(latest.drafts);
        if (identical(drafts[ayahId], draft)) {
          drafts[ayahId] = QuranNoteDraft(text, QuranNoteSaveStatus.saved);
        }
        state = AsyncData(QuranNotesState(persisted, drafts));
      } catch (error, stack) {
        _log.e(
          '[QuranNotesStore.save] Failed',
          error: error,
          stackTrace: stack,
        );
        if (ref.mounted) {
          final latest = state.requireValue;
          if (identical(latest.drafts[ayahId], draft)) {
            state = AsyncData(
              QuranNotesState(latest, {
                ...latest.drafts,
                ayahId: QuranNoteDraft(text, QuranNoteSaveStatus.failed),
              }),
            );
          }
        }
        rethrow;
      }
    });
  }

  /// Deletes only after the durable operation succeeds.
  Future<void> delete(int ayahId) => _serialize(() async {
    final source = ref.read(quranNotesSourceProvider);
    await source.deleteNote(ayahId);
    final persisted = await source.getAllNotes();
    if (!ref.mounted) return;
    _debounces.remove(ayahId)?.cancel();
    final drafts = Map.of(state.requireValue.drafts)..remove(ayahId);
    state = AsyncData(QuranNotesState(persisted, drafts));
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
  final notes = ref.watch(
    quranNotesStoreProvider.select((value) => value.value?.persisted),
  );
  if (notes == null) {
    await ref.watch(quranNotesStoreProvider.future);
    // Hydration publishes a persisted collection and invalidates this build.
    return const [];
  }
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
