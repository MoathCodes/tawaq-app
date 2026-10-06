// Fixture overrides belong to an independent root test scope.
// ignore_for_file: riverpod_lint/scoped_providers_should_specify_dependencies

import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/ayah_search_selector.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/l10n/app_localizations_delegates.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

class _Controller extends Mock implements MushafReaderController {}

void main() {
  testWidgets(
    'short Quran queries explain how to start; unmatched queries show no results',
    (tester) async {
      final controller = _Controller();
      when(controller.warmUpSearchIndex).thenAnswer((_) async {});
      when(() => controller.searchAyahs(any(), maxResults: 20))
          .thenAnswer((_) async => []);
      final theme = buildAppTheme(
        palette: AppPalette.manuscript,
        themeMode: ThemeMode.light,
        touch: false,
        textScale: 1,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            quranMushafControllerProvider.overrideWithValue(controller),
          ],
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: appLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: FTheme(
              data: theme,
              child: const Scaffold(
                body: Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(width: 500, child: AyahSearchSelector()),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      const prompt = 'Type at least two characters to search the Quran.';
      final field = find.byType(EditableText);
      await tester.tap(field);
      await tester.pumpAndSettle();
      expect(find.text(prompt), findsOneWidget);
      expect(find.text('No results found'), findsNothing);
      await tester.enterText(field, 'a');
      await tester.pumpAndSettle();
      expect(find.text(prompt), findsOneWidget);
      await tester.enterText(field, 'zz');
      await tester.pumpAndSettle();
      expect(find.text('No results found'), findsOneWidget);
      expect(find.text(prompt), findsNothing);
      await tester.enterText(field, '');
      await tester.pumpAndSettle();
      expect(find.text(prompt), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
