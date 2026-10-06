import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:tawaq/core/storage/settings_storage.dart';
import 'package:tawaq/feature/prayer/presentation/provider/location_service_provider.dart';
import 'package:tawaq/feature/settings/presentation/screens/settings_screen.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/l10n/app_localizations_delegates.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

void main() {
  for (final locale in ['en', 'ar']) {
    testWidgets(
      'settings tabs publish taps and swipes once across rebuilds in $locale',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        final container = ProviderContainer(
          overrides: [
            settingsStorageProvider.overrideWith(
              (ref) async => Storage<String, String>.inMemory(),
            ),
            deviceLocationAvailableProvider.overrideWith((ref) async => false),
          ],
        );
        addTearDown(container.dispose);
        final theme = buildAppTheme(
          palette: AppPalette.manuscript,
          themeMode: ThemeMode.dark,
          touch: false,
          textScale: 1,
        );
        final routedTabs = <String>[];
        var routeKey = 'keyboard-shortcuts';
        Widget host() => UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: theme.toApproximateMaterialTheme(),
            locale: Locale(locale),
            localizationsDelegates: appLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: FTheme(
              data: theme,
              child: Scaffold(
                body: StatefulBuilder(
                  builder: (context, update) => SettingsScreen(
                    tabKey: routeKey,
                    onTabChanged: (key) {
                      routedTabs.add(key);
                      update(() => routeKey = key);
                    },
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpWidget(host());
        await tester.pumpAndSettle();
        final controller = tester
            .widget<TabBar>(find.byType(TabBar))
            .controller!;
        expect(controller.index, 3);
        final context = tester.element(find.byType(TabBar));
        expect(
          MaterialLocalizations.of(context).copyButtonLabel,
          locale == 'ar' ? 'نسخ' : 'Copy',
        );
        expect(
          Directionality.of(context),
          locale == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        );

        await tester.pumpWidget(host());
        await tester.pumpAndSettle();
        expect(
          tester.widget<TabBar>(find.byType(TabBar)).controller,
          same(controller),
        );

        await tester.tap(
          find
              .descendant(of: find.byType(TabBar), matching: find.byType(Tab))
              .at(1),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 260));
        await tester.pumpAndSettle();
        expect(controller.index, 1);
        expect(tester.takeException(), isNull);
        expect(routedTabs, [
          'prayer-times',
        ], reason: 'settling publishes exactly once');
        routedTabs.clear();
        await tester.drag(
          find.byType(TabBarView),
          Offset(locale == 'ar' ? 650 : -650, 0),
        );
        await tester.pumpAndSettle();
        expect(controller.index, 2);
        expect(tester.takeException(), isNull);
        expect(routedTabs, ['location']);

        // Leaving while a tab animation is active must release its ticker.
        controller.animateTo(1);
        await tester.pumpWidget(const SizedBox.shrink());
        container.dispose();
        await tester.pump();
        debugDefaultTargetPlatformOverride = null;
      },
    );
  }
}
