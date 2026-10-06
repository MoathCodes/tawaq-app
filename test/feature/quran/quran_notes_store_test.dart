import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tawaq/feature/quran/data/models/quran_note.dart';
import 'package:tawaq/feature/quran/data/sources/quran_notes.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_notes_provider.dart';

class _MockQuranNotes extends Mock implements QuranNotes {}

void main() {
  test(
    'quit flush includes edits made while an earlier write is waiting',
    () async {
      final source = _MockQuranNotes();
      final gate = Completer<void>();
      final writes = <String>[];
      final persisted = <int, QuranNote>{};
      when(source.getAllNotes).thenAnswer((_) async => Map.of(persisted));
      when(() => source.addNote(any(), any())).thenAnswer((call) async {
        writes.add(call.positionalArguments[1] as String);
        if (writes.length == 1) await gate.future;
        persisted[1] = QuranNote(
          text: writes.last,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        );
      });
      final container = ProviderContainer(
        overrides: [quranNotesSourceProvider.overrideWithValue(source)],
      );
      addTearDown(container.dispose);
      await container.read(quranNotesStoreProvider.future);
      final owner = container.read(quranNotesStoreProvider.notifier);
      owner.edit(1, 'before quit');
      final quit = owner.flush();
      await Future<void>.delayed(Duration.zero);
      owner.edit(1, 'latest draft');
      gate.complete();
      await quit;
      expect(writes, ['before quit', 'latest draft']);
      expect(
        container.read(quranNotesStoreProvider).requireValue[1]!.text,
        'latest draft',
      );
    },
  );
  test('save status waits for acknowledged storage; failure retains draft and retry succeeds', () async {
    final source = _MockQuranNotes();
    final gate = Completer<void>();
    final persisted = <int, QuranNote>{};
    var fail = true;
    when(source.getAllNotes).thenAnswer((_) async => Map.of(persisted));
    when(() => source.addNote(any(), any())).thenAnswer((invocation) async {
      await gate.future;
      if (fail) throw StateError('disk full');
      final id = invocation.positionalArguments[0] as int;
      final text = invocation.positionalArguments[1] as String;
      persisted[id] = QuranNote(
        text: text,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
    });
    final container = ProviderContainer(
      overrides: [quranNotesSourceProvider.overrideWithValue(source)],
    );
    addTearDown(container.dispose);
    await container.read(quranNotesStoreProvider.future);
    final store = container.read(quranNotesStoreProvider.notifier);
    final beforeDraft = container
        .read(quranNotesStoreProvider)
        .requireValue
        .persisted;
    store.edit(42, 'retained draft');
    expect(
      identical(
        beforeDraft,
        container.read(quranNotesStoreProvider).requireValue.persisted,
      ),
      isTrue,
    );
    final operation = store.flushAyah(42);
    final assertion = expectLater(operation, throwsStateError);
    await Future<void>.delayed(Duration.zero);
    expect(
      container.read(quranNotesStoreProvider).requireValue.drafts[42]!.status,
      QuranNoteSaveStatus.saving,
    );
    expect(container.read(quranNotesStoreProvider).requireValue[42], isNull);
    gate.complete();
    await assertion;
    expect(
      container.read(quranNotesStoreProvider).requireValue.drafts[42]!.text,
      'retained draft',
    );
    expect(
      container.read(quranNotesStoreProvider).requireValue.drafts[42]!.status,
      QuranNoteSaveStatus.failed,
    );
    fail = false;
    await store.flush();
    expect(
      container.read(quranNotesStoreProvider).requireValue[42]!.text,
      'retained draft',
    );
    expect(
      container.read(quranNotesStoreProvider).requireValue.drafts[42]!.status,
      QuranNoteSaveStatus.saved,
    );
  });

  test('a newer edit remains pending when an older write completes', () async {
    final source = _MockQuranNotes();
    final gate = Completer<void>();
    final persisted = <int, QuranNote>{};
    var writes = 0;
    when(source.getAllNotes).thenAnswer((_) async => Map.of(persisted));
    when(() => source.addNote(any(), any())).thenAnswer((invocation) async {
      if (++writes == 1) await gate.future;
      final text = invocation.positionalArguments[1] as String;
      persisted[1] = QuranNote(
        text: text,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
    });
    final container = ProviderContainer(
      overrides: [quranNotesSourceProvider.overrideWithValue(source)],
    );
    addTearDown(container.dispose);
    await container.read(quranNotesStoreProvider.future);
    final store = container.read(quranNotesStoreProvider.notifier);
    final first = store.save(1, 'old');
    store.edit(1, 'new');
    gate.complete();
    await first;
    expect(
      container.read(quranNotesStoreProvider).requireValue.drafts[1]!.text,
      'new',
    );
    expect(
      container.read(quranNotesStoreProvider).requireValue.drafts[1]!.status,
      QuranNoteSaveStatus.pending,
    );
    await store.flush();
    expect(
      container.read(quranNotesStoreProvider).requireValue[1]!.text,
      'new',
    );
  });

  test('concurrent saves publish the complete persisted collection', () async {
    final source = _MockQuranNotes();
    final firstWrite = Completer<void>();
    final persisted = <int, QuranNote>{};
    var writeCount = 0;

    when(source.getAllNotes).thenAnswer((_) async => Map.of(persisted));
    when(() => source.addNote(any(), any())).thenAnswer((invocation) async {
      writeCount++;
      if (writeCount == 1) await firstWrite.future;
      final ayahId = invocation.positionalArguments[0] as int;
      final text = invocation.positionalArguments[1] as String;
      final now = DateTime(2026);
      persisted[ayahId] = QuranNote(text: text, createdAt: now, updatedAt: now);
    });

    final container = ProviderContainer(
      overrides: [quranNotesSourceProvider.overrideWithValue(source)],
    );
    addTearDown(container.dispose);
    await container.read(quranNotesStoreProvider.future);

    final first = container.read(quranNotesStoreProvider.notifier).save(1, 'a');
    final second = container
        .read(quranNotesStoreProvider.notifier)
        .save(2, 'b');
    await Future<void>.delayed(Duration.zero);

    expect(writeCount, 1, reason: 'the second write must wait for the first');
    firstWrite.complete();
    await Future.wait([first, second]);

    expect(container.read(quranNotesStoreProvider).requireValue.keys, {1, 2});
  });
}
