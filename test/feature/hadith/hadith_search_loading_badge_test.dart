// Fixture overrides belong to an independent root test scope.
// ignore_for_file: riverpod_lint/scoped_providers_should_specify_dependencies

import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_session_state.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/hadith_search_column.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/l10n/app_localizations_delegates.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

class _Session extends HadithSessionController {
  @override
  HadithSessionState build() => const HadithSessionState(
    query: 'fixture query',
    searchOutcome: AsyncLoading(),
  );
  void outcome(AsyncValue<HadithSearchPage> value) {
    state = state.copyWith(searchOutcome: value);
  }
}

void main() {
  for (final language in ['en', 'ar']) {
    testWidgets(
      'search count does not claim empty while loading or failed in $language',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            hadithSessionControllerProvider.overrideWith(_Session.new),
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
                  themeMode: ThemeMode.light,
                  touch: false,
                  textScale: 1,
                ),
                child: const Scaffold(
                  body: HadithSearchColumn(useSplitLayout: false),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(l10n.hadithResultsCount(0)), findsNothing);
        expect(find.text(l10n.loading), findsOneWidget);
        final session = container.read(
          hadithSessionControllerProvider.notifier,
        ) as _Session;
        session.outcome(
          AsyncError(StateError('private diagnostic'), StackTrace.empty),
        );
        await tester.pumpAndSettle();
        expect(find.text(l10n.hadithResultsCount(0)), findsNothing);
        expect(find.text(l10n.loading), findsNothing);
        session.outcome(const AsyncData(HadithSearchPage.empty));
        await tester.pumpAndSettle();
        expect(find.text(l10n.hadithResultsCount(0)), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
