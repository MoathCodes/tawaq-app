import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/app/routing/not_found_screen.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/l10n/app_localizations_delegates.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

void main() {
  for (final language in ['en', 'ar']) {
    testWidgets('$language unavailable route stays bounded at compact XL', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final theme = buildAppTheme(
        palette: AppPalette.manuscript,
        themeMode: ThemeMode.dark,
        touch: false,
        textScale: 1.2,
      );
      await tester.pumpWidget(
        FTheme(
          data: theme,
          child: MaterialApp(
            locale: Locale(language),
            localizationsDelegates: appLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const NotFoundScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.textContaining('private invalid URI diagnostic'),
        findsNothing,
      );
      expect(find.byType(FButton), findsOneWidget);
      expect(find.byType(FScaffold), findsOneWidget);
    });
  }
}
