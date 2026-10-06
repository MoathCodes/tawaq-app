// Fixture overrides belong to an independent root test scope.
// ignore_for_file: riverpod_lint/scoped_providers_should_specify_dependencies

import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/feature/quran/data/models/quran_note.dart';
import 'package:tawaq/feature/quran/data/sources/quran_notes.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_notes_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/study/notes_browser.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/l10n/app_localizations_delegates.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

class _Source extends Mock implements QuranNotes {}

class _Controller extends Mock implements MushafReaderController {}

void main() {
  late _Source source;
  late Map<int, QuranNote> persisted;
  setUp(() {
    source = _Source();
    persisted = {
      1: QuranNote(
        text: 'My saved reflection',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    };
    when(source.getAllNotes).thenAnswer((_) async => Map.of(persisted));
  });

  Future<void> mount(WidgetTester tester, ProviderContainer container) async {
    final theme = buildAppTheme(
      palette: AppPalette.manuscript,
      themeMode: ThemeMode.light,
      touch: false,
      textScale: 1.2,
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: FTheme(
          data: theme,
          child: MaterialApp(
            locale: const Locale('en'),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.2)),
              child: child!,
            ),
            localizationsDelegates: appLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: FToaster(
              child: Scaffold(
                body: SizedBox(
                  width: 600,
                  height: 500,
                  child: const NotesBrowser(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  List<QuranNoteEntry> entries(Map<int, QuranNote> notes) => [
    for (final item in notes.entries)
      QuranNoteEntry(
        ayahId: item.key,
        note: item.value,
        ayahPreview: '',
        surahNumber: 1,
        numberInSurah: 1,
      ),
  ];

  testWidgets('failed reflection deletion stays visible and can be retried', (
    tester,
  ) async {
    var fail = true;
    when(() => source.deleteNote(1)).thenAnswer((_) async {
      if (fail) throw StateError('private disk diagnostic');
      persisted.remove(1);
    });
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        quranNotesSourceProvider.overrideWithValue(source),
        quranMushafControllerProvider.overrideWithValue(_Controller()),
        quranAllNotesProvider.overrideWith(
          (ref) async => entries(
            await ref
                .watch(quranNotesStoreProvider.future)
                .then((state) => state.persisted),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    await mount(tester, container);
    Future<void> delete() async {
      final button = find.byWidgetPredicate(
        (widget) =>
            widget is FButton && widget.semanticsLabel == 'Delete reflection',
      );
      await tester.tap(button);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete reflection').last);
      await tester.pumpAndSettle();
    }

    await delete();
    expect(find.text('My saved reflection'), findsOneWidget);
    expect(
      find.text('Could not delete this reflection. Try again.'),
      findsOneWidget,
    );
    expect(find.textContaining('private disk diagnostic'), findsNothing);
    fail = false;
    await delete();
    expect(find.text('My saved reflection'), findsNothing);
    expect(persisted, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  }, variant: const TargetPlatformVariant({TargetPlatform.linux}));

  testWidgets(
    'reflections loading failure offers retry without raw diagnostics',
    (tester) async {
      var fail = true;
      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          quranNotesSourceProvider.overrideWithValue(source),
          quranMushafControllerProvider.overrideWithValue(_Controller()),
          quranAllNotesProvider.overrideWith((ref) async {
            if (fail) throw StateError('private load diagnostic');
            return entries(persisted);
          }),
        ],
      );
      addTearDown(container.dispose);
      await mount(tester, container);
      expect(
        find.text('Could not load your reflections. Try again.'),
        findsOneWidget,
      );
      expect(find.textContaining('private load diagnostic'), findsNothing);
      fail = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('My saved reflection'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
