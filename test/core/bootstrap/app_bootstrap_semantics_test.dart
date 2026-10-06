import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:tawaq/core/storage/settings_storage.dart';
import 'package:tawaq/core/locale/locale_provider.dart';
import 'package:tawaq/core/bootstrap/app_init_providers.dart';
import 'package:tawaq/feature/onboarding/data/models/onboarding_state.dart';
import 'package:tawaq/feature/onboarding/presentation/providers/onboarding_state_provider.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_settings.dart';
import 'package:tawaq/feature/prayer/data/database/prayer_database.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_settings_provider.dart';
import 'package:tawaq/main.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';
import 'package:timezone/data/latest.dart' as tz;

class _PendingOnboarding extends OnboardingStateNotifier {
  @override
  Future<OnboardingState> build() => Completer<OnboardingState>().future;
}

class _PendingPrayerSettings extends PrayerSettingsNotifier {
  @override
  Future<PrayerSettings> build() => Completer<PrayerSettings>().future;
}

class _ReadyOnboarding extends OnboardingStateNotifier {
  @override
  Future<OnboardingState> build() async => const OnboardingState();
}

class _ReadyPrayerSettings extends PrayerSettingsNotifier {
  @override
  Future<PrayerSettings> build() async => PrayerSettings.defaultSettings();
}

class _EnglishLocale extends LocaleNotifier {
  @override
  Future<String> build() async => 'en';
}

void main() {
  setUpAll(tz.initializeTimeZones);
  testWidgets(
    'history startup failure keeps app gated and Retry starts recovery',
    (tester) async {
      final first = Completer<void>();
      final retry = Completer<void>();
      var attempts = 0;
      final theme = buildAppTheme(
        palette: AppPalette.manuscript,
        themeMode: ThemeMode.light,
        touch: false,
        textScale: 1,
      );
      await tester.pumpWidget(
        ProviderScope(
          retry: (_, _) => null,
          overrides: [
            settingsStorageProvider.overrideWith(
              (ref) async => Storage<String, String>.inMemory(),
            ),
            localeProvider.overrideWith(_EnglishLocale.new),
            appBootstrapReadyProvider.overrideWith((ref) async {}),
            onboardingStateProvider.overrideWith(_ReadyOnboarding.new),
            prayerSettingsProvider.overrideWith(_ReadyPrayerSettings.new),
            prayerHistoryReadyProvider.overrideWith(
              (ref) => ++attempts == 1 ? first.future : retry.future,
            ),
            appThemeDataProvider.overrideWithValue(theme),
          ],
          child: const AppBootstrap(),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.byType(TawaqApp), findsNothing);
      first.completeError(StateError('private storage diagnostic'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.text('Could not prepare prayer history. Try again.'),
        findsOneWidget,
      );
      expect(find.textContaining('private storage diagnostic'), findsNothing);
      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(attempts, 2);
      expect(
        find.text('Could not prepare prayer history. Try again.'),
        findsNothing,
      );
      expect(find.byType(TawaqApp), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('bootstrap leaves accessibility ownership with the platform', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final ready = Completer<void>();
    final theme = buildAppTheme(
      palette: AppPalette.manuscript,
      themeMode: ThemeMode.light,
      touch: false,
      textScale: 1,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appBootstrapReadyProvider.overrideWith((ref) => ready.future),
          onboardingStateProvider.overrideWith(_PendingOnboarding.new),
          prayerSettingsProvider.overrideWith(_PendingPrayerSettings.new),
          appThemeDataProvider.overrideWithValue(theme),
        ],
        child: const AppBootstrap(),
      ),
    );

    // A startup-only debugger acquires its own semantics handle and paints a
    // diagnostic overlay into normal launches. Accessibility must instead
    // stay available through replacement of the bootstrap shell.
    expect(find.byType(SemanticsDebugger), findsNothing);
    expect(tester.binding.semanticsEnabled, isTrue);
    ready.completeError(StateError('bootstrap failed'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Could not start Tawaq. Try again.'), findsOneWidget);
    expect(find.textContaining('bootstrap failed'), findsNothing);
    expect(
      tester.getSemantics(find.text('Could not start Tawaq. Try again.')).label,
      contains('Could not start Tawaq'),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    semantics.dispose();
  });
}
