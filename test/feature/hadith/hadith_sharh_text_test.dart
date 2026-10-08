import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/gestures.dart';
import 'package:tawaq/core/utils/external_link_provider.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart' hide TextRange;
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/detail/hadith_sharh_text.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

Widget wrap(Widget child) => ProviderScope(
  child: FTheme(
    data: buildAppTheme(
      palette: AppPalette.neutral,
      themeMode: ThemeMode.light,
      touch: false,
      textScale: 1,
    ),
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  ),
);

void main() {
  testWidgets(
    'canonical ranges preserve marks, dashes, UTF-16 and boundaries',
    (tester) async {
      const source = 'قَالَ — 😀\n\nأي: كلام محايد\nعنصر';
      final second = source.indexOf('أي:');
      final third = source.indexOf('عنصر');
      final document = SourcedDocument(
        sourceHtml: '',
        sourceText: source,
        contentHash: sha256.convert(utf8.encode('1\n$source')).toString(),
        blocks: [
          DocumentBlock(
            kind: BlockKind.paragraph,
            range: TextRange(0, second - 2),
          ),
          DocumentBlock(
            kind: BlockKind.paragraph,
            range: TextRange(second, third - 1),
          ),
          DocumentBlock(
            kind: BlockKind.listItem,
            range: TextRange(third, source.length),
          ),
        ],
        annotations: const [
          InlineAnnotation(
            kind: AnnotationKind.quotation,
            range: TextRange(0, 5),
          ),
        ],
      );
      await tester.pumpWidget(wrap(HadithSharhText(document: document)));
      final paragraphs = tester
          .widgetList<ScopedSelectableRichText>(
            find.byType(ScopedSelectableRichText),
          )
          .toList();
      expect(paragraphs.map((p) => p.textSpan.toPlainText()).toList(), [
        'قَالَ — 😀',
        'أي: كلام محايد',
        'عنصر',
      ]);
      final rendered = paragraphs.first;
      expect(
        document.sourceText,
        source,
        reason: 'Presentation spacing must not rewrite canonical ranges',
      );
      expect(
        rendered.textSpan.children!.whereType<TextSpan>().first.style,
        isNull,
        reason: 'quotation does not imply a speaker',
      );
    },
  );

  testWidgets('commentary sharing excludes narration and citation', (
    tester,
  ) async {
    const source = 'matn\nsource\ncommentary';
    final document = SourcedDocument(
      sourceHtml: '',
      sourceText: source,
      contentHash: sha256.convert(utf8.encode('1\n$source')).toString(),
      blocks: const [
        DocumentBlock(kind: BlockKind.narration, range: TextRange(0, 4)),
        DocumentBlock(kind: BlockKind.citation, range: TextRange(5, 11)),
        DocumentBlock(kind: BlockKind.commentary, range: TextRange(12, 22)),
      ],
    );
    await tester.pumpWidget(
      wrap(HadithSharhText(document: document, commentaryOnly: true)),
    );
    expect(
      tester
          .widget<ScopedSelectableRichText>(
            find.byType(ScopedSelectableRichText),
          )
          .textSpan
          .toPlainText(),
      'commentary',
    );
  });

  testWidgets(
    'source annotations open glossary and established external links',
    (tester) async {
      const source = 'word link';
      final uri = Uri.parse('https://dorar.net/sharh/1');
      final document = SourcedDocument(
        sourceHtml: '',
        sourceText: source,
        contentHash: sha256.convert(utf8.encode('1\n$source')).toString(),
        blocks: const [
          DocumentBlock(kind: BlockKind.commentary, range: TextRange(0, 9)),
        ],
        annotations: [
          const InlineAnnotation(
            kind: AnnotationKind.glossary,
            range: TextRange(0, 4),
            definition: 'source definition',
            label: 'word',
          ),
          InlineAnnotation(
            kind: AnnotationKind.quranCitation,
            range: const TextRange(5, 9),
            uri: uri,
          ),
        ],
      );
      Uri? opened;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            externalLinkLauncherProvider.overrideWithValue((value) async {
              opened = value;
              return true;
            }),
          ],
          child: wrap(HadithSharhText(document: document)),
        ),
      );
      await tester.pumpAndSettle();
      final spans = tester
          .widget<ScopedSelectableRichText>(
            find.byType(ScopedSelectableRichText),
          )
          .textSpan
          .children!
          .whereType<TextSpan>()
          .toList();
      (spans.first.recognizer! as TapGestureRecognizer).onTap!();
      await tester.pumpAndSettle();
      expect(find.text('source definition'), findsOneWidget);
      (spans.last.recognizer! as TapGestureRecognizer).onTap!();
      await tester.pump();
      expect(opened, uri);
    },
  );

  testWidgets('historical flattened samples render unchanged', (tester) async {
    final fixtures = jsonDecode(
      File('test/fixtures/hadith_sharh_samples.json').readAsStringSync(),
    ) as List;
    for (final raw in fixtures) {
      final map = raw as Map;
      final text = (map['sharhText'] ?? map['text'] ?? map['sharh']) as String?;
      if (text == null) continue;
      await tester.pumpWidget(wrap(HadithSharhText(text: text)));
      expect(find.text(text), findsOneWidget);
    }
  });
}
