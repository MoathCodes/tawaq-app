import 'package:dorar_hadith/dorar_hadith.dart';
// Fixture overrides belong to an independent root test scope.
// ignore_for_file: riverpod_lint/scoped_providers_should_specify_dependencies

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_filters.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/filters/hadith_lookup_section.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/l10n/app_localizations_delegates.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

void main() {
  for (final language in ['en', 'ar']) {
    for (final kind in HadithLookupKind.values) {
      testWidgets(
        '$language $kind lookup distinguishes failure and retries same query',
        (tester) async {
          tester.view.physicalSize = const Size(800, 600);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          var attempts = 0;
          final resumed = Completer<List<ReferenceChoice>>();
          final container = ProviderContainer(
            retry: (_, _) => null,
            overrides: [
              hadithLookupProvider(kind, 'اب').overrideWith((ref) {
                if (++attempts == 1)
                  return Future.error(StateError('private lookup diagnostic'));
                return resumed.future;
              }),
            ],
          );
          addTearDown(container.dispose);
          final l10n = lookupAppLocalizations(Locale(language));
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                locale: Locale(language),
                localizationsDelegates: appLocalizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: FTheme(
                  data: buildAppTheme(
                    palette: AppPalette.manuscript,
                    themeMode: ThemeMode.dark,
                    touch: false,
                    textScale: 1.2,
                  ),
                  child: Scaffold(
                    body: Padding(
                      padding: const EdgeInsets.all(24),
                      child: HadithLookupSection(
                        title: l10n.hadithBooks,
                        hint: l10n.hadithTypeToSearch,
                        kind: kind,
                        selected: (f) => const [],
                        withSelected: (f, items) => f,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text(l10n.hadithTypeToSearch));
          await tester.pumpAndSettle();
          expect(
            find.text(language == 'ar' ? 'بحث' : 'Search'),
            findsOneWidget,
          );
          final prompt = language == 'en'
              ? 'Type at least two characters to search suggestions.'
              : 'اكتب حرفين على الأقل للبحث عن اقتراحات.';

          await tester.enterText(find.byType(EditableText), 'اب');
          await tester.pump(const Duration(milliseconds: 250));
          await tester.pump();
          final message = language == 'en'
              ? 'Could not load suggestions. Try again.'
              : 'تعذّر تحميل الاقتراحات. حاول مرة أخرى.';
          expect(find.text(message), findsOneWidget);
          expect(find.text(l10n.noResults), findsNothing);
          expect(
            find.textContaining('private lookup diagnostic'),
            findsNothing,
          );
          final beforeRetry = tester.widget<EditableText>(
            find.byType(EditableText),
          );
          final selection = beforeRetry.controller.selection;
          final focus = beforeRetry.focusNode;
          expect(focus.hasFocus, isTrue);
          await tester.tap(find.text(l10n.retryAction));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 250));
          await tester.pump();
          expect(
            tester
                .widget<EditableText>(find.byType(EditableText))
                .controller
                .selection,
            selection,
          );
          expect(
            tester.widget<EditableText>(find.byType(EditableText)).focusNode,
            same(focus),
          );
          expect(attempts, 2);
          expect(
            tester
                .widget<EditableText>(find.byType(EditableText))
                .controller
                .text,
            'اب',
          );
          expect(find.text(message), findsNothing);
          expect(find.text(l10n.noResults), findsNothing);
          resumed.complete(const [
            ReferenceChoice(id: '1', name: 'Lookup fixture'),
          ]);
          await tester.pumpAndSettle();
          expect(find.text('Lookup fixture'), findsOneWidget);
          await tester.enterText(find.byType(EditableText), 'ا');
          await tester.pumpAndSettle();
          expect(find.text(prompt), findsOneWidget);
          expect(attempts, 2);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
        variant: TargetPlatformVariant({TargetPlatform.linux}),
      );
    }
  }
}
