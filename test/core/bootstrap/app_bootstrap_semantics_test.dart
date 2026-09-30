import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/core/bootstrap/app_init_providers.dart';
import 'package:tawaq/feature/onboarding/data/models/onboarding_state.dart';
import 'package:tawaq/feature/onboarding/presentation/providers/onboarding_state_provider.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_settings.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_settings_provider.dart';
import 'package:tawaq/main.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

class _PendingOnboarding extends OnboardingStateNotifier {
  @override
  Future<OnboardingState> build() => Completer<OnboardingState>().future;
}

class _PendingPrayerSettings extends PrayerSettingsNotifier {
  @override
  Future<PrayerSettings> build() => Completer<PrayerSettings>().future;
}

void main() {
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
    expect(find.text('Bad state: bootstrap failed'), findsOneWidget);
    expect(
      tester.getSemantics(find.text('Bad state: bootstrap failed')).label,
      contains('bootstrap failed'),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    semantics.dispose();
  });
}
