import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/feature/quran/data/models/translation.dart';
import 'package:tawaq/feature/quran/domain/models/translation_source.dart';
import 'package:tawaq/feature/quran/presentation/widgets/study/study_content_section.dart';

void main() {
  Widget harness({required TranslationId source, required String text}) {
    return MaterialApp(
      home: Scaffold(
        body: TranslationProse(
          source: source,
          translation: Translation(
            id: 1,
            sura: 1,
            aya: 1,
            translation: text,
          ),
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  testWidgets('renders the exact translation string in source direction', (
    tester,
  ) async {
    const sourceText = 'In the name of Allah — [2]';
    await tester.pumpWidget(
      harness(source: TranslationId.saheehInternational, text: sourceText),
    );

    expect(find.text(sourceText), findsOneWidget);
    final directions = tester
        .widgetList<Directionality>(find.byType(Directionality))
        .map((widget) => widget.textDirection);
    expect(directions, contains(TextDirection.ltr));
  });

  testWidgets('renders Urdu prose RTL independently of interface locale', (
    tester,
  ) async {
    const sourceText = 'اللہ کے نام سے — [۲]';
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: Scaffold(
          body: TranslationProse(
            source: TranslationId.urdu,
            translation: const Translation(
              id: 1,
              sura: 1,
              aya: 1,
              translation: sourceText,
            ),
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );

    expect(find.text(sourceText), findsOneWidget);
    final directions = tester
        .widgetList<Directionality>(find.byType(Directionality))
        .map((widget) => widget.textDirection);
    expect(directions, contains(TextDirection.rtl));
  });
}
