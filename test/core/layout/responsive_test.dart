import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/layout/responsive.dart';
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

  group('isContainerAtLeast', () {
    testWidgets('uses container width not viewport width', (tester) async {
      late bool wideContainer;
      late bool narrowContainer;

      await tester.pumpWidget(
        wrap(
          width: 400,
          child: LayoutBuilder(
            builder: (context, viewportConstraints) {
              return Row(
                children: [
                  SizedBox(
                    width: 900,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        wideContainer = isContainerAtLeast(
                          context,
                          constraints,
                          FBreakpoint.md,
                        );
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        narrowContainer = isContainerAtLeast(
                          context,
                          constraints,
                          FBreakpoint.md,
                        );
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );

      expect(wideContainer, isTrue);
      expect(narrowContainer, isFalse);
    });
  });

  group('responsiveColumnCount', () {
    testWidgets('uses one column below sm and three at md+', (tester) async {
      late int narrowCount;
      late int wideCount;

      await tester.pumpWidget(
        wrap(
          width: 500,
          child: LayoutBuilder(
            builder: (context, constraints) {
              narrowCount = responsiveColumnCount(
                context,
                constraints.maxWidth,
                maxColumns: 3,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      await tester.pumpWidget(
        wrap(
          width: 900,
          child: LayoutBuilder(
            builder: (context, constraints) {
              wideCount = responsiveColumnCount(
                context,
                constraints.maxWidth,
                maxColumns: 3,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(narrowCount, 1);
      expect(wideCount, 3);
    });
  });
}
