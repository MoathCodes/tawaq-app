import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/widgets/dialog_shell.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

void main() {
  Widget wrap({
    required Size viewport,
    required Widget child,
  }) {
    final theme = buildAppTheme(
      palette: AppPalette.zinc,
      themeMode: ThemeMode.light,
      touch: false,
      textScale: 1,
    );

    return FTheme(
      data: theme,
      child: MediaQuery(
        data: MediaQueryData(size: viewport),
        child: MaterialApp(home: Scaffold(body: child)),
      ),
    );
  }

  group('TawaqDialogShell', () {
    testWidgets('clamps preferred width to viewport at 400px', (tester) async {
      await tester.pumpWidget(
        wrap(
          viewport: const Size(400, 800),
          child: const Center(
            child: TawaqDialogShell(
              title: 'Reciter',
              child: SizedBox(height: 120),
            ),
          ),
        ),
      );

      final shellBox = tester.renderObject<RenderBox>(
        find.descendant(
          of: find.byType(TawaqDialogShell),
          matching: find.byType(Container).first,
        ),
      );

      // 400 * 0.9 viewport cap beats the 520 preferred width.
      expect(shellBox.size.width, 360);
    });

    testWidgets('respects preferred width on wide viewports', (tester) async {
      await tester.pumpWidget(
        wrap(
          viewport: const Size(1200, 900),
          child: const Center(
            child: TawaqDialogShell(
              title: 'Reciter',
              child: SizedBox(height: 120),
            ),
          ),
        ),
      );

      final shellBox = tester.renderObject<RenderBox>(
        find.descendant(
          of: find.byType(TawaqDialogShell),
          matching: find.byType(Container).first,
        ),
      );

      expect(shellBox.size.width, 520);
    });
  });
}
