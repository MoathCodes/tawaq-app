import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/core/widgets/tawaq_scroll_behavior.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

void main() {
  testWidgets('sibling documents retain block boundary', (t) async {
    await t.pumpWidget(
      FTheme(
        data: buildAppTheme(
          palette: AppPalette.neutral,
          themeMode: ThemeMode.light,
          touch: false,
          textScale: 1,
        ),
        child: MaterialApp(
          scrollBehavior: const TawaqAppScrollBehavior(),
          home: const Scaffold(
            body: DesktopSelectionArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    DesktopSelectionDocument(
                      child: Column(children: [Text('first'), Text('second')]),
                    ),
                    DesktopSelectionDocument(
                      child: Column(children: [Text('third'), Text('fourth')]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    String? copied;
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (c) async {
        if (c.method == 'Clipboard.setData') {
          copied = (c.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final m = await t.createGesture(kind: PointerDeviceKind.mouse);
    await m.addPointer();
    final p = t.getCenter(find.text('first'));
    await m.down(p);
    await t.pump(const Duration(milliseconds: 80));
    await m.moveTo(p + const Offset(12, 0));
    await t.pump();
    await m.up();
    await t.pump();
    await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.keyA);
    await t.sendKeyEvent(LogicalKeyboardKey.keyC);
    await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await t.pump();
    expect(copied, 'first\nsecond\nthird\nfourth');
    await m.removePointer();
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
}
