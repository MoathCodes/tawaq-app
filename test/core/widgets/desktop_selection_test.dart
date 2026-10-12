import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/core/widgets/tawaq_scroll_behavior.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

void main() {
  for (final rich in [false, true]) {
    testWidgets(
      'successive RTL ${rich ? 'rich' : 'plain'} drags replace the anchor',
      (tester) async {
        final font = FontLoader('IBMPlexSansArabic')
          ..addFont(
            rootBundle.load(
              'assets/fonts/IBM_Plex_Sans_Arabic/IBMPlexSansArabic-Regular.ttf',
            ),
          );
        await font.load();
        const text =
            'نص تجريبي لاختبار تحديد الكلمات العربية في السطر الأول ثم السطر التالي دون تعديل المصدر.';
        const style = TextStyle(
          fontFamily: 'IBMPlexSansArabic',
          fontSize: 24,
          height: 1.8,
        );
        await tester.pumpWidget(
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
                body: Directionality(
                  textDirection: TextDirection.rtl,
                  child: SingleChildScrollView(
                    child: Align(
                      alignment: Alignment.topRight,
                      child: SizedBox(
                        width: 480,
                        child: rich
                            ? const ScopedSelectableRichText(
                                TextSpan(text: text, style: style),
                              )
                            : const ScopedSelectableText(
                                text,
                                style: style,
                                textDirection: TextDirection.rtl,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        String? copied;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'Clipboard.setData') {
              copied = (call.arguments as Map)['text'] as String;
            }
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer();
        for (final offsets in [(5, 20), (48, 32), (25, 64), (12, 28)]) {
          final paragraph = tester.renderObject<RenderParagraph>(
            find.byType(RichText).last,
          );
          Offset point(int index) => paragraph.localToGlobal(
            paragraph.getOffsetForCaret(
                  TextPosition(offset: index),
                  Rect.zero,
                ) +
                const Offset(0, 16),
          );
          int offset(Offset p) =>
              paragraph.getPositionForOffset(paragraph.globalToLocal(p)).offset;
          final start = point(offsets.$1);
          final end = point(offsets.$2);
          final anchor = offset(start);
          final extent = offset(end);
          await mouse.down(start);
          await tester.pump(const Duration(milliseconds: 80));
          for (var step = 1; step <= 10; step++) {
            await mouse.moveTo(Offset.lerp(start, end, step / 10)!);
            await tester.pump(const Duration(milliseconds: 40));
          }
          await mouse.up();
          await tester.pump();
          await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
          await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
          await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
          await tester.pump();
          expect(
            copied,
            text.substring(
              anchor < extent ? anchor : extent,
              anchor > extent ? anchor : extent,
            ),
            reason: 'new drag $offsets must not extend the old selection',
          );
          await tester.pump(const Duration(milliseconds: 100));
        }
        await mouse.removePointer();
      },
      variant: TargetPlatformVariant.only(TargetPlatform.linux),
    );
  }
  testWidgets(
    'one reading region selects across paragraphs, excludes controls, and honours Shift',
    (tester) async {
      const first = 'First reading paragraph remains exact.';
      const second = 'Second reading paragraph has a fresh anchor.';
      const style = TextStyle(fontSize: 20, height: 1.5);
      await tester.pumpWidget(
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
            home: const Scaffold(
              body: DesktopSelectionArea(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      ScopedSelectableText(
                        first,
                        style: style,
                        textDirection: TextDirection.ltr,
                      ),
                      NonSelectable(
                        child: ScopedSelectableText(
                          'Control label',
                          style: style,
                        ),
                      ),
                      ScopedSelectableRichText(
                        TextSpan(text: second, style: style),
                        textDirection: TextDirection.ltr,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      Future<void> copy() async {
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pump();
      }

      Offset caret(String text, int offset) {
        final p = tester.renderObject<RenderParagraph>(
          find.descendant(of: find.text(text), matching: find.byType(RichText)),
        );
        return p.localToGlobal(
          p.getOffsetForCaret(TextPosition(offset: offset), Rect.zero) +
              const Offset(0, 10),
        );
      }

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer();
      Future<void> drag(Offset start, Offset end) async {
        await mouse.down(start);
        await tester.pump(const Duration(milliseconds: 80));
        for (var step = 1; step <= 10; step++) {
          await mouse.moveTo(Offset.lerp(start, end, step / 10)!);
          await tester.pump(const Duration(milliseconds: 40));
        }
        await mouse.up();
        await tester.pump();
        await copy();
      }

      await drag(caret(first, 6), caret(second, 12));
      expect(copied, '${first.substring(6)}\n${second.substring(0, 12)}');
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await copy();
      expect(copied, '$first\n${second.substring(0, 12)}');
      await tester.pump(const Duration(milliseconds: 600));
      await drag(caret(second, 18), caret(second, 26));
      expect(copied, second.substring(18, 26));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      expect(
        HardwareKeyboard.instance.logicalKeysPressed,
        contains(LogicalKeyboardKey.shiftLeft),
      );
      await mouse.down(caret(second, 32));
      await tester.pump(const Duration(milliseconds: 150));
      await mouse.up();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      await copy();
      expect(copied, second.substring(18, 32));
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
      await copy();
      expect(copied, '$first\n$second');
      await mouse.removePointer();
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );
  testWidgets(
    'selection preserves links, input keys, and inner contextual shortcuts',
    (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      var links = 0;
      var shortcuts = 0;
      final recognizer = TapGestureRecognizer()..onTap = () => links++;
      final controller = TextEditingController(
        text: 'Editable input stays independent',
      );
      addTearDown(recognizer.dispose);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
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
                child: CallbackShortcuts(
                  bindings: {
                    const SingleActivator(LogicalKeyboardKey.f1): () =>
                        shortcuts++,
                  },
                  child: DesktopSelectionFocusAnchor(
                    child: Column(
                      children: [
                        ScopedSelectableRichText(
                          TextSpan(
                            style: const TextStyle(fontSize: 24),
                            children: [
                              const TextSpan(text: 'Before '),
                              TextSpan(
                                text: 'inline link',
                                recognizer: recognizer,
                              ),
                              const TextSpan(text: ' after text.'),
                            ],
                          ),
                          textDirection: TextDirection.ltr,
                        ),
                        TextField(controller: controller, maxLines: 3),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final paragraph = tester.renderObject<RenderParagraph>(
        find.byType(RichText).first,
      );
      Offset caret(int index) => paragraph.localToGlobal(
        paragraph.getOffsetForCaret(TextPosition(offset: index), Rect.zero) +
            const Offset(0, 12),
      );
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer();
      await mouse.down(caret(10));
      await tester.pump();
      await mouse.up();
      await tester.pumpAndSettle();
      expect(links, 1);
      await tester.pump(const Duration(milliseconds: 600));
      await mouse.down(caret(2));
      await tester.pump();
      await mouse.moveTo(caret(26));
      await tester.pump();
      await mouse.up();
      await tester.pumpAndSettle();
      expect(links, 1, reason: 'dragging across a link must not open it');
      await tester.sendKeyEvent(LogicalKeyboardKey.f1);
      expect(shortcuts, 1);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
      expect(copied, 'Before inline link after text.'.substring(2, 26));
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      expect(
        controller.selection,
        TextSelection(baseOffset: 0, extentOffset: controller.text.length),
      );
      await tester.enterText(
        find.byType(TextField),
        'First input line.\nSecond input line.',
      );
      controller.selection = const TextSelection.collapsed(offset: 4);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(controller.selection.baseOffset, greaterThan(4));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      expect(controller.selection, const TextSelection.collapsed(offset: 4));
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      expect(controller.selection.baseOffset, 4);
      expect(controller.selection.extentOffset, greaterThan(4));
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      expect(controller.selection, const TextSelection.collapsed(offset: 4));
      expect(tester.takeException(), isNull);
      await mouse.removePointer();
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );
}
