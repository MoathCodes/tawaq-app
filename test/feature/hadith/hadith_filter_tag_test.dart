import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/filters/hadith_filter_tag.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

void main() {
  for (final direction in TextDirection.values) {
    for (final scale in [1.0, 1.5]) {
      testWidgets(
        'long selected source label wraps and can be removed ($direction, $scale)',
        (tester) async {
          const label = 'أحاديث حكم المحدثون على أسانيدها بالضعف، ونحو ذلك';
          final controller = FMultiValueNotifier<String>(value: {'fixture'});
          addTearDown(controller.dispose);
          await tester.pumpWidget(
            MaterialApp(
              home: FTheme(
                data: buildAppTheme(
                  palette: AppPalette.manuscript,
                  themeMode: ThemeMode.dark,
                  touch: false,
                  textScale: scale,
                ),
                child: Directionality(
                  textDirection: direction,
                  child: Scaffold(
                    body: Center(
                      child: SizedBox(
                        width: 252,
                        child: FMultiSelect<String>(
                          tagBuilder: hadithFilterTag,
                          items: const {label: 'fixture'},
                          control: .managed(controller: controller),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final tag = find.byType(FMultiSelectTag);
          expect(tester.getSize(tag).width, lessThanOrEqualTo(252));
          expect(tester.getSize(find.text(label)).height, greaterThan(30));
          expect(tester.takeException(), isNull);
          await tester.tap(find.byIcon(FLucideIcons.x));
          await tester.pumpAndSettle();
          expect(controller.value, isEmpty);
          expect(find.text(label), findsNothing);
        },
      );
    }
  }
}
