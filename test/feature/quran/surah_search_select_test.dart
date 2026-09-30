import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/surah_selector.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/l10n/app_localizations_delegates.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

class _Controller extends Mock implements MushafReaderController {}

void main() {
  for (final language in ['en', 'ar']) {
    testWidgets(
      'Surah picker exposes searchable names in $language',
      (
        tester,
      ) async {
        final controller = _Controller();
        final surah = Surah(
          number: 2,
          glyph: '',
          hasBasmalah: true,
          nameEnglish: 'Al-Baqara',
          nameArabic: 'سورة البقرة',
          englishNameTranslation: 'The Cow',
        );
        when(controller.getAllSurahs).thenAnswer((_) async => [surah]);
        int? selected;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              quranMushafControllerProvider.overrideWithValue(controller),
            ],
            child: FTheme(
              data: buildAppTheme(
                palette: AppPalette.manuscript,
                themeMode: ThemeMode.light,
                touch: false,
                textScale: 1,
              ),
              child: MaterialApp(
                locale: Locale(language),
                localizationsDelegates: appLocalizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: Scaffold(
                  body: SurahSearchSelect(
                    value: null,
                    label: 'Surah',
                    onChanged: (value) => selected = value,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byType(SurahSearchSelect));
        await tester.pumpAndSettle();
        expect(find.text('Al-Baqara'), findsOneWidget);
        expect(find.text('سورة البقرة'), findsOneWidget);
        if (language == 'en') {
          expect(find.text('The Cow'), findsOneWidget);
          await tester.enterText(find.byType(TextField).last, 'cow');
          await tester.pumpAndSettle();
          expect(find.text('The Cow'), findsOneWidget);
          await tester.tap(find.text('The Cow'));
        } else {
          await tester.tap(find.text('Al-Baqara'));
        }
        await tester.pumpAndSettle();
        expect(selected, 2);
        expect(tester.takeException(), isNull);
      },
      // Standalone FSelect popovers hit the pinned SDK's merge assertion even
      // before this change. Check rendering/input here; inspect live semantics.
      semanticsEnabled: false,
      variant: const TargetPlatformVariant({TargetPlatform.linux}),
    );
  }
}
