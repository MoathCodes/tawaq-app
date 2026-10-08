// Independent fixture scope; no app storage or remote requests.
// ignore_for_file: riverpod_lint/scoped_providers_should_specify_dependencies
import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/feature/hadith/presentation/models/hadith_session_state.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/hadith_topics.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/hadith_desk_breadcrumbs.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/l10n/app_localizations_delegates.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

class _Session extends HadithSessionController {
  @override
  HadithSessionState build() =>
      const HadithSessionState(context: TopicsCollection());
}

void main() {
  testWidgets(
    'bounded roots, searched categories and breadcrumb ancestors preserve exact selectors',
    (tester) async {
      final roots = [
        for (var i = 0; i < 15; i++)
          ThematicRoot(value: 'selector $i ', name: 'Fixture root $i'),
      ];
      final leaf = ThematicCategory(
        id: 'leaf',
        name: 'Fixture leaf',
        uri: Uri.https('dorar.net', '/hadith-category/cat/leaf'),
      );
      String? requestedSelector;
      String? requestedQuery;
      final container = ProviderContainer(
        overrides: [
          hadithSessionControllerProvider.overrideWith(_Session.new),
          hadithTopicRootsProvider.overrideWith(
            (ref) async =>
                ApiResponse(data: roots, metadata: const SearchMetadata()),
          ),
          hadithTopicChildrenProvider.overrideWith((ref, parent) async {
            requestedSelector = parent.value;
            return ApiResponse(data: [leaf], metadata: const SearchMetadata());
          }),
          hadithTopicSearchProvider.overrideWith((ref, query) async {
            requestedQuery = query;
            return ApiResponse(data: [leaf], metadata: const SearchMetadata());
          }),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: FTheme(
            data: buildAppTheme(
              palette: AppPalette.manuscript,
              themeMode: ThemeMode.dark,
              touch: false,
              textScale: 1,
            ),
            child: MaterialApp(
              locale: const Locale('en'),
              localizationsDelegates: appLocalizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const Scaffold(
                body: SingleChildScrollView(
                  child: Column(
                    children: [HadithDeskBreadcrumbs(), HadithTopics()],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Fixture root'), findsNWidgets(8));
      expect(find.text('Fixture root 14'), findsNothing);
      await tester.tap(find.text('Fixture root 0'));
      await tester.pumpAndSettle();
      expect(requestedSelector, 'selector 0 ');
      expect(find.byType(FBreadcrumb), findsOneWidget);
      await tester.tap(find.byIcon(FLucideIcons.chevronDown));
      await tester.pumpAndSettle();
      expect(
        container.read(hadithSessionControllerProvider).topicPath.length,
        2,
      );
      await tester.tap(find.text('Fixture root 0'));
      await tester.pumpAndSettle();
      expect(
        container.read(hadithSessionControllerProvider).topicPath.length,
        1,
      );
      final query = find.byType(EditableText);
      await tester.enterText(query, 'Fixture query');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(requestedQuery, 'Fixture query');
      expect(find.text('Fixture leaf'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
