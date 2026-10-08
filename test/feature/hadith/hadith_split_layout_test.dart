// Fixture overrides belong to an independent root test scope.
// ignore_for_file: riverpod_lint/scoped_providers_should_specify_dependencies

import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:hivez_flutter/hivez_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/core/bootstrap/app_init_providers.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_persisted_settings.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_screen_settings_provider.dart';
import 'package:tawaq/feature/hadith/presentation/screens/hadith_screen.dart';
import 'package:tawaq/hive/hive_registrar.g.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/l10n/app_localizations_delegates.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

class _TestHadithScreenSettings extends HadithScreenSettingsNotifier {
  @override
  Future<HadithPersistedSettings> build() async =>
      const HadithPersistedSettings();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    Hive
      ..init('./test/hive_test_db')
      ..registerAdapters();
  });

  Widget wrap({required double containerWidth, required Widget child}) {
    final theme = buildAppTheme(
      palette: AppPalette.neutral,
      themeMode: ThemeMode.light,
      touch: false,
      textScale: 1,
    );

    return ProviderScope(
      overrides: [
        dorarInitProvider.overrideWith((ref) async {}),
        hiveCoreInitProvider.overrideWith((ref) async {}),
        hadithScreenSettingsProvider.overrideWith(
          _TestHadithScreenSettings.new,
        ),
      ],
      child: FTheme(
        data: theme,
        child: MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1024, 768)),
            child: Row(
              children: [
                SizedBox(width: containerWidth, height: 700, child: child),
                const Expanded(child: SizedBox.shrink()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> pumpHadithLayout(
    WidgetTester tester, {
    required double containerWidth,
    required Widget child,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1024, 768));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(wrap(containerWidth: containerWidth, child: child));
  }

  group('Hadith split layout', () {
    testWidgets(
      'uses stacked layout when container is narrower than split minimum',
      (tester) async {
        await pumpHadithLayout(
          tester,
          containerWidth: 742,
          child: const HadithPage(),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('persisted-split-side')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'leaves an unselected reader closed even when a split would fit',
      (tester) async {
        await pumpHadithLayout(
          tester,
          containerWidth: 900,
          child: const HadithPage(),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('persisted-split-side')),
          findsNothing,
        );
      },
    );
  });
}
