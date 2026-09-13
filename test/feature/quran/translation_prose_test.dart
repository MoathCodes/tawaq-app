import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/feature/quran/data/models/translation.dart';
import 'package:tawaq/feature/quran/domain/models/translation_source.dart';
import 'package:tawaq/feature/quran/presentation/models/quran_ui_models.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_screen_settings_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/study/study_content_section.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/translation_source_selector.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

class _TestQuranScreenSettings extends QuranScreenSettingsNotifier {
  @override
  Future<QuranScreenState> build() async => QuranScreenState.initial();
}

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
    final prose = find.byKey(const ValueKey('translation-prose-direction'));
    expect(
      tester.widget<Directionality>(prose).textDirection,
      TextDirection.ltr,
    );
    final selectable = tester.widget<SelectableText>(
      find.descendant(of: prose, matching: find.byType(SelectableText)),
    );
    expect(selectable.textDirection, TextDirection.ltr);
  });

  testWidgets('English prose stays LTR inside an Arabic interface shell', (
    tester,
  ) async {
    const sourceText = 'In the name of Allah — [2]';
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        home: const Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: TranslationProse(
              source: TranslationId.saheehInternational,
              translation: Translation(
                id: 1,
                sura: 1,
                aya: 1,
                translation: sourceText,
              ),
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
    );

    final prose = find.byKey(const ValueKey('translation-prose-direction'));
    expect(
      tester.widget<Directionality>(prose).textDirection,
      TextDirection.ltr,
    );
    final selectable = tester.widget<SelectableText>(
      find.descendant(of: prose, matching: find.byType(SelectableText)),
    );
    expect(selectable.textDirection, TextDirection.ltr);
    expect(find.text(sourceText), findsOneWidget);
  });

  testWidgets('renders Urdu prose RTL inside an English interface shell', (
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
    final prose = find.byKey(const ValueKey('translation-prose-direction'));
    expect(
      tester.widget<Directionality>(prose).textDirection,
      TextDirection.rtl,
    );
    final selectable = tester.widget<SelectableText>(
      find.descendant(of: prose, matching: find.byType(SelectableText)),
    );
    expect(selectable.textDirection, TextDirection.rtl);
  });

  testWidgets(
    'translation selector keeps an accessible name without a label row',
    (
      tester,
    ) async {
      final theme = buildAppTheme(
        palette: AppPalette.manuscript,
        themeMode: ThemeMode.light,
        touch: false,
        textScale: 1,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            quranScreenSettingsProvider.overrideWith(
              _TestQuranScreenSettings.new,
            ),
          ],
          child: FTheme(
            data: theme,
            child: MaterialApp(
              locale: const Locale('en'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const Scaffold(
                body: TranslationSourceSelector(showLabel: false),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final selector = tester.getSemantics(
        find.bySemanticsLabel('Translation'),
      );
      expect(selector.label, 'Translation');
    },
  );

  testWidgets('long prose keeps its source selector reachable above the text', (
    tester,
  ) async {
    final semanticsHandle = tester.ensureSemantics();
    final theme = buildAppTheme(
      palette: AppPalette.manuscript,
      themeMode: ThemeMode.light,
      touch: false,
      textScale: 1,
    );
    const longText =
        'A long source passage remains readable while the compact edition '
        'control stays available near the section heading. ';
    await tester.pumpWidget(
      FTheme(
        data: theme,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              width: 340,
              height: 400,
              child: SingleChildScrollView(
                child: StudyContentSection<String>(
                  asyncValue: const AsyncData(longText),
                  contentKey: 'long-prose',
                  errorMessage: 'error',
                  emptyMessage: 'empty',
                  sourceSelector: Semantics(
                    label: 'Edition source',
                    button: true,
                    onTap: () {},
                    child: const Text('Source'),
                  ),
                  contentBuilder: (text) => Text(text),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final selector = find.text('Source');
    expect(selector, findsOneWidget);
    expect(
      tester.getTopLeft(selector).dy,
      lessThan(tester.getTopLeft(find.text(longText)).dy),
    );
    semanticsHandle.dispose();
  });
}
