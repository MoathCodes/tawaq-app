import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/core/desktop/omarchy_theme_source.dart';
import 'package:tawaq/feature/settings/data/models/theme_prefs.dart';
import 'package:tawaq/feature/settings/presentation/provider/theme_settings_provider.dart';
import 'package:tawaq/feature/settings/presentation/widgets/theme/app_theme_selector.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/l10n/app_localizations_delegates.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/omarchy_theme_provider.dart';
import 'package:tawaq/theme/theme_model.dart';

class _TestThemeNotifier extends ThemeNotifier {
  @override
  Future<ThemePrefs> build() async => const ThemePrefs(
    appPalette: AppPalette.manuscript,
    themeMode: ThemeMode.light,
  );
}

const _availableTheme = OmarchyThemeSnapshot(
  isAvailable: true,
  values: {
    'mode': 'dark',
    'accent': '#BB9AF7',
    'background': '#05010C',
    'foreground': '#FFFFFF',
  },
);

Widget _host(ProviderContainer container, {Locale? locale}) =>
    UncontrolledProviderScope(
      container: container,
      child: FTheme(
        data: buildAppTheme(
          palette: AppPalette.manuscript,
          themeMode: ThemeMode.light,
          touch: false,
          textScale: 1,
        ),
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: ColorThemeSelectorContent()),
        ),
      ),
    );

ProviderContainer _container({required bool available}) => ProviderContainer(
  overrides: [
    themeProvider.overrideWith(_TestThemeNotifier.new),
    omarchyThemeProvider.overrideWith(
      (ref) => Stream.value(
        available ? _availableTheme : const OmarchyThemeSnapshot.unavailable(),
      ),
    ),
  ],
);

void main() {
  testWidgets('four palettes fit a narrow Arabic settings viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = _container(available: true);
    addTearDown(container.dispose);
    await tester.pumpWidget(_host(container, locale: const Locale('ar')));
    await tester.pumpAndSettle();
    expect(find.text('المريمية'), findsOneWidget);
    await tester.tap(find.text('المريمية'));
    await tester.pumpAndSettle();
    expect(container.read(themeProvider).value?.appPalette, AppPalette.sage);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selects Sage alongside existing palettes', (tester) async {
    final container = _container(available: false);
    addTearDown(container.dispose);
    await tester.pumpWidget(_host(container));
    await tester.pump();
    expect(find.text('Sage'), findsOneWidget);
    await tester.tap(find.text('Sage'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(container.read(themeProvider).value?.appPalette, AppPalette.sage);
  });

  testWidgets('hides Omarchy when no active Omarchy palette is available', (
    tester,
  ) async {
    final container = _container(available: false);
    addTearDown(container.dispose);

    await tester.pumpWidget(_host(container));
    await tester.pump();

    expect(find.text('Omarchy'), findsNothing);
  });

  testWidgets('shows and selects Omarchy when its palette is available', (
    tester,
  ) async {
    final container = _container(available: true);
    addTearDown(container.dispose);

    await tester.pumpWidget(_host(container));
    await tester.pump();

    expect(find.text('Omarchy'), findsOneWidget);
    await tester.tap(find.text('Omarchy'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(container.read(themeProvider).value?.appPalette, AppPalette.omarchy);
  });
}
