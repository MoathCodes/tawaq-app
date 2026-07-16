import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/recitation_drawer.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

Widget _wrap(Widget child) {
  final theme = buildAppTheme(
    palette: AppPalette.zinc,
    themeMode: ThemeMode.light,
    touch: false,
    textScale: 1,
  );
  return FTheme(
    data: theme,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  group('drawer playback status', () {
    testWidgets('loop label visible on first frame when rangeRepeatCount > 1',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          drawerPlaybackStatusForTest(
            rangeLabel: 'Al-Fatihah',
            rangeRepeatCount: 2,
            repeatsRemaining: 2,
            ayahRepeatCount: 1,
            currentAyah: 3,
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('Loop 1 of 2'), findsOneWidget);
      expect(find.textContaining('Ayah 3'), findsOneWidget);

      final opacityWidgets = tester.widgetList<Opacity>(
        find.ancestor(
          of: find.textContaining('Loop 1 of 2'),
          matching: find.byType(Opacity),
        ),
      );
      for (final widget in opacityWidgets) {
        expect(widget.opacity, greaterThan(0));
      }
    });
  });
}
