import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/core/widgets/dialog_shell.dart';
import 'package:tawaq/core/widgets/share_card_dialog_layout.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

void main() {
  for (final width in [580.0, 850.0]) {
    testWidgets(
      'share preview and settings stay reachable at body width $width',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1200, 860));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final theme = buildAppTheme(
          palette: AppPalette.manuscript,
          themeMode: ThemeMode.light,
          touch: false,
          textScale: 1,
        );
        await tester.pumpWidget(
          MaterialApp(
            home: FTheme(
              data: theme,
              child: Center(
                child: SizedBox(
                  width: width,
                  height: 480,
                  child: ForuiDialogLayout(
                    style: theme.dialogStyle,
                    title: const Text('Share'),
                    body: ShareCardDialogLayout(
                      preview: const Column(
                        children: [
                          Text('Preview'),
                          Expanded(child: Center(child: Text('Card'))),
                        ],
                      ),
                      settings: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Settings'),
                          FButton(
                            onPress: () {},
                            child: const Text('Choose range'),
                          ),
                          const SizedBox(height: 280),
                          const Text('Last setting'),
                        ],
                      ),
                    ),
                    actions: [
                      FButton(onPress: () {}, child: const Text('Copy')),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.text('Preview').hitTestable(), findsOneWidget);
        expect(find.text('Choose range').hitTestable(), findsOneWidget);
        if (width == 580) {
          await tester.scrollUntilVisible(find.text('Last setting'), 120);
        }
        expect(find.text('Last setting').hitTestable(), findsOneWidget);
        expect(find.text('Copy').hitTestable(), findsOneWidget);
      },
    );
  }
}
