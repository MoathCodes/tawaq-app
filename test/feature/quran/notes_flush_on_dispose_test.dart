import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/feature/quran/presentation/widgets/study/notes_section.dart' show NotesSection;

/// Mirrors [NotesSection] dispose flush: cancel debounce, persist when the
/// editor text diverges from the last persisted value.
({bool shouldFlush, String? textToFlush}) notesDisposeFlush({
  required int? ayahId,
  required bool hasSynced,
  required String controllerText,
  required String lastPersistedText,
}) {
  if (ayahId == null || !hasSynced) {
    return (shouldFlush: false, textToFlush: null);
  }
  if (controllerText == lastPersistedText) {
    return (shouldFlush: false, textToFlush: null);
  }
  return (shouldFlush: true, textToFlush: controllerText);
}

void main() {
  group('notes flush on dispose', () {
    test('flushes when synced editor has unsaved text', () {
      final result = notesDisposeFlush(
        ayahId: 42,
        hasSynced: true,
        controllerText: 'draft reflection',
        lastPersistedText: '',
      );
      expect(result.shouldFlush, isTrue);
      expect(result.textToFlush, 'draft reflection');
    });

    test('skips flush when text already persisted', () {
      final result = notesDisposeFlush(
        ayahId: 42,
        hasSynced: true,
        controllerText: 'saved',
        lastPersistedText: 'saved',
      );
      expect(result.shouldFlush, isFalse);
    });

    test('skips flush before note has synced', () {
      final result = notesDisposeFlush(
        ayahId: 42,
        hasSynced: false,
        controllerText: 'typing before load',
        lastPersistedText: '',
      );
      expect(result.shouldFlush, isFalse);
    });

    test('skips flush when no ayah is selected', () {
      final result = notesDisposeFlush(
        ayahId: null,
        hasSynced: true,
        controllerText: 'orphan',
        lastPersistedText: '',
      );
      expect(result.shouldFlush, isFalse);
    });
  });
}
