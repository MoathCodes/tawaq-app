import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/detail/hadith_detail_pane.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/l10n/app_localizations_delegates.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

void main() {
  testWidgets('failed detail keeps a named retry and recovers in place', (
    tester,
  ) async {
    var retries = 0;
    Future<void> pump(AsyncValue<String> value) => tester.pumpWidget(
      FTheme(
        data: buildAppTheme(
          palette: AppPalette.manuscript,
          themeMode: ThemeMode.light,
          touch: false,
          textScale: 1,
        ),
        child: MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: HadithAsyncDetailsSection<String>(
              value: value,
              onRetry: () => retries++,
              dataBuilder: Text.new,
            ),
          ),
        ),
      ),
    );
    await pump(
      AsyncError(StateError('private network diagnostics'), StackTrace.empty),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('private network'), findsNothing);
    expect(
      find.text('Could not load hadith. Check your connection and try again.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Retry'));
    expect(retries, 1);
    await pump(const AsyncData('fixture source content'));
    await tester.pumpAndSettle();
    expect(find.text('fixture source content'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });
}
