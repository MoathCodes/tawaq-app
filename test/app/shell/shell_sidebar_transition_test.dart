import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart';
import 'package:tawaq/feature/hadith/presentation/models/hadith_session_state.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_filters.dart';
// Fixture overrides belong to an independent root test scope.
// ignore_for_file: riverpod_lint/scoped_providers_should_specify_dependencies

import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/app/shell/shell_sidebar.dart';
import 'package:tawaq/core/widgets/page_shell/sidebar_settings_provider.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/l10n/app_localizations_delegates.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

class _SidebarSettings extends SidebarSettingsNotifier {
  @override
  Future<bool> build() async => false;
}

class _HadithSession extends HadithSessionController {
  @override
  HadithSessionState build() => const HadithSessionState(
    query: 'prior query',
    filters: HadithFilters(exclude: 'draft'),
  );
}

void main() {
  for (final language in ['en', 'ar']) {
    testWidgets('Hadith sidebar owns home, topics and saved ($language)', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 860));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final container = ProviderContainer(
        overrides: [
          sidebarSettingsProvider.overrideWith(_SidebarSettings.new),
          hadithSessionControllerProvider.overrideWith(_HadithSession.new),
        ],
      );
      addTearDown(container.dispose);
      final router = GoRouter(
        initialLocation: '/hadith',
        routes: [
          GoRoute(
            path: '/hadith',
            builder: (_, _) => const Row(
              children: [
                ShellSidebar(),
                Expanded(child: SizedBox()),
              ],
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await container.read(sidebarSettingsProvider.future);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            locale: Locale(language),
            localizationsDelegates: appLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (_, child) => FTheme(
              data: buildAppTheme(
                palette: AppPalette.manuscript,
                themeMode: ThemeMode.dark,
                touch: false,
                textScale: 1.2,
              ),
              child: child!,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final session = container.read(hadithSessionControllerProvider.notifier);
      await tester.tap(find.byKey(const ValueKey('hadith-sidebar-topics')));
      await tester.pumpAndSettle();
      expect(session.state.context, isA<TopicsCollection>());
      expect(
        tester
            .widget<FSidebarItem>(
              find.byKey(const ValueKey('hadith-sidebar-topics')),
            )
            .selected,
        isTrue,
      );
      await tester.tap(find.byKey(const ValueKey('hadith-sidebar-saved')));
      await tester.pumpAndSettle();
      expect(session.state.context, isA<SavedCollection>());
      await tester.tap(find.byKey(const ValueKey('/hadith')));
      await tester.pumpAndSettle();
      expect((session.state.context as SearchCollection).home, isTrue);
      expect(session.state.query, isEmpty);
      expect(session.state.filters.exclude, 'draft');
      container
          .read(sidebarSettingsProvider.notifier)
          .setCollapsed(collapsed: true);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('hadith-sidebar-topics')));
      await tester.pumpAndSettle();
      expect(session.state.context, isA<TopicsCollection>());
      await tester.tap(find.byKey(const ValueKey('/hadith')));
      await tester.pumpAndSettle();
      expect((session.state.context as SearchCollection).home, isTrue);
      expect(tester.takeException(), isNull);
    });
  }

  for (final language in ['en', 'ar']) {
    for (final reduced in [false, true]) {
      testWidgets(
        'sidebar collapse, reversal and expansion stay bounded in $language (reduced=$reduced)',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(1200, 860));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final container = ProviderContainer(
            overrides: [
              sidebarSettingsProvider.overrideWith(_SidebarSettings.new),
            ],
          );
          addTearDown(container.dispose);
          final router = GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, _) => const Row(
                  children: [
                    ShellSidebar(),
                    Expanded(child: SizedBox()),
                  ],
                ),
              ),
            ],
          );
          addTearDown(router.dispose);
          final theme = buildAppTheme(
            palette: AppPalette.manuscript,
            themeMode: ThemeMode.dark,
            touch: false,
            textScale: 1.2,
          );
          await container.read(sidebarSettingsProvider.future);
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp.router(
                routerConfig: router,
                locale: Locale(language),
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: appLocalizationsDelegates,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    disableAnimations: reduced,
                    textScaler: const TextScaler.linear(1.2),
                  ),
                  child: FTheme(data: theme, child: child!),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.getSize(find.byType(FSidebar)).width, 250);
          final settings = container.read(sidebarSettingsProvider.notifier);
          settings.setCollapsed(collapsed: true);
          await tester.pump();
          if (reduced) {
            expect(tester.getSize(find.byType(FSidebar)).width, 105);
          } else {
            for (var i = 0; i < 5; i++) {
              await tester.pump(const Duration(milliseconds: 16));
              expect(tester.takeException(), isNull);
            }
            settings.setCollapsed(collapsed: false);
            await tester.pump();
            for (var i = 0; i < 15; i++) {
              await tester.pump(const Duration(milliseconds: 16));
              expect(tester.takeException(), isNull);
            }
            expect(tester.getSize(find.byType(FSidebar)).width, 250);
            settings.setCollapsed(collapsed: true);
            await tester.pump();
            for (var i = 0; i < 15; i++) {
              await tester.pump(const Duration(milliseconds: 16));
              expect(tester.takeException(), isNull);
            }
          }
          await tester.pumpAndSettle();
          expect(tester.getSize(find.byType(FSidebar)).width, 105);
          settings.setCollapsed(collapsed: false);
          await tester.pumpAndSettle();
          expect(tester.getSize(find.byType(FSidebar)).width, 250);
          router.go('/unavailable');
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }
}
