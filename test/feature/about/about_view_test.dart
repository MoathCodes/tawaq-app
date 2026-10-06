import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tawaq/core/utils/external_link_provider.dart';
import 'package:tawaq/core/utils/package_metadata_provider.dart';
import 'package:tawaq/feature/about/data/about_info.dart';
import 'package:tawaq/feature/about/presentation/widgets/about_view.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/l10n/app_localizations_delegates.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

void main() {
  testWidgets(
    'installed version, real destination, and failed-open copy recovery work',
    (tester) async {
      final destinations = <Uri>[];
      final clipboard = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData')
            clipboard.add((call.arguments as Map)['text'] as String);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            packageMetadataProvider.overrideWith(
              (ref) async => PackageInfo(
                appName: 'Tawaq',
                packageName: 'me.moathdev.tawaq',
                version: '2.3.4',
                buildNumber: '56',
              ),
            ),
            externalLinkLauncherProvider.overrideWithValue((uri) async {
              destinations.add(uri);
              return false;
            }),
          ],
          child: FTheme(
            data: buildAppTheme(
              palette: AppPalette.manuscript,
              themeMode: ThemeMode.light,
              touch: false,
              textScale: 1,
            ),
            child: MaterialApp(
              localizationsDelegates: appLocalizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const FToaster(
                child: Scaffold(
                  body: SingleChildScrollView(
                    child: AboutView(content: aboutContent),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('2.3.4+56'), findsOneWidget);
      expect(find.text('Bundled tafsir and translations'), findsNothing);
      await tester.ensureVisible(find.text('Report an issue'));
      await tester.tap(find.text('Report an issue'));
      await tester.pumpAndSettle();
      expect(destinations, [
        Uri.parse('https://github.com/MoathCodes/tawaq-app/issues'),
      ]);
      expect(find.text('Could not open link'), findsOneWidget);
      await tester.tap(find.text('Copy link').last);
      await tester.pumpAndSettle();
      expect(clipboard, ['https://github.com/MoathCodes/tawaq-app/issues']);
    },
  );
}
