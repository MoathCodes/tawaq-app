// The test owns a root provider scope and an empty durable-store fixture.
// ignore_for_file: riverpod_lint/scoped_providers_should_specify_dependencies
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/feature/hadith/data/database/hadith_local_database.dart';
import 'package:tawaq/feature/hadith/presentation/models/hadith_session_state.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/hadith_results_column.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/l10n/app_localizations_delegates.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

class _EmptyStore extends HadithFavoritesStore {
  @override
  Future<Map<String, SavedHadithEntry>> build() async => {};
}

void main() {
  for (final language in ['en', 'ar']) {
    testWidgets(
      'empty saved collection has a working browse action in $language',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            hadithFavoritesStoreProvider.overrideWith(_EmptyStore.new),
          ],
        );
        addTearDown(container.dispose);
        final subscription = container.listen(
          hadithSessionControllerProvider,
          (_, _) {},
        );
        addTearDown(subscription.close);
        container
            .read(hadithSessionControllerProvider.notifier)
            .openBookmarks();
        await tester.pumpWidget(
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
                locale: Locale(language),
                localizationsDelegates: appLocalizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: const Scaffold(body: HadithResultsColumn()),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final l10n = AppLocalizations.of(
          tester.element(find.byType(HadithResultsColumn)),
        )!;
        expect(find.text(l10n.hadithSavedEmptyTitle), findsOneWidget);
        expect(find.text(l10n.hadithSavedEmptyHint), findsOneWidget);
        expect(find.text(l10n.noResults), findsNothing);
        expect(find.text(l10n.hadithResultsCount(0)), findsNothing);
        await tester.tap(find.text(l10n.hadithBrowseAction));
        await tester.pumpAndSettle();
        final session = container.read(hadithSessionControllerProvider);
        expect(session.context, isA<SearchCollection>());
        expect((session.context as SearchCollection).home, true);
      },
    );
  }
}
