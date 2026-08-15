import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_settings.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_settings_provider.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/sections/location_section/location_map_section.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';
import 'package:timezone/data/latest.dart' as tzdata;

class _TestPrayerSettings extends PrayerSettingsNotifier {
  @override
  Future<PrayerSettings> build() async => PrayerSettings.defaultSettings();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(tzdata.initializeTimeZones);

  testWidgets('mapActive false then dispose does not assert', (tester) async {
    final container = ProviderContainer(
      overrides: [
        prayerSettingsProvider.overrideWith(_TestPrayerSettings.new),
      ],
    );
    addTearDown(container.dispose);

    await container.read(prayerSettingsProvider.future);
    final settings = container.read(prayerSettingsProvider).value!;
    final theme = buildAppTheme(
      palette: AppPalette.neutral,
      themeMode: ThemeMode.light,
      touch: false,
      textScale: 1,
    );

    Future<void> pumpMap({required bool mapActive}) {
      return tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: FTheme(
            data: theme,
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: LocationMapContainer(
                  mapActive: mapActive,
                  enabled: true,
                  autoLocation: false,
                  coordinates: settings.coordinates,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Inactive map avoids FmMap/tiles; still exercises flush-on-deactivate + dispose.
    await pumpMap(mapActive: false);
    await tester.pump();

    await pumpMap(mapActive: true);
    await tester.pump();

    await pumpMap(mapActive: false);
    await tester.pump();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
