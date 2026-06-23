import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:hivez_flutter/hivez_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/bootstrap/app_init_providers.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_screen_state.dart';
import 'package:tawaq/feature/hadith/presentation/screens/hadith_screen.dart';
import 'package:tawaq/feature/settings/data/migration/state_settings_legacy_migration.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/hive/hive_registrar.g.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

class _TestHadithScreenSettings extends HadithScreenSettingsNotifier {
  @override
  Future<HadithScreenState> build() async => const HadithScreenState();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    Hive
      ..init('./test/hive_test_db')
      ..registerAdapters();
  });

  Widget wrap({
    required double containerWidth,
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
        dorarInitProvider.overrideWith((ref) async {}),
        hiveCoreInitProvider.overrideWith((ref) async {}),
        stateSettingsLegacyMigrationProvider.overrideWith((ref) async {}),
        hadithScreenSettingsProvider.overrideWith(
          _TestHadithScreenSettings.new,
        ),
      ],
      child: FTheme(
        data: theme,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1024, 768)),
            child: Row(
              children: [
                SizedBox(
                  width: containerWidth,
                  height: 700,
                  child: child,
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  group('Hadith split layout', () {
    testWidgets(
      'uses stacked layout when container is narrower than split minimum',
      (tester) async {
        await tester.pumpWidget(
          wrap(
            containerWidth: 742,
            child: const HadithPage(),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('persisted-split-side')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'uses horizontal split when container can honor pane minimums',
      (tester) async {
        await tester.pumpWidget(
          wrap(
            containerWidth: 900,
            child: const HadithPage(),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('persisted-split-side')),
          findsOneWidget,
        );
      },
    );
  });
}
