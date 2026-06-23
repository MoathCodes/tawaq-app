import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/core/bootstrap/app_init_providers.dart';
import 'package:tawaq/feature/quran/domain/models/quran_layouts.dart';
import 'package:tawaq/feature/quran/domain/models/quran_screen_state.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/quran_layout_widgets.dart';
import 'package:tawaq/feature/settings/data/migration/state_settings_legacy_migration.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/l10n/app_localizations_en.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

class _TestQuranScreenSettings extends QuranScreenSettingsNotifier {
  @override
  Future<QuranScreenState> build() async {
    return QuranScreenState.initial().copyWith(
      layout: QuranReadingLayout.doublePage,
    );
  }
}

void main() {
  Widget wrap({
    required double width,
    required Widget child,
  }) {
    final theme = buildAppTheme(
      palette: AppPalette.zinc,
      themeMode: ThemeMode.light,
      touch: false,
      textScale: 1,
    );

    return ProviderScope(
      overrides: [
        mushafLibraryInitProvider.overrideWith((ref) async {}),
        stateSettingsLegacyMigrationProvider.overrideWith((ref) async {}),
        quranScreenSettingsProvider.overrideWith(_TestQuranScreenSettings.new),
        quranMushafControllerProvider.overrideWithValue(
          MushafReaderController(),
        ),
        appThemeDataProvider.overrideWithValue(theme),
      ],
      child: FTheme(
        data: theme,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              width: width,
              height: 700,
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  group('QuranMushafPane double-page guard', () {
    testWidgets('falls back to single page below 2× mushaf minimum width',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          width: 700,
          child: const QuranMushafPane(),
        ),
      );
      await tester.pump();

      final reader = tester.widget<MushafReader>(find.byType(MushafReader));
      expect(reader.pagesPerViewport, 1);
      expect(
        find.text(AppLocalizationsEn().quranDoublePageWidthFallback),
        findsOneWidget,
      );
    });

    testWidgets('keeps two-page spread when container is wide enough',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          width: 800,
          child: const QuranMushafPane(),
        ),
      );
      await tester.pump();

      final reader = tester.widget<MushafReader>(find.byType(MushafReader));
      expect(reader.pagesPerViewport, 2);
      expect(find.byType(FAlert), findsNothing);
    });
  });
}
