import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tawaq/feature/quran/data/models/quran_note.dart';
import 'package:tawaq/feature/quran/data/sources/quran_notes.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_notes_provider.dart';

class _MockQuranNotes extends Mock implements QuranNotes {}

void main() {
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
      persisted[ayahId] = QuranNote(
        text: text,
        createdAt: now,
        updatedAt: now,
      );
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
