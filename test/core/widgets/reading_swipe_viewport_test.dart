import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/core/widgets/reading_swipe_viewport.dart';
import 'package:tawaq/core/widgets/tawaq_scroll_behavior.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

void main() {
  testWidgets('mouse selects reading text while touch and trackpad navigate', (
    t,
  ) async {
    var next = 0;
    var previous = 0;
    String? copied;
    const text = 'Reading text stays selected without changing the verse.';
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData')
          copied = (call.arguments as Map)['text'] as String;
        return null;
      },
    );
    addTearDown(
      () => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: DesktopSelectionArea(
              child: ReadingSwipeViewport(
                viewportMinHeight: 400,
                horizontalPadding: 24,
                topPadding: 24,
                bottomPadding: 24,
                canGoNext: true,
                canGoPrevious: true,
                onNext: () => next++,
                onPrevious: () => previous++,
                textDirection: kReadingPageTurnDirection,
                child: const ScopedSelectableText(
                  text,
                  style: TextStyle(fontSize: 20),
                  textDirection: TextDirection.ltr,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    final paragraph = t.renderObject<RenderParagraph>(
      find.descendant(of: find.text(text), matching: find.byType(RichText)),
    );
    Offset caret(int index) => paragraph.localToGlobal(
      paragraph.getOffsetForCaret(TextPosition(offset: index), Rect.zero) +
          const Offset(0, 10),
    );
    final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer();
    for (final offsets in [(2, 25), (29, 5)]) {
      await mouse.down(caret(offsets.$1));
      await t.pump(const Duration(milliseconds: 80));
      for (var step = 1; step <= 10; step++) {
        await mouse.moveTo(
          Offset.lerp(caret(offsets.$1), caret(offsets.$2), step / 10)!,
        );
        await t.pump(const Duration(milliseconds: 40));
      }
      expect(
        find.text('Next'),
        findsNothing,
        reason: 'mouse selection must not show a swipe preview',
      );
      await mouse.up();
      await t.pump();
      expect(next, 0);
      expect(previous, 0);
      await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await t.sendKeyEvent(LogicalKeyboardKey.keyC);
      await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await t.pump();
      expect(
        copied,
        text.substring(
          offsets.$1 < offsets.$2 ? offsets.$1 : offsets.$2,
          offsets.$1 > offsets.$2 ? offsets.$1 : offsets.$2,
        ),
      );
      await t.pump(const Duration(milliseconds: 600));
    }
    await mouse.removePointer();
    final center =
        t.getCenter(find.byType(ReadingSwipeViewport)) + const Offset(0, 100);
    final trackpad = await t.createGesture(kind: PointerDeviceKind.trackpad);
    await trackpad.panZoomStart(center);
    await t.pump();
    await trackpad.panZoomUpdate(center, pan: const Offset(140, 0));
    await t.pump();
    await trackpad.panZoomEnd();
    await t.pumpAndSettle();
    expect(next, 1);
    final touch = await t.startGesture(center, kind: PointerDeviceKind.touch);
    await touch.moveBy(const Offset(-140, 0));
    await t.pump();
    await touch.up();
    await t.pumpAndSettle();
    expect(previous, 1);
    expect(t.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
}
