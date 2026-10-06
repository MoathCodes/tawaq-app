import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/core/widgets/f_skeletonizer.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

void main() {
  testWidgets(
    'reduced motion stops repeating loading frames without removing loading content',
    (tester) async {
      Future<void> pump(bool reduced) => tester.pumpWidget(
        FTheme(
          data: buildAppTheme(
            palette: AppPalette.manuscript,
            themeMode: ThemeMode.light,
            touch: false,
            textScale: 1,
          ),
          child: MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: reduced),
              child: const Scaffold(
                body: FSkeletonizer(child: Text('Loading fixture')),
              ),
            ),
          ),
        ),
      );
      await pump(false);
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.binding.transientCallbackCount, greaterThan(0));
      await pump(true);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Loading fixture'), findsOneWidget);
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
    },
  );
}
