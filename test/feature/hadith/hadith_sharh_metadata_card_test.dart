import 'dart:async';

import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/detail/hadith_sharh_text.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

void main() {
  testWidgets('shared pending explanation uses the current selection origin', (
    tester,
  ) async {
    final pending = Completer<Sharh>();
    var requests = 0;
    final container = ProviderContainer(
      overrides: [
        hadithSharhProvider.overrideWith((ref, id) {
          requests++;
          return pending.future;
        }),
      ],
    );
    addTearDown(container.dispose);
    Future<void> render(String label, ContentRelationship relationship) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
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
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) {
                    final value = ref.watch(hadithSharhProvider(SharhId('1')));
                    return value.when(
                      loading: () => const Text('pending'),
                      error: (error, stack) => Text('$error'),
                      data: (sharh) => SingleChildScrollView(
                        child: HadithSharhContent(
                          sharh: sharh,
                          origin: ExplanationReference(
                            id: '1',
                            uri: Uri.parse('https://dorar.net/sharh/1'),
                            relationship: relationship,
                            rawLabel: label,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    await render('first direct origin', ContentRelationship.direct);
    await render('current similar origin', ContentRelationship.similar);
    pending.complete(
      const Sharh(
        hadith: DetailedHadith(
          hadith: 'source header',
          rawi: 'r',
          mohdith: 'm',
          book: 'b',
          numberOrPage: '1',
          grade: 'g',
        ),
        sharhMetadata: SharhMetadata(id: '1', sharh: 'source prose'),
      ),
    );
    await tester.pumpAndSettle();
    expect(requests, 1);
    expect(find.text('current similar origin'), findsOneWidget);
    expect(find.text('first direct origin'), findsNothing);
    expect(find.text('source header'), findsOneWidget);
  });

  testWidgets('page header and body citation do not leak selection origin', (
    tester,
  ) async {
    const header = DetailedHadith(
      hadith: 'header matn',
      rawi: 'header narrator',
      mohdith: 'header scholar',
      book: 'header book',
      numberOrPage: '1',
      grade: 'header ruling',
    );
    const body = DetailedHadith(
      hadith: 'body matn',
      rawi: 'body narrator',
      mohdith: 'body scholar',
      book: 'body book',
      numberOrPage: '2',
      grade: 'body ruling',
    );
    const sharh = Sharh(
      hadith: header,
      embeddedHadith: body,
      sharhMetadata: SharhMetadata(id: '1', sharh: 'old plain commentary'),
    );
    Future<void> render(String label, {bool commentaryOnly = false}) =>
        tester.pumpWidget(
          ProviderScope(
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
                home: Scaffold(
                  body: SingleChildScrollView(
                    child: HadithSharhContent(
                      sharh: sharh,
                      commentaryOnly: commentaryOnly,
                      origin: ExplanationReference(
                        id: '1',
                        uri: Uri.parse('https://dorar.net/sharh/1'),
                        rawLabel: label,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
    await render('similar origin');
    await tester.pumpAndSettle();
    expect(find.text('header matn'), findsOneWidget);
    expect(find.text('body matn'), findsOneWidget);
    expect(find.text('similar origin'), findsOneWidget);
    await render('direct origin');
    await tester.pumpAndSettle();
    expect(find.text('similar origin'), findsNothing);
    expect(find.text('direct origin'), findsOneWidget);
    expect(find.text('old plain commentary'), findsOneWidget);
    await render('direct origin', commentaryOnly: true);
    await tester.pumpAndSettle();
    expect(find.text('header matn'), findsNothing);
    expect(find.text('body matn'), findsNothing);
    expect(
      find.textContaining('header ruling', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('body ruling', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('old plain commentary'), findsOneWidget);
  });
}
