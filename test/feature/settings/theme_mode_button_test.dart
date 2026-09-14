import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/widgets/animated_icon_button.dart';
import 'package:tawaq/feature/settings/data/models/theme_prefs.dart';
import 'package:tawaq/feature/settings/presentation/provider/theme_settings_provider.dart';
import 'package:tawaq/feature/settings/presentation/widgets/theme_mode_button.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

class _TestThemeNotifier extends ThemeNotifier {
  new(this.palette);

  final AppPalette palette;

  @override
  Future<ThemePrefs> build() async => ThemePrefs(
    appPalette: palette,
    themeMode: ThemeMode.light,
  );
}

Widget _host(ProviderContainer container) => UncontrolledProviderScope(
  container: container,
  child: FTheme(
    data: buildAppTheme(
      palette: AppPalette.manuscript,
      themeMode: ThemeMode.light,
      touch: false,
      textScale: 1,
    ),
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: ThemeModeButton()),
    ),
  ),
);

ProviderContainer _container(AppPalette palette) => ProviderContainer(
  overrides: [
    themeProvider.overrideWith(() => _TestThemeNotifier(palette)),
  ],
);

void main() {
  testWidgets('hides the mode button for Omarchy', (tester) async {
    final container = _container(AppPalette.omarchy);
    addTearDown(container.dispose);

    await tester.pumpWidget(_host(container));
    await tester.pump();

    expect(find.byType(AnimatedIconButton), findsNothing);
  });

  testWidgets('keeps the mode button for regular palettes', (tester) async {
    final container = _container(AppPalette.manuscript);
    addTearDown(container.dispose);

    await tester.pumpWidget(_host(container));
    await tester.pump();

    expect(find.byType(AnimatedIconButton), findsOneWidget);
  });
}
