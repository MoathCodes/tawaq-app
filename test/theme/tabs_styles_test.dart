import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme.dart';
import 'package:tawaq/theme/theme_model.dart';

FThemeData _theme({double textScale = 1}) => buildAppTheme(
  palette: AppPalette.manuscript,
  themeMode: ThemeMode.light,
  touch: false,
  textScale: textScale,
);

Widget _host({required Widget child, FThemeData? theme}) => FTheme(
  data: theme ?? _theme(),
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  ),
);

void main() {
  group('AppTabsStyles', () {
    test('standard is installed as the app-wide tabs style', () {
      final theme = _theme();
      expect(theme.tabsStyle, same(theme.tabs.standard));
    });

    test('every variant rounds its track and indicator identically', () {
      final theme = _theme();
      BorderRadiusGeometry radiusOf(Decoration decoration) {
        final shape = (decoration as ShapeDecoration).shape;
        return (shape as RoundedSuperellipseBorder).borderRadius;
      }

      final radii = [
        for (final tabs in [
          theme.tabs.standard,
          theme.tabs.compact,
          theme.tabs.primary,
        ]) ...[radiusOf(tabs.decoration), radiusOf(tabs.indicatorDecoration)],
      ];

      expect(radii, everyElement(theme.radii.md));
    });

    test('primary tints the indicator with the palette primary', () {
      final theme = _theme();
      final indicator = theme.tabs.primary.indicatorDecoration;

      expect(indicator, isA<ShapeDecoration>());
      expect(
        (indicator as ShapeDecoration).color,
        theme.colors.primary.withValues(alpha: 0.18),
      );
      expect(
        theme.tabs.standard.indicatorDecoration,
        isNot(theme.tabs.primary.indicatorDecoration),
      );
    });

    test('compact reuses the primary treatment at a smaller scale', () {
      final theme = _theme();

      expect(theme.tabs.compact.decoration, theme.tabs.primary.decoration);
      expect(
        theme.tabs.compact.indicatorDecoration,
        theme.tabs.primary.indicatorDecoration,
      );
      expect(
        theme.tabs.compact.minHeight,
        lessThan(theme.tabs.primary.minHeight),
      );
    });

    test('compact is denser than standard and adds no gap below the bar', () {
      final theme = _theme();

      expect(
        theme.tabs.compact.minHeight,
        lessThan(theme.tabs.standard.minHeight),
      );
      expect(theme.tabs.compact.spacing, 0);
      expect(
        theme.tabs.compact.labelTextStyle.resolve({}).fontSize,
        lessThan(theme.tabs.standard.labelTextStyle.resolve({}).fontSize!),
      );
    });

    test('label styles follow the persisted app text scale', () {
      final small = _theme(textScale: 0.9).tabs.primary;
      final large = _theme(textScale: 1.2).tabs.primary;

      expect(
        large.labelTextStyle.resolve({}).fontSize,
        greaterThan(small.labelTextStyle.resolve({}).fontSize!),
      );
    });
  });

  group('compact tabs in an unbounded row', () {
    // Mirrors the Quran header, where the layout tabs sit in a
    // `Row(mainAxisSize: min)` that hands children unbounded width.
    Widget bar(int index, ValueChanged<int> onChange) => Builder(
      builder: (context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IntrinsicWidth(
            child: FTabs(
              style: context.theme.tabs.compact,
              control: FTabControl.lifted(index: index, onChange: onChange),
              children: const [
                FTabEntry(label: Text('Double page'), child: SizedBox.shrink()),
                FTabEntry(label: Text('Study'), child: SizedBox.shrink()),
              ],
            ),
          ),
          const Text('trailing'),
        ],
      ),
    );

    testWidgets('lays out without overflow and reports taps', (tester) async {
      var index = 0;
      await tester.pumpWidget(
        _host(child: bar(index, (value) => index = value)),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Double page'), findsOneWidget);
      expect(find.text('trailing'), findsOneWidget);

      await tester.tap(find.text('Study'));
      await tester.pumpAndSettle();

      expect(index, 1);
    });

    testWidgets('sizes both tabs to the widest label', (tester) async {
      await tester.pumpWidget(_host(child: bar(0, (_) {})));
      await tester.pumpAndSettle();

      final wide = tester.getSize(find.text('Double page')).width;
      final narrow = tester.getSize(find.text('Study')).width;
      expect(wide, greaterThan(narrow));

      // Neither label is squeezed below its natural width.
      expect(
        tester.renderObject<RenderBox>(find.text('Double page')).size.width,
        wide,
      );
    });
  });
}
