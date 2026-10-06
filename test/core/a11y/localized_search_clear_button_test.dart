import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/core/widgets/localized_search_clear_button.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/l10n/app_localizations_delegates.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

void main() {
  for (final language in ['en', 'ar']) {
    testWidgets(
      '$language clear search has a localized action and clears the field',
      (tester) async {
        final semantics = tester.ensureSemantics();

        final controller = TextEditingController(text: 'fixture');
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          FTheme(
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
              home: Scaffold(
                body: FTextField(
                  control: .managed(controller: controller),
                  clearable: (value) => value.text.isNotEmpty,
                  clearIconBuilder: localizedSearchClearButton,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final clear = find.bySemanticsLabel(
          language == 'ar' ? 'مسح البحث' : 'Clear search',
        );
        expect(clear, findsOneWidget);
        await tester.tap(clear);
        await tester.pumpAndSettle();
        expect(controller.text, isEmpty);
        expect(clear, findsNothing);
        expect(tester.takeException(), isNull);
        semantics.dispose();
      },
    );
  }
}
