// Fixture overrides belong to an independent root test scope.
// ignore_for_file: riverpod_lint/scoped_providers_should_specify_dependencies

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/feature/quran/presentation/models/quran_ui_models.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_screen_settings_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/share/ayah_share_dialog.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/l10n/app_localizations_delegates.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

class _Controller extends Mock implements MushafReaderController {}

class _Settings extends QuranScreenSettingsNotifier {
  @override
  Future<QuranScreenState> build() async => QuranScreenState.initial();
}

void main() {
  testWidgets(
    'failed share page disables exports and retries without diagnostics',
    (tester) async {
      final controller = _Controller();
      final first = Completer<QuranPage>();
      final retry = Completer<QuranPage>();
      final ready = Completer<QuranPage>();
      var attempts = 0;
      when(() => controller.getPage(1)).thenAnswer(
        (_) => switch (++attempts) {
          1 => first.future,
          2 => retry.future,
          _ => ready.future,
        },
      );
      final ayah = Ayah(
        ayahId: 1,
        juz: 1,
        page: 1,
        surahNumber: 1,
        numberInSurah: 1,
        text: '',
        textPlain: '',
      );
      when(() => controller.getAyah(1)).thenAnswer((_) async => ayah);
      final container = ProviderContainer(
        overrides: [
          quranMushafControllerProvider.overrideWithValue(controller),
          quranScreenSettingsProvider.overrideWith(_Settings.new),
        ],
      );
      addTearDown(container.dispose);
      final theme = buildAppTheme(
        palette: AppPalette.manuscript,
        themeMode: ThemeMode.light,
        touch: false,
        textScale: 1,
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: appLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: FTheme(
              data: theme,
              child: Scaffold(
                body: AyahShareDialog(ayah: ayah, style: theme.dialogStyle),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      FButton exportButton(String label) => tester.widget<FButton>(
        find
            .ancestor(of: find.text(label), matching: find.byType(FButton))
            .first,
      );
      expect(exportButton('Save image').onPress, isNull);
      expect(exportButton('Copy image').onPress, isNull);
      first.completeError(StateError('private database diagnostic'));
      await tester.pumpAndSettle();
      expect(find.text('Could not load this page. Try again.'), findsOneWidget);
      expect(find.textContaining('private database'), findsNothing);
      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(attempts, 2);
      expect(exportButton('Copy image').onPress, isNull);
      expect(find.text('Could not load this page. Try again.'), findsNothing);
      retry.completeError(StateError('second fixture failure'));
      await tester.pumpAndSettle();
      expect(find.text('Retry'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pump();
      // Metadata-only fixture exercises the loaded dialog without inventing
      // religious text. Native confirmation uses the bundled source page.
      ready.complete(
        QuranPage(
          pageNumber: 1,
          glyphText: '',
          lines: const [],
          surahs: [
            SurahBlock(
              surahNumber: 1,
              glyph: '',
              start: 0,
              end: 0,
              hasBasmalah: false,
              ayahs: [AyahFragment(ayahId: 1, start: 0, end: 0)],
            ),
          ],
          juzNumber: 1,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Retry'), findsNothing);
      expect(exportButton('Save image').onPress, isNotNull);
      expect(exportButton('Copy image').onPress, isNotNull);
      expect(find.text('Copy image').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant({TargetPlatform.linux}),
  );
}
