// Fixture overrides belong to an independent root test scope.
// ignore_for_file: riverpod_lint/scoped_providers_should_specify_dependencies

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:tawaq/core/bootstrap/app_init_providers.dart';
import 'package:tawaq/core/locale/locale_provider.dart';
import 'package:tawaq/core/storage/settings_storage.dart';
import 'package:tawaq/feature/onboarding/data/models/onboarding_state.dart';
import 'package:tawaq/feature/onboarding/presentation/providers/onboarding_state_provider.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_settings.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_settings_provider.dart';
import 'package:tawaq/main.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';
import 'package:timezone/data/latest.dart' as tz;

class _Locale extends LocaleNotifier {
  new(this.language);
  final String language;
  @override
  Future<String> build() async => language;
}

class _Onboarding extends OnboardingStateNotifier {
  new(this.load);
  final Future<OnboardingState> Function() load;
  @override
  Future<OnboardingState> build() => load();
}

class _Prayer extends PrayerSettingsNotifier {
  new(this.load);
  final Future<PrayerSettings> Function() load;
  @override
  Future<PrayerSettings> build() => load();
}

void main() {
  setUpAll(tz.initializeTimeZones);
  for (final failedSource in ['mushaf', 'hive', 'desktop']) {
    testWidgets('startup retries cached $failedSource initialization failure', (
      tester,
    ) async {
      var mushafAttempts = 0;
      var hiveAttempts = 0;
      var desktopAttempts = 0;
      final pending = Completer<void>();
      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          settingsStorageProvider.overrideWith(
            (ref) async => Storage<String, String>.inMemory(),
          ),
          localeProvider.overrideWith(() => _Locale('en')),
          mushafInitProvider.overrideWith((ref) async {
            mushafAttempts++;
            if (failedSource == 'mushaf') {
              if (mushafAttempts == 1)
                throw StateError('private init diagnostic');
              await pending.future;
            }
          }),
          hiveCoreInitProvider.overrideWith((ref) async {
            await ref.watch(mushafInitProvider.future);
            hiveAttempts++;
            if (failedSource == 'hive') {
              if (hiveAttempts == 1)
                throw StateError('private init diagnostic');
              await pending.future;
            }
          }),
          desktopShellInitProvider.overrideWith((ref) async {
            desktopAttempts++;
            if (failedSource == 'desktop') {
              if (desktopAttempts == 1)
                throw StateError('private init diagnostic');
              await pending.future;
            }
          }),
          onboardingStateProvider.overrideWith(
            () => _Onboarding(() => Completer<OnboardingState>().future),
          ),
          prayerSettingsProvider.overrideWith(
            () => _Prayer(() => Completer<PrayerSettings>().future),
          ),
          appThemeDataProvider.overrideWithValue(
            buildAppTheme(
              palette: AppPalette.manuscript,
              themeMode: ThemeMode.light,
              touch: false,
              textScale: 1.2,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const AppBootstrap(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Could not start Tawaq. Try again.'), findsOneWidget);
      expect(find.textContaining('private init diagnostic'), findsNothing);
      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(switch (failedSource) {
        'mushaf' => mushafAttempts,
        'hive' => hiveAttempts,
        _ => desktopAttempts,
      }, 2);
      expect(
        failedSource == 'hive' ? desktopAttempts : hiveAttempts,
        failedSource == 'desktop' ? 1 : 0,
      );
      expect(find.text('Could not start Tawaq. Try again.'), findsNothing);
      expect(find.byType(TawaqApp), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }, variant: TargetPlatformVariant({TargetPlatform.linux}));
  }
  for (final language in ['en', 'ar']) {
    for (final owner in ['core', 'prayer', 'onboarding']) {
      testWidgets(
        '$language $owner startup failure hides diagnostics and retries',
        (tester) async {
          tester.view.physicalSize = const Size(800, 600);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          var attempts = 0;
          final pending = Completer<void>();
          Future<void> load() {
            if (++attempts == 1)
              return Future.error(StateError('private startup diagnostic'));
            return pending.future;
          }

          final container = ProviderContainer(
            retry: (_, _) => null,
            overrides: [
              settingsStorageProvider.overrideWith(
                (ref) async => Storage<String, String>.inMemory(),
              ),
              localeProvider.overrideWith(() => _Locale(language)),
              appBootstrapReadyProvider.overrideWith(
                (ref) => owner == 'core' ? load() : Future.value(),
              ),
              onboardingStateProvider.overrideWith(
                () => _Onboarding(
                  () => owner == 'onboarding'
                      ? load().then((_) => const OnboardingState())
                      : Completer<OnboardingState>().future,
                ),
              ),
              prayerSettingsProvider.overrideWith(
                () => _Prayer(
                  () => owner == 'prayer'
                      ? load().then((_) => PrayerSettings.defaultSettings())
                      : Completer<PrayerSettings>().future,
                ),
              ),
              appThemeDataProvider.overrideWithValue(
                buildAppTheme(
                  palette: AppPalette.manuscript,
                  themeMode: ThemeMode.dark,
                  touch: false,
                  textScale: 1.2,
                ),
              ),
            ],
          );
          addTearDown(container.dispose);
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: const AppBootstrap(),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          final message = language == 'en'
              ? 'Could not start Tawaq. Try again.'
              : 'تعذّر بدء توّاق. حاول مرة أخرى.';
          expect(find.text(message), findsOneWidget);
          expect(
            find.textContaining('private startup diagnostic'),
            findsNothing,
          );
          expect(find.byType(TawaqApp), findsNothing);
          await tester.tap(
            find.text(language == 'en' ? 'Retry' : 'إعادة المحاولة'),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(attempts, 2);
          expect(find.text(message), findsNothing);
          expect(find.byType(TawaqApp), findsNothing);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
        variant: TargetPlatformVariant({TargetPlatform.linux}),
      );
    }
  }
}
