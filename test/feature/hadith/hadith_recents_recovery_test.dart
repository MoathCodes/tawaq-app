import 'package:dorar_hadith/dorar_hadith.dart';
// Fixture overrides belong to an independent root test scope.
// ignore_for_file: riverpod_lint/scoped_providers_should_specify_dependencies

import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tawaq/feature/hadith/data/models/hadith_recent_search.dart';
import 'package:tawaq/feature/hadith/data/repository/hadith_repository.dart';
import 'package:tawaq/feature/hadith/presentation/models/hadith_session_state.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/hadith_accessibility.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/hadith_results_column.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/l10n/app_localizations_delegates.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

class _Repository extends Mock implements HadithRepository {}

class _Session extends HadithSessionController {
  @override
  HadithSessionState build() => const HadithSessionState();
}

void main() {
  for (final language in ['en', 'ar']) {
    final l10n = lookupAppLocalizations(Locale(language));
    late _Repository repository;
    late List<String> persisted;
    setUp(() {
      repository = _Repository();
      persisted = ['saved search'];
      when(repository.getRecentSearches).thenAnswer(
        (_) async => [
          for (var i = 0; i < persisted.length; i++)
            HadithRecentSearch(
              id: i,
              query: persisted[i],
              searchedAt: DateTime(2026),
            ),
        ],
      );
    });

    Future<void> mount(WidgetTester tester) async {
      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          hadithRepositoryProvider.overrideWith((_) async => repository),
          hadithSessionControllerProvider.overrideWith(_Session.new),
          hadithTopicRootsProvider.overrideWith(
            (ref) async => const ApiResponse(
              data: <ThematicRoot>[],
              metadata: SearchMetadata(),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: FTheme(
            data: buildAppTheme(
              palette: AppPalette.manuscript,
              themeMode: ThemeMode.light,
              touch: false,
              textScale: 1.2,
            ),
            child: MaterialApp(
              locale: Locale(language),
              localizationsDelegates: appLocalizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: FToaster(child: Scaffold(body: HadithRecentQueries())),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('recent search load failure offers retry in $language', (
      tester,
    ) async {
      var fail = true;
      when(repository.getRecentSearches).thenAnswer((_) async {
        if (fail) throw StateError('private disk diagnostic');
        return [
          HadithRecentSearch(
            id: 1,
            query: 'saved search',
            searchedAt: DateTime(2026),
          ),
        ];
      });
      await mount(tester);
      expect(find.text(l10n.hadithRecentsLoadFailed), findsOneWidget);
      expect(find.textContaining('private disk diagnostic'), findsNothing);
      fail = false;
      await tester.tap(find.text(l10n.retryAction));
      await tester.pumpAndSettle();
      expect(find.text('saved search'), findsOneWidget);
      expect(find.text(l10n.hadithRecentsLoadFailed), findsNothing);
      verify(repository.getRecentSearches).called(2);
      expect(tester.takeException(), isNull);
    }, variant: TargetPlatformVariant({TargetPlatform.linux}));

    testWidgets('failed recent search deletion retains entry in $language', (
      tester,
    ) async {
      var fail = true;
      when(() => repository.removeRecentSearch('saved search'))
          .thenAnswer((_) async {
            if (fail) throw StateError('private disk diagnostic');
            persisted.clear();
          });
      await mount(tester);
      final remove = find.byWidgetPredicate(
        (widget) =>
            widget is FButton &&
            widget.semanticsLabel ==
                hadithRemoveRecentSearchSemanticsLabel('saved search', l10n),
      );
      await tester.tap(remove);
      await tester.pumpAndSettle();
      expect(find.text('saved search'), findsOneWidget);
      expect(find.text(l10n.hadithRecentsUpdateFailed), findsOneWidget);
      expect(find.textContaining('private disk diagnostic'), findsNothing);
      fail = false;
      await tester.tap(remove);
      await tester.pumpAndSettle();
      expect(find.text('saved search'), findsNothing);
      expect(find.text(l10n.hadithNoRecentSearches), findsOneWidget);
      expect(persisted, isEmpty);
      expect(tester.takeException(), isNull);
    }, variant: TargetPlatformVariant({TargetPlatform.linux}));

    testWidgets('failed clear recents retains entries in $language', (
      tester,
    ) async {
      var fail = true;
      when(repository.clearRecentSearches).thenAnswer((_) async {
        if (fail) throw StateError('private disk diagnostic');
        persisted.clear();
      });
      await mount(tester);
      Future<void> clear() async {
        await tester.tap(find.text(l10n.hadithClearAllRecents).first);
        await tester.pumpAndSettle();
        expect(find.text(l10n.hadithClearRecentsConfirm), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text(l10n.hadithClearAllRecents).last);
        await tester.pumpAndSettle();
      }

      await clear();
      expect(find.text('saved search'), findsOneWidget);
      expect(find.text(l10n.hadithRecentsUpdateFailed), findsOneWidget);
      expect(find.textContaining('private disk diagnostic'), findsNothing);
      fail = false;
      await clear();
      expect(find.text('saved search'), findsNothing);
      expect(find.text(l10n.hadithNoRecentSearches), findsOneWidget);
      expect(persisted, isEmpty);
      expect(tester.takeException(), isNull);
    }, variant: TargetPlatformVariant({TargetPlatform.linux}));
  }
}
