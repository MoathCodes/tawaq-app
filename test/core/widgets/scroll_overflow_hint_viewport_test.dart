import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/core/widgets/scroll_overflow_hint_viewport.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/l10n/app_localizations_delegates.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

Widget _host({
  required double contentHeight,
  Object? resetTrigger,
  bool reducedMotion = false,
}) => FTheme(
  data: buildAppTheme(
    palette: AppPalette.manuscript,
    themeMode: ThemeMode.light,
    touch: false,
    textScale: 1,
  ),
  child: MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reducedMotion),
      child: child!,
    ),
    localizationsDelegates: appLocalizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SizedBox(
        height: 300,
        child: ScrollOverflowHintViewport(
          resetTrigger: resetTrigger,
          builder: (controller) => SingleChildScrollView(
            controller: controller,
            child: SizedBox(
              height: contentHeight,
              child: const Text('content'),
            ),
          ),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('keyboard activation jumps immediately with reduced motion', (
    tester,
  ) async {
    await tester.pumpWidget(_host(contentHeight: 900, reducedMotion: true));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    final controller = tester
        .widget<SingleChildScrollView>(find.byType(SingleChildScrollView))
        .controller!;
    expect(controller.offset, 225);
    expect(tester.takeException(), isNull);
  });

  testWidgets('initial overflow is actionable and hides at the end', (
    tester,
  ) async {
    await tester.pumpWidget(_host(contentHeight: 900));
    await tester.pumpAndSettle();
    final controller = tester
        .widget<SingleChildScrollView>(find.byType(SingleChildScrollView))
        .controller!;
    expect(
      tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
      1,
    );
    await tester.tap(find.text('More below'));
    await tester.pumpAndSettle();
    expect(controller.offset, greaterThan(0));
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(
      tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
      0,
    );
  });

  testWidgets('late content and step changes update metrics without a scroll', (
    tester,
  ) async {
    await tester.pumpWidget(_host(contentHeight: 100, resetTrigger: 1));
    await tester.pumpAndSettle();
    expect(
      tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
      0,
    );
    await tester.pumpWidget(_host(contentHeight: 900, resetTrigger: 1));
    await tester.pumpAndSettle();
    expect(
      tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
      1,
    );
    await tester.tap(find.text('More below'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(_host(contentHeight: 900, resetTrigger: 2));
    await tester.pumpAndSettle();
    final controller = tester
        .widget<SingleChildScrollView>(find.byType(SingleChildScrollView))
        .controller!;
    expect(controller.offset, 0);
  });
}
