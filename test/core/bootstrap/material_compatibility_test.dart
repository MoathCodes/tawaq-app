import 'package:flutter/material.dart' as legacy;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/l10n/app_localizations_delegates.dart';

void main() {
  for (final locale in ['en', 'ar']) {
    testWidgets('legacy fields retain the dark theme and $locale labels', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          locale: Locale(locale),
          supportedLocales: const [Locale('en'), Locale('ar')],
          localizationsDelegates: appLocalizationsDelegates,
          // free_map, fl_chart and mushaf_reader still use legacy Material.
          builder: (_, child) => MaterialUiCompatibilityBridge(child: child!),
          home: const legacy.Scaffold(body: legacy.TextField()),
        ),
      );
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(legacy.TextField));
      expect(legacy.Theme.of(context).brightness, Brightness.dark);
      expect(
        legacy.MaterialLocalizations.of(context).copyButtonLabel,
        locale == 'ar' ? 'نسخ' : 'Copy',
      );
      await tester.enterText(find.byType(legacy.TextField), 'Tawaq');
      expect(find.text('Tawaq'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
