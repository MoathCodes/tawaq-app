// Independent controller fixtures do not read persisted user settings.
// ignore_for_file: riverpod_lint/scoped_providers_should_specify_dependencies
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_screen_settings_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/recitation_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/quran_reading_shortcuts.dart';

class _Controller extends Mock implements MushafReaderController {}

class _Selection extends QuranSelectedAyahId {
  @override
  int? build() => 10;
}

Ayah _ayah(int id) => Ayah(
  ayahId: id,
  juz: 1,
  page: 1,
  surahNumber: 2,
  numberInSurah: id,
  text: '',
  textPlain: 'Fixture $id',
);

void main() {
  late _Controller controller;
  late ProviderContainer container;
  setUp(() {
    controller = _Controller();
    when(() => controller.currentPage).thenReturn(10);
    when(() => controller.pagesPerViewport).thenReturn(2);
    when(() => controller.animateToPage(any())).thenAnswer((_) async {});
    when(() => controller.getAyah(any())).thenAnswer(
      (invocation) async => _ayah(invocation.positionalArguments.first as int),
    );
    when(() => controller.jumpToAyah(any(), select: true))
        .thenAnswer((_) async {});
    container = ProviderContainer(
      overrides: [
        quranMushafControllerProvider.overrideWithValue(controller),
        quranSelectedAyahIdProvider.overrideWith(_Selection.new),
      ],
    );
  });
  tearDown(() => container.dispose());
  Widget host(Widget child) => UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      home: Scaffold(body: QuranReadingShortcuts(child: child)),
    ),
  );

  testWidgets(
    'arrows and Space turn a full spread even with a focused button',
    (tester) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      var activated = 0;
      await tester.pumpWidget(
        host(
          TextButton(
            focusNode: focus,
            onPressed: () => activated++,
            child: const Text('Fixture action'),
          ),
        ),
      );
      await tester.pump();
      focus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      verify(() => controller.animateToPage(12)).called(2);
      verify(() => controller.animateToPage(8)).called(1);
      expect(activated, 0);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(activated, 1);
    },
  );
  testWidgets('root focus fallback keeps current reader navigation available', (
    tester,
  ) async {
    await tester.pumpWidget(host(const SizedBox()));
    await tester.pump();
    FocusManager.instance.rootScope.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    verify(() => controller.animateToPage(12)).called(1);
  });
  testWidgets('readonly prose keeps Up and Down for ayah selection', (
    tester,
  ) async {
    await tester.pumpWidget(host(const SelectableText('Fixture prose')));
    await tester.tap(find.text('Fixture prose'));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(container.read(quranSelectedAyahIdProvider), 11);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(container.read(quranSelectedAyahIdProvider), 10);
  });
  testWidgets('editable search and portal focus scopes keep their own keys', (
    tester,
  ) async {
    final text = TextEditingController(text: 'Fixture');
    addTearDown(text.dispose);
    await tester.pumpWidget(host(TextField(controller: text)));
    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    verifyNever(() => controller.animateToPage(any()));
    verifyNever(() => controller.getAyah(any()));
    await tester.enterText(find.byType(TextField), 'Fixture search');
    expect(text.text, 'Fixture search');
    final portalFocus = FocusNode();
    addTearDown(portalFocus.dispose);
    await tester.pumpWidget(
      host(
        FocusScope(
          child: Focus(
            focusNode: portalFocus,
            child: const Text('Fixture portal'),
          ),
        ),
      ),
    );
    portalFocus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    verifyNever(() => controller.animateToPage(any()));
  });
  testWidgets('drawer pauses reading shortcuts and disposal removes handler', (
    tester,
  ) async {
    await tester.pumpWidget(host(const SizedBox()));
    await tester.pump();
    container.read(recitationDrawerProvider.notifier).open();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    verifyNever(() => controller.animateToPage(any()));
    container.read(recitationDrawerProvider.notifier).close();
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    verifyNever(() => controller.animateToPage(any()));
    expect(tester.takeException(), isNull);
  });
  testWidgets('late ayah load cannot overwrite a newer page or selection', (
    tester,
  ) async {
    final gate = Completer<Ayah>();
    when(() => controller.getAyah(11)).thenAnswer((_) => gate.future);
    await tester.pumpWidget(host(const SizedBox()));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    container.read(quranSelectedAyahIdProvider.notifier).select(20);
    when(() => controller.currentPage).thenReturn(12);
    gate.complete(_ayah(11));
    await tester.pump();
    expect(container.read(quranSelectedAyahIdProvider), 20);
    verifyNever(() => controller.jumpToAyah(any(), select: true));
  });
}
