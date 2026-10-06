// Fixture overrides belong to an independent root test scope.
// ignore_for_file: riverpod_lint/scoped_providers_should_specify_dependencies

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:tawaq/core/storage/settings_storage.dart';
import 'package:tawaq/feature/prayer/presentation/provider/location_service_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_settings_provider.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_screen_settings_provider.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/sections/location_section/prayer_location_settings.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/widgets/custom_parameters_content.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/l10n/app_localizations_delegates.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() {
  setUpAll(tz.initializeTimeZones);
  for (final language in ['en', 'ar']) {
    for (final (location, available) in [
      (false, false),
      (true, false),
      (true, true),
    ]) {
      final initiallyOpen = location && !available;
      testWidgets(
        '${location ? 'advanced location (service $available)' : 'custom parameters'} stays expanded after settling and theme rebuild in $language',
        (tester) async {
          final container = ProviderContainer(
            overrides: [
              settingsStorageProvider.overrideWith(
                (_) async => Storage<String, String>.inMemory(),
              ),
              deviceLocationAvailableProvider.overrideWith(
                (_) async => available,
              ),
            ],
          );
          addTearDown(container.dispose);
          await container.read(prayerSettingsProvider.future);
          await container.read(settingsScreenSettingsProvider.future);
          await container
              .read(prayerSettingsProvider.notifier)
              .update(
                (settings) =>
                    settings.copyWith(coordinates: Coordinates(24, 46)),
              );
          final l10n = lookupAppLocalizations(Locale(language));
          var mode = ThemeMode.light;
          Widget host() => UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              locale: Locale(language),
              localizationsDelegates: appLocalizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: FTheme(
                data: buildAppTheme(
                  palette: AppPalette.manuscript,
                  themeMode: mode,
                  touch: false,
                  textScale: 1.2,
                ),
                child: Scaffold(
                  body: SingleChildScrollView(
                    child: location
                        ? const PrayerLocationSettings(
                            compactMap: true,
                            gateMapToSettingsTab: true,
                          )
                        : const CustomParametersAccordion(),
                  ),
                ),
              ),
            ),
          );

          await tester.pumpWidget(host());
          await tester.pumpAndSettle();
          final title = find.text(
            location
                ? l10n.advancedLocationOptions
                : l10n.customParametersTitle,
          );
          final content = find.text(
            location ? l10n.latitude : l10n.basicParametersTitle,
          );
          expect(
            content.hitTestable(),
            initiallyOpen ? findsOneWidget : findsNothing,
          );
          if (initiallyOpen) {
            await tester.tap(title);
            await tester.pumpAndSettle();
            expect(content.hitTestable(), findsNothing);
          }
          await tester.tap(title);
          await tester.pumpAndSettle();
          expect(content.hitTestable(), findsOneWidget);
          mode = ThemeMode.dark;
          await tester.pumpWidget(host());
          await tester.pumpAndSettle();
          expect(content.hitTestable(), findsOneWidget);
          await tester.tap(title);
          await tester.pumpAndSettle();
          expect(content.hitTestable(), findsNothing);
          await tester.tap(title);
          await tester.pumpAndSettle();
          expect(content.hitTestable(), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
        variant: TargetPlatformVariant({TargetPlatform.linux}),
      );
    }
  }
}
