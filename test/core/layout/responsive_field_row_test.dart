import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/layout/responsive_field_row.dart';
import 'package:tawaq/theme/durations.dart';
import 'package:tawaq/theme/radii.dart';

void main() {
  Widget wrap({required double width, required Widget child}) {
    return FTheme(
      data: FThemeData(
        colors: FTheme.neutral.light.desktop.colors,
        typography: FTheme.neutral.light.desktop.typography,
        icons: FTheme.neutral.light.desktop.icons,
        touch: false,
        extensions: const [AppRadii.standard(), AppDurations.standard()],
      ),
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(width: width, child: child),
        ),
      ),
    );
  }

  group('ResponsiveFieldRow', () {
    testWidgets('stacks children below the sm breakpoint', (tester) async {
      const fieldA = Key('field-a');
      const fieldB = Key('field-b');

      await tester.pumpWidget(
        wrap(
          width: 500,
          child: const ResponsiveFieldRow(
            children: [
              SizedBox(key: fieldA, height: 24, width: 120),
              SizedBox(key: fieldB, height: 24, width: 120),
            ],
          ),
        ),
      );

      final topA = tester.getTopLeft(find.byKey(fieldA));
      final topB = tester.getTopLeft(find.byKey(fieldB));

      expect(topB.dy, greaterThan(topA.dy));
      expect(find.byType(Row), findsNothing);
    });

    testWidgets('lays out children in a row at sm width and above', (
      tester,
    ) async {
      const fieldA = Key('field-a');
      const fieldB = Key('field-b');

      await tester.pumpWidget(
        wrap(
          width: 720,
          child: const ResponsiveFieldRow(
            children: [
              SizedBox(key: fieldA, height: 24, width: 120),
              SizedBox(key: fieldB, height: 24, width: 120),
            ],
          ),
        ),
      );

      final topA = tester.getTopLeft(find.byKey(fieldA));
      final topB = tester.getTopLeft(find.byKey(fieldB));

      expect(topA.dy, topB.dy);
      expect(topB.dx, greaterThan(topA.dx));
    });
  });
}
