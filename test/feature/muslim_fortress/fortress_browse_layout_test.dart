// Independent screen scope isolates persistence and bundled repository loading.
// ignore_for_file: riverpod_lint/scoped_providers_should_specify_dependencies
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:hisn_elmoslem/hisn_elmoslem.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/core/shortcuts/shortcuts.dart';
import 'package:tawaq/feature/muslim_fortress/data/repository/fortress_repository.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_screen_state.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/provider/fortress_screen_settings_provider.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/provider/muslim_fortress_provider.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/screens/muslim_fortress_screen.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/browse/fortress_browse_sidebar.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/browse/fortress_category_detail.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/fortress_favorite_toggle.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/search/fortress_search_results.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/study/fortress_dua_insights.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/study/fortress_study_panel.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/l10n/app_localizations_delegates.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/spacing.dart';
import 'package:tawaq/theme/theme_model.dart';

class _Settings extends FortressScreenSettingsNotifier {
  @override
  Future<FortressScreenState> build() async => FortressScreenState.initial();
}

void main() {
  late HisnClient client;
  late FortressRepository repository;
  setUp(() async {
    client = await HisnClient.open();
    repository = FortressRepository(client);
  });
  tearDown(() => client.close());

  Future<ProviderContainer> mount(
    WidgetTester tester,
    Locale locale, {
    Size size = const Size(1300, 850),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fortressRepositoryProvider.overrideWith((ref) async => repository),
          fortressRecommendedCategoriesProvider.overrideWith((ref) => []),
          fortressScreenSettingsProvider.overrideWith(_Settings.new),
        ],
        child: FTheme(
          data: buildAppTheme(
            palette: AppPalette.manuscript,
            themeMode: ThemeMode.dark,
            touch: false,
            textScale: 1.3,
          ),
          child: MaterialApp(
            locale: locale,
            localizationsDelegates: appLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: MuslimFortressScreen()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(
      tester.element(find.byType(MuslimFortressScreen)),
    );
  }

  testWidgets(
    'browse sheet covers catalog, is flush, and closes on catalog tap',
    (tester) async {
      final container = await mount(tester, const Locale('ar'));
      final chapter = repository.loadChapters().first;
      container
          .read(fortressScreenControllerProvider.notifier)
          .selectCategory(chapter);
      await tester.pumpAndSettle();
      final item = repository.loadDuas(chapter.chapterId).first;
      showFortressStudySheet(
        tester.element(find.byType(FortressCategoryDetailView)),
        item,
      );
      await tester.pumpAndSettle();
      expect(find.byType(FortressStudyHost), findsOneWidget);
      final screen = tester.getRect(find.byType(MuslimFortressScreen));
      final sheet = tester.getRect(find.byType(FortressStudyPanel));
      expect(sheet.left, screen.left);
      expect(sheet.top, screen.top);
      expect(sheet.bottom, screen.bottom);
      final barrier = tester.getRect(find.byType(FModalBarrier));
      expect(
        barrier.contains(tester.getCenter(find.byType(FortressBrowseSidebar))),
        isTrue,
      );
      await tester.tapAt(tester.getCenter(find.byType(FortressBrowseSidebar)));
      await tester.pumpAndSettle();
      expect(find.byType(FortressStudyPanel), findsNothing);
      expect(
        container.read(fortressScreenControllerProvider).selectedChapterId,
        chapter.chapterId,
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final locale in [const Locale('en'), const Locale('ar')]) {
    testWidgets(
      'browse sidebar follows ${locale.languageCode} direction and reserves collapse space',
      (tester) async {
        await mount(tester, locale);
        final sidebar = find.byType(FortressBrowseSidebar);
        final rect = tester.getRect(sidebar);
        expect(
          rect.center.dx,
          locale.languageCode == 'ar' ? greaterThan(650) : lessThan(650),
        );
        final title = find.descendant(
          of: sidebar,
          matching: find.text(lookupAppLocalizations(locale).muslimFortress),
        );
        final collapse = find.byIcon(
          locale.languageCode == 'ar'
              ? FLucideIcons.panelRightClose
              : FLucideIcons.panelLeftClose,
        );
        expect(
          tester.getRect(collapse).overlaps(tester.getRect(title)),
          isFalse,
        );
        final splitRect = tester.getRect(find.byType(FResizable));
        final dividerCenter = tester.getCenter(
          find.byIcon(FLucideIcons.gripVertical),
        );
        final l10n = lookupAppLocalizations(locale);
        expect(
          find.descendant(
            of: sidebar,
            matching: find.text(l10n.fortressAllChapters),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: sidebar,
            matching: find.text(l10n.fortressFavorites),
          ),
          findsOneWidget,
        );
        // The content is inset at the divider edge, in physical split coordinates.
        if (locale.languageCode == 'ar') {
          expect(
            rect.left - dividerCenter.dx,
            greaterThanOrEqualTo(AppSpacing.lg - 1),
          );
          expect(splitRect.right - rect.right, closeTo(0, 0.1));
        } else {
          expect(
            dividerCenter.dx - rect.right,
            greaterThanOrEqualTo(AppSpacing.lg - 1),
          );
          expect(rect.left - splitRect.left, closeTo(0, 0.1));
        }
        expect(find.byType(TextField), findsOneWidget);
        expect(find.byIcon(FLucideIcons.search), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
      semanticsEnabled: false,
      variant: const TargetPlatformVariant({TargetPlatform.linux}),
    );
  }

  testWidgets(
    'detail header has one reading action and no duplicate bookmark',
    (tester) async {
      final container = await mount(tester, const Locale('ar'));
      container
          .read(fortressScreenControllerProvider.notifier)
          .selectCategory(repository.loadChapters()[3]);
      await tester.pumpAndSettle();
      expect(find.byType(FortressCategoryDetailHeader), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(FortressCategoryDetailHeader),
          matching: find.byType(FortressFavoriteToggle),
        ),
        findsNothing,
      );
      expect(find.byType(TextField), findsOneWidget);
    },
    semanticsEnabled: false,
    variant: const TargetPlatformVariant({TargetPlatform.linux}),
  );

  testWidgets(
    'compact unified search keeps typing visible and searches source content',
    (tester) async {
      final container = await mount(
        tester,
        const Locale('ar'),
        size: const Size(800, 600),
      );
      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'الحمد');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();
      expect(container.read(fortressScreenControllerProvider).query, 'الحمد');
      expect(repository.search('الحمد').contents, isNotEmpty);
      expect(
        find.descendant(
          of: find.byType(FortressBrowseSidebar),
          matching: find.byType(FortressSearchResultsPane),
        ),
        findsOneWidget,
      );
      expect(find.byType(TextField), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus,
        isTrue,
      );
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();
      expect(container.read(fortressScreenControllerProvider).query, isEmpty);
      expect(find.byType(FortressSearchResultsPane), findsNothing);
      expect(tester.takeException(), isNull);
    },
    semanticsEnabled: false,
    variant: const TargetPlatformVariant({TargetPlatform.linux}),
  );

  testWidgets(
    'search shortcut reopens a collapsed sidebar and focuses its only field',
    (tester) async {
      final container = await mount(tester, const Locale('ar'));
      await tester.tap(find.byIcon(FLucideIcons.panelRightClose));
      await tester.pumpAndSettle();
      expect(
        container
            .read(fortressScreenSettingsProvider)
            .value!
            .sidePanelCollapsed,
        isTrue,
      );
      expect(AppSearchFocusRegistry.instance.focus(), isTrue);
      await tester.pumpAndSettle();
      expect(
        container
            .read(fortressScreenSettingsProvider)
            .value!
            .sidePanelCollapsed,
        isFalse,
      );
      expect(find.byType(TextField), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus,
        isTrue,
      );
    },
    semanticsEnabled: false,
    variant: const TargetPlatformVariant({TargetPlatform.linux}),
  );
  testWidgets(
    'opening a chapter cancels a still-pending search',
    (tester) async {
      final container = await mount(tester, const Locale('en'));
      await tester.enterText(find.byType(TextField), 'الحمد');
      await tester.pump();
      container
          .read(fortressScreenControllerProvider.notifier)
          .selectCategory(repository.loadChapters()[3]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(container.read(fortressScreenControllerProvider).query, isEmpty);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(find.byType(FortressCategoryDetailHeader), findsOneWidget);
    },
    semanticsEnabled: false,
    variant: const TargetPlatformVariant({TargetPlatform.linux}),
  );

  testWidgets(
    'compact search can reopen the already-selected chapter',
    (tester) async {
      final container = await mount(
        tester,
        const Locale('ar'),
        size: const Size(800, 600),
      );
      final category = repository.loadChapters()[3];
      container
          .read(fortressScreenControllerProvider.notifier)
          .selectCategory(category);
      await tester.pumpAndSettle();
      final back = lookupAppLocalizations(const Locale('ar'))
          .fortressBackToCatalog;
      await tester.tap(find.text(back));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), category.title);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(
        container.read(fortressScreenControllerProvider).query,
        category.title,
      );
      expect(
        repository.search(category.title).titles.map((c) => c.chapterId),
        contains(category.chapterId),
      );
      await tester.tap(
        find
            .descendant(
              of: find.byType(FortressSearchResultsPane),
              matching: find.text(category.title),
            )
            .first,
      );
      await tester.pumpAndSettle();
      expect(find.byType(FortressCategoryDetailHeader), findsOneWidget);
      expect(
        container.read(fortressScreenControllerProvider).selectedChapterId,
        category.chapterId,
      );
      expect(container.read(fortressScreenControllerProvider).query, isEmpty);
      await tester.tap(find.text(back));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
    },
    semanticsEnabled: false,
    variant: const TargetPlatformVariant({TargetPlatform.linux}),
  );

  testWidgets(
    'favorites use the same field without losing bookmark scope',
    (tester) async {
      final container = await mount(tester, const Locale('en'));
      final category = repository.loadChapters()[3];
      container.read(fortressScreenSettingsProvider.notifier)
        ..toggleFavorite(category.chapterId)
        ..setSidebarTab(FortressSidebarTab.favorites);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), category.title);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.byType(FortressSearchResultsPane), findsNothing);
      final tiles = tester.widgetList<FortressCategoryListTile>(
        find.byType(FortressCategoryListTile),
      );
      expect(tiles.map((tile) => tile.category.chapterId), [
        category.chapterId,
      ]);
      expect(find.byType(TextField), findsOneWidget);
    },
    semanticsEnabled: false,
    variant: const TargetPlatformVariant({TargetPlatform.linux}),
  );
  testWidgets(
    'search shortcut focuses an already-visible field without waiting for a new frame',
    (tester) async {
      await mount(tester, const Locale('en'), size: const Size(800, 600));
      final focus = tester.widget<TextField>(find.byType(TextField)).focusNode!;
      expect(focus.hasFocus, isFalse);
      expect(AppSearchFocusRegistry.instance.focus(), isTrue);
      await tester.idle();
      expect(focus.hasFocus, isTrue);
    },
    semanticsEnabled: false,
    variant: const TargetPlatformVariant({TargetPlatform.linux}),
  );
}
