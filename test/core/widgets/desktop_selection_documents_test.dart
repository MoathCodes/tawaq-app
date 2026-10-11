import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/core/widgets/tawaq_scroll_behavior.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

void main() {
  testWidgets(
    'retiring an offstage selection edge does not replay stale geometry',
    (t) async {
      await t.pumpWidget(
        FTheme(
          data: buildAppTheme(
            palette: AppPalette.neutral,
            themeMode: ThemeMode.light,
            touch: false,
            textScale: 1,
          ),
          child: const MaterialApp(
            home: Scaffold(
              body: DesktopSelectionArea(child: SizedBox.expand()),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      final document = find.byType(DesktopSelectionDocument);
      final delegate = t
          .widget<SelectionContainer>(
            find.descendant(
              of: document,
              matching: find.byType(SelectionContainer),
            ),
          )
          .delegate!;
      final anchor = _ClippedSelectable(first: true);
      final edge = _ClippedSelectable(first: false);
      addTearDown(anchor.dispose);
      addTearDown(edge.dispose);
      delegate.add(anchor);
      delegate.add(edge);
      t.binding.scheduleFrame();
      await t.pump();
      delegate.dispatchSelectionEvent(
        const SelectionEdgeUpdateEvent.forStart(globalPosition: Offset(5, 10)),
      );
      delegate.dispatchSelectionEvent(
        const SelectionEdgeUpdateEvent.forEnd(globalPosition: Offset(5, 110)),
      );
      expect(delegate.value.startSelectionPoint, isNotNull);
      expect(delegate.value.endSelectionPoint, isNull);
      expect(delegate.getSelectedContent(), isNotNull);
      delegate.remove(anchor);
      t.binding.scheduleFrame();
      await t.pump();
      expect(t.takeException(), isNull);
      expect(delegate.getSelectedContent(), isNull);
      delegate.remove(edge);
      t.binding.scheduleFrame();
      await t.pump();
      await t.pumpWidget(const SizedBox());
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );
  testWidgets(
    'removing an anchor while the other edge is scrolled away recovers',
    (t) async {
      String? copied;
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
      final visible = ValueNotifier(true);
      final scroll = ScrollController();
      addTearDown(visible.dispose);
      addTearDown(scroll.dispose);
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
            home: Scaffold(
              body: DesktopSelectionArea(
                child: Column(
                  children: [
                    ValueListenableBuilder<bool>(
                      valueListenable: visible,
                      builder: (_, show, _) => show
                          ? const Text(
                              'First reading anchor',
                              style: TextStyle(fontSize: 20),
                            )
                          : const SizedBox(height: 20),
                    ),
                    SizedBox(
                      height: 160,
                      child: SingleChildScrollView(
                        controller: scroll,
                        child: const Column(
                          children: [
                            Text(
                              'Second reading edge',
                              style: TextStyle(fontSize: 20),
                            ),
                            SizedBox(height: 600),
                            Text(
                              'Replacement reading content',
                              style: TextStyle(fontSize: 20),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      Offset caret(String text, int index) {
        final p = t.renderObject<RenderParagraph>(
          find.descendant(of: find.text(text), matching: find.byType(RichText)),
        );
        return p.localToGlobal(
          p.getOffsetForCaret(TextPosition(offset: index), Rect.zero) +
              const Offset(0, 10),
        );
      }

      final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer();
      await mouse.down(caret('First reading anchor', 3));
      await t.pump(const Duration(milliseconds: 80));
      await mouse.moveTo(caret('Second reading edge', 10));
      await t.pump();
      await mouse.up();
      await t.pump();
      scroll.jumpTo(300);
      await t.pumpAndSettle();
      visible.value = false;
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      scroll.jumpTo(scroll.position.maxScrollExtent);
      await t.pumpAndSettle();
      await mouse.down(caret('Replacement reading content', 2));
      await t.pump(const Duration(milliseconds: 80));
      await mouse.moveTo(caret('Replacement reading content', 12));
      await t.pump();
      await mouse.up();
      await t.pump();
      await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await t.sendKeyEvent(LogicalKeyboardKey.keyC);
      await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await t.pump();
      expect(copied, 'Replacement reading content'.substring(2, 12));
      expect(t.takeException(), isNull);
      await mouse.removePointer();
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );
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

// Models a scrollable selectable whose selected endpoint is outside its viewport.
// Removing the other endpoint before a geometry notification exposes the SDK's
// cached start point with a missing start index during its END-first replay.
class _ClippedSelectable extends ChangeNotifier with Selectable {
  _ClippedSelectable({required this.first});
  final bool first;
  bool selected = true;
  @override
  SelectionGeometry get value => SelectionGeometry(
    hasContent: true,
    status: selected ? SelectionStatus.uncollapsed : SelectionStatus.none,
    startSelectionPoint: selected && first
        ? const SelectionPoint(
            localPosition: Offset(5, 10),
            lineHeight: 20,
            handleType: TextSelectionHandleType.left,
          )
        : null,
  );
  @override
  Matrix4 getTransformTo(RenderObject? ancestor) =>
      Matrix4.translationValues(0, first ? 0 : 100, 0);
  @override
  Size get size => const Size(100, 20);
  @override
  List<Rect> get boundingBoxes => [Offset.zero & size];
  @override
  int get contentLength => 5;
  @override
  SelectedContent? getSelectedContent() =>
      selected ? const SelectedContent(plainText: 'block') : null;
  @override
  SelectedContentRange? getSelection() => selected
      ? const SelectedContentRange(startOffset: 0, endOffset: 5)
      : null;
  @override
  void pushHandleLayers(LayerLink? startHandle, LayerLink? endHandle) {}
  @override
  SelectionResult dispatchSelectionEvent(SelectionEvent event) {
    if (event is ClearSelectionEvent) {
      selected = false;
      notifyListeners();
      return SelectionResult.none;
    }
    if (!selected) {
      selected = true;
      notifyListeners();
    }
    if (event.type == SelectionEventType.startEdgeUpdate)
      return first ? SelectionResult.end : SelectionResult.previous;
    if (event.type == SelectionEventType.endEdgeUpdate)
      return first ? SelectionResult.next : SelectionResult.end;
    return SelectionResult.none;
  }
}
