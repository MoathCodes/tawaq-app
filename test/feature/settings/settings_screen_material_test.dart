import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:tawaq/core/storage/settings_storage.dart';
import 'package:tawaq/feature/settings/presentation/screens/settings_screen.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/l10n/app_localizations_delegates.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

void main() {
  for (final locale in ['en', 'ar']) {
    testWidgets(
      'settings tabs survive rebuild and animated disposal in $locale',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        final container = ProviderContainer(
          overrides: [
            settingsStorageProvider.overrideWith(
              (ref) async => Storage<String, String>.inMemory(),
            ),
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
                body: SettingsScreen(
                  tabKey: 'keyboard-shortcuts',
                  onTabChanged: routedTabs.add,
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

        // Leaving while a tab animation is active must release its ticker.
        controller.animateTo(2);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        expect(tester.takeException(), isNull);
        debugDefaultTargetPlatformOverride = null;
      },
    );
  }
}
