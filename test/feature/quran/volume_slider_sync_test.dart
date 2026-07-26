import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/widgets/volume_slider.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

/// Minimal theme wrapper so the slider renders without a full ProviderScope.
/// The sync logic lives in [PersistedVolumeSlider] and needs no Riverpod scope
/// or live audio service.
Widget _wrap(Widget child) {
  final theme = buildAppTheme(
    palette: AppPalette.neutral,
    themeMode: ThemeMode.light,
    touch: false,
    textScale: 1,
  );
  return FTheme(
    data: theme,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: SizedBox(width: 320, child: child),
        ),
      ),
    ),
  );
}

/// Finds the widest [GestureDetector] descendant of the slider — that is the
/// track's hit region (the thumb detector is only `thumbSize` wide). Tapping
/// its center lands on the track and moves the value, so we can assert the
/// debounce contract without depending on exact track geometry.
Future<Offset> _trackCenter(WidgetTester tester) async {
  final gdFinder = find.descendant(
    of: find.byType(FSlider),
    matching: find.byType(GestureDetector),
  );
  var widest = Rect.zero;
  for (final gd in tester.widgetList<GestureDetector>(gdFinder)) {
    final rect = tester.getRect(find.byWidget(gd));
    if (rect.width > widest.width) widest = rect;
  }
  expect(widest, isNot(Rect.zero), reason: 'track gesture detector not found');
  return widest.center;
}

void main() {
  group('PersistedVolumeSlider', () {
    testWidgets(
      'reflects externally-changed persisted volume without emitting a preview',
      (tester) async {
        final previews = <double>[];

        await tester.pumpWidget(
          _wrap(PersistedVolumeSlider(
            persistedVolume: 80,
            onPreview: previews.add,
            onCommit: (_) {},
          )),
        );
        await tester.pumpAndSettle();
        expect(previews, isEmpty);

        await tester.pumpWidget(
          _wrap(PersistedVolumeSlider(
            persistedVolume: 40,
            onPreview: previews.add,
            onCommit: (_) {},
          )),
        );
        await tester.pumpAndSettle();
        expect(previews, isEmpty);

        final trackPoint = await _trackCenter(tester);
        final gesture = await tester.startGesture(trackPoint);
        await tester.pump();
        await gesture.up();
        await tester.pump();

        expect(previews, hasLength(1));
        expect(previews.first, lessThan(80));
      },
    );

    testWidgets('fires preview immediately when the value changes', (tester) async {
      final previews = <double>[];
      final commits = <double>[];

      await tester.pumpWidget(
        _wrap(PersistedVolumeSlider(
          // Start at 80%; tapping the track center moves it to ~50%, a real
          // change that triggers onChange.
          persistedVolume: 80,
          onPreview: previews.add,
          onCommit: commits.add,
        )),
      );
      await tester.pumpAndSettle();

      final trackPoint = await _trackCenter(tester);

      final gesture = await tester.startGesture(trackPoint);
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(previews, hasLength(1));
      expect(previews.first, greaterThanOrEqualTo(0));
      expect(previews.first, lessThan(80));
      expect(commits, hasLength(1));
    });

    testWidgets('disabled slider does not emit previews or commits',
        (tester) async {
      final previews = <double>[];
      final commits = <double>[];

      await tester.pumpWidget(
        _wrap(PersistedVolumeSlider(
          persistedVolume: 50,
          enabled: false,
          onPreview: previews.add,
          onCommit: commits.add,
        )),
      );
      await tester.pumpAndSettle();

      // Disabled sliders have no track gesture detector (forui omits it when
      // !enabled), so any interaction is inert.
      final point = tester.getCenter(find.byType(FSlider));
      final gesture = await tester.startGesture(point);
      await tester.pump();
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 100));

      expect(previews, isEmpty);
      expect(commits, isEmpty);
    });
  });
}
