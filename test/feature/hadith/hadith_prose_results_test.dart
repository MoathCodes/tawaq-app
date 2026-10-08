import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart' hide TextRange;
import 'package:tawaq/feature/hadith/presentation/models/hadith_session_state.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/hadith_results_column.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

class _Session extends HadithSessionController {
  @override
  HadithSessionState build() {
    final source = List.filled(200, 'شرح طويل بألفاظ المصدر').join(' ');
    final document = SourcedDocument(
      sourceHtml: '',
      sourceText: source,
      contentHash: sha256.convert(utf8.encode('1\n$source')).toString(),
      blocks: [
        DocumentBlock(
          kind: BlockKind.commentary,
          range: TextRange(0, source.length),
        ),
      ],
    );
    return HadithSessionState(
      query: 'شرح',
      target: HadithSearchTarget.prose,
      searchOutcome: AsyncData(
        HadithSearchPage.prose(
          snippets: [
            SharhSnippet(
              id: '1',
              uri: Uri.parse('https://dorar.net/sharh/1'),
              document: document,
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  testWidgets(
    'long prose excerpt wraps within a narrow result row at large text',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            hadithSessionControllerProvider.overrideWith(_Session.new),
          ],
          child: FTheme(
            data: buildAppTheme(
              palette: AppPalette.manuscript,
              themeMode: ThemeMode.light,
              touch: false,
              textScale: 1.4,
            ),
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 320,
                    height: 450,
                    child: HadithResultsColumn(),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final excerpt = find.textContaining('شرح طويل');
      expect(excerpt.hitTestable(), findsOneWidget);
      expect(tester.getSize(excerpt).width, lessThan(320));
    },
  );
}
