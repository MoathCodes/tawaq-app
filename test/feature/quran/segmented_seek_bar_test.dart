import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/segmented_seek_bar.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

Widget _wrap(Widget child, {TextDirection direction = TextDirection.ltr}) {
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
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Directionality(
          textDirection: direction,
          child: Center(child: SizedBox(width: 320, child: child)),
        ),
      ),
    ),
  );
}

const _style = SegmentedSeekBarStyle(
  activeColor: Color(0xFF111111),
  inactiveColor: Color(0xFF999999),
  bufferedColor: Color(0x44111111),
  thumbColor: Color(0xFF111111),
  thumbBorderColor: Color(0xFFFFFFFF),
  repeatBadgeColor: Color(0xFF111111),
  repeatBadgeTextColor: Color(0xFFFFFFFF),
  repeatPulseColor: Color(0xFF111111),
  tooltipBackgroundColor: Color(0xFFFFFFFF),
  tooltipBorderColor: Color(0xFFCCCCCC),
  ayahGlowColor: Color(0xFF111111),
  tooltipTextStyle: TextStyle(color: Color(0xFF111111), fontSize: 12),
  thumbRadius: 8,
  trackHeight: 4,
  previewRadius: BorderRadius.all(Radius.circular(8)),
  thumbTweenDuration: Duration(milliseconds: 1),
  snapScaleDuration: Duration(milliseconds: 1),
  pulseDuration: Duration(milliseconds: 400),
  revealDuration: Duration(milliseconds: 1),
);

List<SeekBarSegment> _segments() => const [
  SeekBarSegment(
    index: 1,
    start: Duration.zero,
    end: Duration(seconds: 5),
  ),
  SeekBarSegment(
    index: 2,
    start: Duration(seconds: 5),
    end: Duration(seconds: 10),
  ),
  SeekBarSegment(
    index: 3,
    start: Duration(seconds: 10),
    end: Duration(seconds: 15),
  ),
];

List<SeekBarSegment> _longSurahSegments(int count, Duration total) {
  final totalMs = total.inMilliseconds;
  final perAyah = totalMs ~/ count;
  return [
    for (var i = 0; i < count; i++)
      SeekBarSegment(
        index: i + 1,
        start: Duration(milliseconds: i * perAyah),
        end: Duration(
          milliseconds: i == count - 1 ? totalMs : (i + 1) * perAyah,
        ),
      ),
  ];
}

SegmentedSeekBar _bar({
  Duration position = Duration.zero,
  Duration duration = const Duration(seconds: 15),
  List<SeekBarSegment>? segments,
  ValueChanged<Duration>? onSeek,
  RepeatStatus? repeat,
  Future<String?> Function(int)? excerpt,
  Object? contentKey,
  bool enabled = true,
}) {
  return SegmentedSeekBar(
    position: position,
    duration: duration,
    segments: segments ?? _segments(),
    onSeek: onSeek ?? (_) {},
    style: _style,
    repeat: repeat,
    enabled: enabled,
    segmentLabel: (index) => 'Ayah $index',
    segmentNumberLabel: (index) => '$index',
    segmentUthmaniExcerpt: excerpt,
    segmentContentKey: contentKey,
    repeatLabel: (current, total) => '$current of $total',
    remainingLabel: (remaining) => '$remaining plays remaining',
    semanticsLabel: 'Recitation position',
    unavailableLabel: 'Unavailable',
  );
}

Future<TestGesture> _hoverAt(
  WidgetTester tester,
  double localX,
) async {
  final bar = find.byType(SegmentedSeekBar);
  final box = tester.renderObject<RenderBox>(bar);
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(
    location: box.localToGlobal(Offset(localX, box.size.height / 2)),
  );
  await tester.pump();
  await gesture.moveTo(
    box.localToGlobal(Offset(localX, box.size.height / 2)),
  );
  await tester.pump();
  return gesture;
}

void main() {
  group('timeline helpers', () {
    test('position resolves containing ayah and clamps at the edges', () {
      final segments = _segments();
      expect(segmentIndexForPosition(segments, const Duration(seconds: 4)), 1);
      expect(segmentIndexForPosition(segments, const Duration(seconds: 5)), 2);
      expect(segmentIndexForPosition(segments, const Duration(seconds: 20)), 3);
      expect(
        segmentIndexForPosition(segments, const Duration(seconds: -1)),
        1,
      );
    });

    test('seek target snaps to the containing ayah start', () {
      expect(
        segmentStartForPosition(_segments(), const Duration(seconds: 9)),
        const Duration(seconds: 5),
      );
    });

    test('preview window stays full and shifts at both ends', () {
      final segments = _longSurahSegments(10, const Duration(seconds: 100));
      expect(
        previewSegmentsForFocus(segments, 1).map((s) => s.index),
        [1, 2, 3, 4, 5],
      );
      expect(
        previewSegmentsForFocus(segments, 6).map((s) => s.index),
        [4, 5, 6, 7, 8],
      );
      expect(
        previewSegmentsForFocus(segments, 10).map((s) => s.index),
        [6, 7, 8, 9, 10],
      );
    });

    test('repeat status derives the current pass from remaining plays', () {
      expect(
        const RepeatStatus(remaining: 2, total: 3, segmentIndex: 1).current,
        2,
      );
      expect(
        const RepeatStatus(remaining: 1, total: 3, segmentIndex: 1).current,
        3,
      );
    });
  });

  group('SegmentedSeekBar', () {
    testWidgets('disabled bar exposes localized unavailable semantics', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          _bar(
            duration: Duration.zero,
            segments: const [],
            enabled: false,
          ),
        ),
      );
      await tester.pump();

      final semantics = tester.getSemantics(find.byType(SegmentedSeekBar));
      expect(semantics.label, 'Recitation position');
      expect(semantics.value, contains('Unavailable'));
      expect(semantics.flagsCollection.isEnabled, Tristate.isFalse);
    });

    testWidgets('idle and hovered states retain one continuous track', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(_bar(position: const Duration(seconds: 7))),
      );
      await tester.pump();

      var paint = tester.widget<CustomPaint>(
        find.byKey(const Key('continuous-seek-track')),
      );
      var painter = paint.painter! as SegmentedTrackPainter;
      expect(painter.previewSegmentIndex, isNull);
      expect(painter.progress, closeTo(7 / 15, 0.001));

      final gesture = await _hoverAt(tester, 160);
      paint = tester.widget<CustomPaint>(
        find.byKey(const Key('continuous-seek-track')),
      );
      painter = paint.painter! as SegmentedTrackPainter;
      expect(painter.previewSegmentIndex, 2);
      expect(painter.progress, closeTo(7 / 15, 0.001));
      expect(find.byKey(const Key('ayah-preview-card')), findsOneWidget);

      await gesture.removePointer();
      await tester.pump();
    });

    testWidgets('a 286-ayah timeline reaches the end from a middle entry', (
      tester,
    ) async {
      const total = Duration(minutes: 119, seconds: 41);
      await tester.pumpWidget(
        _wrap(
          _bar(
            position: const Duration(minutes: 40),
            duration: total,
            segments: _longSurahSegments(286, total),
          ),
        ),
      );
      await tester.pump();

      final bar = find.byType(SegmentedSeekBar);
      final box = tester.renderObject<RenderBox>(bar);
      final gesture = await _hoverAt(tester, box.size.width / 2);
      expect(find.text('Ayah 144'), findsOneWidget);

      await gesture.moveTo(
        box.localToGlobal(Offset(box.size.width - _style.thumbRadius, 18)),
      );
      await tester.pump();
      expect(find.text('Ayah 286'), findsOneWidget);

      await gesture.moveTo(
        box.localToGlobal(Offset(_style.thumbRadius, 18)),
      );
      await tester.pump();
      expect(find.text('Ayah 1'), findsOneWidget);

      await gesture.removePointer();
      await tester.pump();
    });

    testWidgets('preview shows five nearby ayat and a Uthmani excerpt', (
      tester,
    ) async {
      final segments = _longSurahSegments(10, const Duration(seconds: 100));
      await tester.pumpWidget(
        _wrap(
          _bar(
            duration: const Duration(seconds: 100),
            segments: segments,
            excerpt: (index) async => 'نص الآية $index',
          ),
        ),
      );
      await tester.pump();

      final gesture = await _hoverAt(tester, 160);
      await tester.pump();

      expect(find.text('Ayah 6'), findsOneWidget);
      expect(find.byKey(const Key('preview-ayah-focused')), findsOneWidget);
      expect(find.text('نص الآية 6'), findsOneWidget);
      for (final ayah in [4, 5, 6, 7, 8]) {
        expect(find.text('$ayah'), findsOneWidget);
      }

      await gesture.removePointer();
      await tester.pump();
    });

    testWidgets('preview card clamps to both track edges', (tester) async {
      await tester.pumpWidget(_wrap(_bar()));
      await tester.pump();
      final bar = find.byType(SegmentedSeekBar);
      final box = tester.renderObject<RenderBox>(bar);
      final gesture = await _hoverAt(tester, _style.thumbRadius);

      var positioned = tester.widget<Positioned>(
        find.byKey(const Key('ayah-preview-positioned')),
      );
      expect(positioned.left, 0);

      await gesture.moveTo(
        box.localToGlobal(Offset(box.size.width - _style.thumbRadius, 18)),
      );
      await tester.pump();
      positioned = tester.widget<Positioned>(
        find.byKey(const Key('ayah-preview-positioned')),
      );
      expect(positioned.left, 20);

      await gesture.removePointer();
      await tester.pump();
    });

    testWidgets('tap and drag snap to the directly selected ayah', (
      tester,
    ) async {
      final seeks = <Duration>[];
      await tester.pumpWidget(_wrap(_bar(onSeek: seeks.add)));
      await tester.pump();
      final bar = find.byType(SegmentedSeekBar);
      final box = tester.renderObject<RenderBox>(bar);

      await tester.tapAt(
        box.localToGlobal(
          Offset(box.size.width - _style.thumbRadius, box.size.height / 2),
        ),
      );
      await tester.pump();
      expect(seeks.single, const Duration(seconds: 10));

      seeks.clear();
      final drag = await tester.startGesture(
        box.localToGlobal(Offset(box.size.width / 2, box.size.height / 2)),
        kind: PointerDeviceKind.mouse,
      );
      await drag.moveTo(
        box.localToGlobal(
          Offset(box.size.width - _style.thumbRadius, box.size.height / 2),
        ),
      );
      await tester.pump();
      expect(find.text('Ayah 3'), findsOneWidget);
      expect(seeks, isEmpty);
      await drag.up();
      await tester.pump();
      expect(seeks.single, const Duration(seconds: 10));
      expect(find.text('Ayah 3'), findsOneWidget);
    });

    testWidgets('untimed seeking commits the exact timeline position', (
      tester,
    ) async {
      final seeks = <Duration>[];
      await tester.pumpWidget(
        _wrap(
          _bar(
            duration: const Duration(seconds: 100),
            segments: const [],
            onSeek: seeks.add,
          ),
        ),
      );
      await tester.pump();
      final box = tester.renderObject<RenderBox>(
        find.byType(SegmentedSeekBar),
      );
      const targetValue = 0.75;
      final x =
          _style.thumbRadius +
          targetValue * (box.size.width - _style.thumbRadius * 2);
      await tester.tapAt(box.localToGlobal(Offset(x, box.size.height / 2)));
      await tester.pump();

      expect(seeks.single, const Duration(seconds: 75));
    });

    testWidgets(
      'repeat keeps real thumb position and shows final-pass details',
      (
        tester,
      ) async {
        const repeat = RepeatStatus(remaining: 1, total: 3, segmentIndex: 1);
        await tester.pumpWidget(
          _wrap(
            _bar(position: const Duration(seconds: 4), repeat: repeat),
          ),
        );
        await tester.pump();

        final barBox = tester.renderObject<RenderBox>(
          find.byType(SegmentedSeekBar),
        );
        final thumb = tester.getCenter(find.byKey(const Key('seek-thumb')));
        final barLeft = barBox.localToGlobal(Offset.zero).dx;
        final expected =
            barLeft +
            _style.thumbRadius +
            (4 / 15) * (barBox.size.width - _style.thumbRadius * 2);
        expect(thumb.dx, closeTo(expected, 1));
        expect(find.text('1 plays remaining · 3 of 3'), findsOneWidget);

        final gesture = await _hoverAt(tester, 50);
        expect(find.byKey(const Key('repeat-badge')), findsNothing);
        expect(find.byKey(const Key('ayah-preview-repeat')), findsOneWidget);
        expect(find.text('1 plays remaining · 3 of 3'), findsOneWidget);

        await gesture.removePointer();
        await tester.pump();
      },
    );

    testWidgets('repeat details are not attached to another hovered ayah', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          _bar(
            position: const Duration(seconds: 4),
            repeat: const RepeatStatus(
              remaining: 2,
              total: 3,
              segmentIndex: 1,
            ),
          ),
        ),
      );
      await tester.pump();

      final gesture = await _hoverAt(tester, 250);
      expect(find.text('Ayah 3'), findsOneWidget);
      expect(find.byKey(const Key('ayah-preview-repeat')), findsNothing);

      await gesture.removePointer();
      await tester.pump();
    });

    testWidgets('excerpt cache resets when its content identity changes', (
      tester,
    ) async {
      final oldExcerpt = Completer<String?>();
      var contentKey = 1;
      late StateSetter rebuild;

      await tester.pumpWidget(
        _wrap(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return _bar(
                contentKey: contentKey,
                excerpt: contentKey == 1
                    ? (_) => oldExcerpt.future
                    : (_) async => 'new source',
              );
            },
          ),
        ),
      );
      await tester.pump();
      final gesture = await _hoverAt(tester, 50);

      rebuild(() => contentKey = 2);
      await tester.pump();
      await tester.pump();
      oldExcerpt.complete('stale source');
      await tester.pump();

      expect(find.text('new source'), findsOneWidget);
      expect(find.text('stale source'), findsNothing);

      await gesture.removePointer();
      await tester.pump();
    });

    testWidgets('buffered ranges remain on the stable painter', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SegmentedSeekBar(
            position: const Duration(seconds: 10),
            duration: const Duration(seconds: 100),
            segments: const [],
            bufferedRanges: const [
              (Duration.zero, Duration(seconds: 50)),
              (Duration(seconds: 70), Duration(seconds: 90)),
            ],
            onSeek: (_) {},
            style: _style,
            segmentLabel: (index) => 'Ayah $index',
            repeatLabel: (current, total) => '$current of $total',
            remainingLabel: (remaining) => '$remaining plays remaining',
            semanticsLabel: 'Recitation position',
            unavailableLabel: 'Unavailable',
          ),
        ),
      );
      await tester.pump();

      final paint = tester.widget<CustomPaint>(
        find.byKey(const Key('continuous-seek-track')),
      );
      final painter = paint.painter! as SegmentedTrackPainter;
      expect(painter.bufferedRanges, hasLength(2));
    });

    testWidgets(
      'RTL mirrors position and maps the left edge to the last ayah',
      (
        tester,
      ) async {
        final seeks = <Duration>[];
        await tester.pumpWidget(
          _wrap(
            _bar(
              position: const Duration(seconds: 3),
              onSeek: seeks.add,
            ),
            direction: TextDirection.rtl,
          ),
        );
        await tester.pump();

        final bar = find.byType(SegmentedSeekBar);
        final box = tester.renderObject<RenderBox>(bar);
        final thumb = tester.getCenter(find.byKey(const Key('seek-thumb')));
        expect(thumb.dx, greaterThan(tester.getCenter(bar).dx));

        await tester.tapAt(
          box.localToGlobal(Offset(_style.thumbRadius, box.size.height / 2)),
        );
        await tester.pump();
        expect(seeks.single, const Duration(seconds: 10));
      },
    );

    testWidgets('keyboard arrows and end seek by ayah', (tester) async {
      final seeks = <Duration>[];
      await tester.pumpWidget(
        _wrap(
          _bar(position: const Duration(seconds: 7), onSeek: seeks.add),
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(SegmentedSeekBar));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(seeks.last, const Duration(seconds: 10));

      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();
      expect(seeks.last, Duration.zero);
    });
  });

  group('SegmentedTrackPainter', () {
    test('minimum highlight width does not affect true timeline mapping', () {
      final painter = SegmentedTrackPainter(
        progress: 0,
        bufferedRanges: const [],
        activeColor: Colors.black,
        inactiveColor: Colors.grey,
        bufferedColor: Colors.blue,
        repeatPulseColor: Colors.black,
        ayahGlowColor: Colors.black,
        enabled: true,
        segments: _longSurahSegments(286, const Duration(seconds: 286)),
        totalDurationMs: 286000,
        trackHeight: 4,
      );
      const size = Size(304, 20);

      final trueRect = painter.segmentRectOnTrack(140, size)!;
      final visibleRect = painter.segmentRectOnTrack(
        140,
        size,
        minimumWidth: 4,
      )!;
      expect(trueRect.width, closeTo(304 / 286, 0.01));
      expect(visibleRect.width, 4);
      expect(visibleRect.center.dx, closeTo(trueRect.center.dx, 0.01));
    });

    test('RTL mirrors true ayah geometry', () {
      final ltr = SegmentedTrackPainter(
        progress: 0,
        bufferedRanges: const [],
        activeColor: Colors.black,
        inactiveColor: Colors.grey,
        bufferedColor: Colors.blue,
        repeatPulseColor: Colors.black,
        ayahGlowColor: Colors.black,
        enabled: true,
        segments: _segments(),
        totalDurationMs: 15000,
        trackHeight: 4,
      );
      final rtl = SegmentedTrackPainter(
        progress: 0,
        bufferedRanges: const [],
        activeColor: Colors.black,
        inactiveColor: Colors.grey,
        bufferedColor: Colors.blue,
        repeatPulseColor: Colors.black,
        ayahGlowColor: Colors.black,
        enabled: true,
        segments: _segments(),
        totalDurationMs: 15000,
        trackHeight: 4,
        isRtl: true,
      );
      const size = Size(300, 20);

      expect(ltr.segmentRectOnTrack(1, size)!.left, 0);
      expect(rtl.segmentRectOnTrack(1, size)!.right, 300);
    });
  });
}
