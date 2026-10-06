import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tawaq/feature/quran/data/models/quran_note.dart';
import 'package:tawaq/feature/quran/data/sources/quran_notes.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_notes_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/study/notes_section.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/l10n/app_localizations_delegates.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

class _Source extends Mock implements QuranNotes {}

Widget _wrap(ProviderContainer container, Widget child) =>
    UncontrolledProviderScope(
      container: container,
      child: FTheme(
        data: buildAppTheme(
          palette: AppPalette.manuscript,
          themeMode: ThemeMode.light,
          touch: false,
          textScale: 1,
        ),
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: appLocalizationsDelegates,
          home: Scaffold(body: child),
        ),
      ),
    );

void main() {
  testWidgets(
    'leaving the real editor flushes immediately and failed drafts reopen for retry',
    (tester) async {
      final source = _Source();
      final persisted = <int, QuranNote>{};
      final acknowledged = Completer<void>();
      final writeStarted = Completer<void>();
      var fail = true;
      when(source.getAllNotes).thenAnswer((_) async => Map.of(persisted));
      when(() => source.addNote(any(), any())).thenAnswer((invocation) async {
        if (!writeStarted.isCompleted) writeStarted.complete();
        await acknowledged.future;
        if (fail) throw StateError('injected disk failure');
        persisted[invocation.positionalArguments[0] as int] = QuranNote(
          text: invocation.positionalArguments[1] as String,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        );
      });
      final container = ProviderContainer(
        overrides: [quranNotesSourceProvider.overrideWithValue(source)],
      );
      addTearDown(container.dispose);
      await container.read(quranNotesStoreProvider.future);
      await tester.pumpWidget(
        _wrap(container, const NotesSection(ayahId: 42, narrowPanel: true)),
      );
      await tester.pump();
      await tester.enterText(find.byType(EditableText), 'draft on leaving');
      expect(container.read(quranNotesStoreProvider).requireValue.drafts[42]?.text, 'draft on leaving');
      await tester.pump();
      // No debounce advance: the production dispose hook must flush this draft.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(writeStarted.isCompleted, isTrue);
      acknowledged.complete();
      await tester.pump();
      await tester.pump();
      expect(
        container.read(quranNotesStoreProvider).requireValue.drafts[42]!.status,
        QuranNoteSaveStatus.failed,
      );
      await tester.pumpWidget(
        _wrap(container, const NotesSection(ayahId: 42, narrowPanel: true)),
      );
      await tester.pump();
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        'draft on leaving',
      );
      expect(find.text('Retry'), findsOneWidget);
      fail = false;
      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pump();
      expect(persisted[42]!.text, 'draft on leaving');
      expect(
        container.read(quranNotesStoreProvider).requireValue.drafts[42]!.status,
        QuranNoteSaveStatus.saved,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 150));
    },
  );
}
