import 'dart:ui' show Tristate;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/segmented_seek_bar.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

Widget _wrap(Widget child, {TextDirection dir = TextDirection.ltr}) {
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
          textDirection: dir,
          child: Center(
            child: SizedBox(width: 320, child: child),
          ),
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
  tooltipBackgroundColor: Color(0xFF222222),
  tooltipBorderColor: Color(0xFF444444),
  segmentGapColor: Color(0xFFFFFFFF),
  ayahGlowColor: Color(0xFF111111),
  tooltipTextStyle: TextStyle(color: Colors.white, fontSize: 12),
  thumbRadius: 8,
  trackHeight: 4,
  thumbTweenDuration: Duration(milliseconds: 1),
  snapScaleDuration: Duration(milliseconds: 1),
  pulseDuration: Duration(milliseconds: 400),
  revealDuration: Duration(milliseconds: 200),
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

List<SeekBarSegment> _fiveSegments() => const [
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
  SeekBarSegment(
    index: 4,
    start: Duration(seconds: 15),
    end: Duration(seconds: 20),
  ),
  SeekBarSegment(
    index: 5,
    start: Duration(seconds: 20),
    end: Duration(seconds: 25),
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

double _timelineCenterX(
  SeekBarSegment seg,
  Duration total,
  double trackWidth,
) =>
    (seg.start.inMilliseconds + seg.end.inMilliseconds) /
    2 /
    total.inMilliseconds *
    trackWidth;

double _focusXAtCrossT(
  SeekBarSegment seg,
  Duration total,
  double trackWidth,
  double crossT,
) {
  final start = seg.start.inMilliseconds / total.inMilliseconds * trackWidth;
  final end = seg.end.inMilliseconds / total.inMilliseconds * trackWidth;
  return start + crossT * (end - start);
}

void main() {
  group('layoutSeekLens', () {
    test('revealStrength zero returns empty layouts', () {
      final layouts = layoutSeekLens(
        segments: _segments(),
        trackWidth: 320,
        focusListIndex: 1,
        totalDurationMs: 15000,
        revealStrength: 0,
        trackHeight: 4,
      );
      expect(layouts, isEmpty);
    });

    test('full lens makes focus segment tallest and widest', () {
      final segments = _fiveSegments();
      const total = Duration(seconds: 25);
      final layouts = layoutSeekLens(
        segments: segments,
        trackWidth: 320,
        focusListIndex: 2,
        totalDurationMs: total.inMilliseconds,
        revealStrength: 1,
        trackHeight: 4,
      );

      expect(layouts, hasLength(5));
      final focus = layouts.firstWhere((l) => l.isFocus);
      final neighbor = layouts.firstWhere((l) => l.index == 4);
      final distant = layouts.firstWhere((l) => l.index == 1);

      expect(focus.rect.height, closeTo(kLensMaxHeight, 0.01));
      expect(focus.rect.height, greaterThan(neighbor.rect.height));
      expect(focus.rect.width, greaterThan(distant.rect.width));
      expect(
        focus.rect.width,
        lessThanOrEqualTo(320 * kLensMaxFocusWidthFraction + 1),
      );
      expect(focus.opacity, closeTo(1, 0.01));
    });

    test('five segment range caps focus width', () {
      final layouts = layoutSeekLens(
        segments: _fiveSegments(),
        trackWidth: 320,
        focusListIndex: 2,
        totalDurationMs: 25000,
        revealStrength: 1,
        trackHeight: 4,
      );
      final focus = layouts.firstWhere((l) => l.isFocus);
      expect(
        focus.rect.width,
        lessThanOrEqualTo(320 * kLensMaxFocusWidthFraction + 1),
      );
    });

    test('widths plus gaps approximate track width', () {
      final segments = _fiveSegments();
      const total = Duration(seconds: 25);
      final layouts = layoutSeekLens(
        segments: segments,
        trackWidth: 320,
        focusListIndex: 2,
        totalDurationMs: total.inMilliseconds,
        revealStrength: 1,
        trackHeight: 4,
      );

      final widthSum = layouts.fold<double>(0, (s, l) => s + l.rect.width);
      final gaps = kLensGap * (layouts.length - 1);
      expect(widthSum + gaps, closeTo(320, 2));
    });

    test('long surah focus cluster wider than distant slivers', () {
      const total = Duration(minutes: 119, seconds: 41);
      final segments = _longSurahSegments(286, total);
      final focusListIndex = listIndexForSegment(segments, 200)!;

      final layouts = layoutSeekLens(
        segments: segments,
        trackWidth: 320,
        focusListIndex: focusListIndex,
        totalDurationMs: total.inMilliseconds,
        revealStrength: 1,
        trackHeight: 4,
      );

      final focus = layouts.firstWhere((l) => l.isFocus);
      final distant = layouts
          .where((l) => !l.isFocus && l.rect.width > 0)
          .reduce((a, b) => a.rect.width < b.rect.width ? a : b);
      expect(focus.rect.width, greaterThan(distant.rect.width));
    });

    test('moving focus shifts tallest segment', () {
      final segments = _fiveSegments();
      const total = Duration(seconds: 25);
      final onTwo = layoutSeekLens(
        segments: segments,
        trackWidth: 320,
        focusListIndex: 2,
        totalDurationMs: total.inMilliseconds,
        revealStrength: 1,
        trackHeight: 4,
      );
      final onThree = layoutSeekLens(
        segments: segments,
        trackWidth: 320,
        focusListIndex: 3,
        totalDurationMs: total.inMilliseconds,
        revealStrength: 1,
        trackHeight: 4,
      );

      expect(onTwo.firstWhere((l) => l.isFocus).index, 3);
      expect(onThree.firstWhere((l) => l.isFocus).index, 4);
    });
  });

  group('lensFlexForDistance', () {
    test('tiers decrease with distance', () {
      expect(
        lensFlexForDistance(0, 0.01),
        greaterThan(lensFlexForDistance(1, 0.01)),
      );
      expect(
        lensFlexForDistance(1, 0.01),
        greaterThan(lensFlexForDistance(2, 0.01)),
      );
      expect(
        lensFlexForDistance(3, 0.01),
        greaterThan(lensFlexForDistance(10, 0.01)),
      );
    });
  });

  group('segmentIndexAtLensDx', () {
    test('returns segment under dx inside lens rect', () {
      final layouts = layoutSeekLens(
        segments: _fiveSegments(),
        trackWidth: 320,
        focusListIndex: 2,
        totalDurationMs: 25000,
        revealStrength: 1,
        trackHeight: 4,
      );
      final focus = layouts.firstWhere((l) => l.isFocus);
      expect(
        segmentIndexAtLensDx(focus.rect.center.dx, layouts),
        focus.index,
      );
    });

    test('falls back to nearest segment for hairline gaps', () {
      final layouts = layoutSeekLens(
        segments: _fiveSegments(),
        trackWidth: 320,
        focusListIndex: 2,
        totalDurationMs: 25000,
        revealStrength: 1,
        trackHeight: 4,
      );
      final focus = layouts.firstWhere((l) => l.isFocus);
      expect(
        segmentIndexAtLensDx(focus.rect.right + 0.5, layouts),
        isNotNull,
      );
    });
  });

  group('interpolateLensLayouts', () {
    test('lerps rects between two focus positions', () {
      final from = layoutSeekLens(
        segments: _fiveSegments(),
        trackWidth: 320,
        focusListIndex: 1,
        totalDurationMs: 25000,
        revealStrength: 1,
        trackHeight: 4,
      );
      final to = layoutSeekLens(
        segments: _fiveSegments(),
        trackWidth: 320,
        focusListIndex: 3,
        totalDurationMs: 25000,
        revealStrength: 1,
        trackHeight: 4,
      );
      final mid = interpolateLensLayouts(from, to, 0.5);
      expect(mid, hasLength(5));
      expect(
        mid.firstWhere((l) => l.isFocus).rect.center.dx,
        isNot(equals(from.firstWhere((l) => l.isFocus).rect.center.dx)),
      );
    });
  });

  group('listIndexForSegment', () {
    test('maps ayah index to sorted list position', () {
      final segments = _fiveSegments();
      expect(listIndexForSegment(segments, 1), 0);
      expect(listIndexForSegment(segments, 3), 2);
      expect(listIndexForSegment(segments, 99), isNull);
    });
  });

  group('SegmentedSeekBar', () {
    testWidgets(
      'disabled when duration is zero; semantics reports unavailable',
      (tester) async {
        final seeks = <Duration>[];
        await tester.pumpWidget(
          _wrap(
            SegmentedSeekBar(
              position: Duration.zero,
              duration: Duration.zero,
              enabled: false,
              segments: const [],
              onSeek: seeks.add,
              style: _style,
              segmentLabel: (i) => 'Ayah $i',
              repeatLabel: (c, t) => 'Repeat $c of $t',
              unavailableLabel: 'No reciter is available',
            ),
          ),
        );
        await tester.pump();

        final node = tester.getSemantics(find.byType(SegmentedSeekBar));
        expect(node.flagsCollection.isEnabled, Tristate.isFalse);
        expect(node.value, contains('No reciter is available'));
        expect(seeks, isEmpty);
      },
    );

    testWidgets('enabled semantics announce snapped ayah + position', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          SegmentedSeekBar(
            position: const Duration(seconds: 7),
            duration: const Duration(seconds: 15),
            segments: _segments(),
            onSeek: (_) {},
            style: _style,
            segmentLabel: (i) => 'Ayah $i',
            repeatLabel: (c, t) => 'Repeat $c of $t',
            unavailableLabel: 'Unavailable',
          ),
        ),
      );
      await tester.pump();

      final node = tester.getSemantics(find.byType(SegmentedSeekBar));
      expect(node.flagsCollection.isEnabled, Tristate.isTrue);
      expect(node.value, contains('Ayah 2'));
      expect(node.value, contains('0:07'));
      expect(node.value, contains('0:15'));
    });

    testWidgets(
      'idle timed track uses continuous painter without magnified lens',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            SegmentedSeekBar(
              position: const Duration(seconds: 2),
              duration: const Duration(seconds: 15),
              segments: _segments(),
              onSeek: (_) {},
              style: _style,
              segmentLabel: (i) => 'Ayah $i',
              repeatLabel: (c, t) => 'Repeat $c of $t',
              unavailableLabel: 'Unavailable',
            ),
          ),
        );
        await tester.pump();

        final painter = tester.widget<CustomPaint>(find.byType(CustomPaint));
        final p = painter.painter! as SegmentedTrackPainter;
        expect(p.lensLayouts, isEmpty);
        expect(p.revealStrength, 0);
        expect(
          p.segmentRectOnTrack(1, const Size(300, 4))!.width,
          closeTo(100, 1),
        );
      },
    );

    test('segmentIndexForPosition returns containing ayah', () {
      final segments = _segments();
      expect(
        segmentIndexForPosition(segments, const Duration(seconds: 4)),
        1,
      );
      expect(
        segmentIndexForPosition(segments, const Duration(seconds: 9)),
        2,
      );
      expect(
        segmentIndexForPosition(segments, const Duration(seconds: 5)),
        2,
      );
      expect(
        segmentIndexForPosition(segments, const Duration(seconds: 14)),
        3,
      );
    });

    test(
      'segmentIndexForPosition prefers containing over nearer next start',
      () {
        final segments = _segments();
        expect(
          segmentIndexForPosition(segments, const Duration(milliseconds: 4900)),
          1,
        );
      },
    );

    test('segmentStartForPosition snaps to ayah start', () {
      final segments = _segments();
      expect(
        segmentStartForPosition(segments, const Duration(seconds: 9)),
        const Duration(seconds: 5),
      );
    });

    testWidgets('thumb follows parent position; reverts when seek fails', (
      tester,
    ) async {
      var position = const Duration(seconds: 2);
      await tester.pumpWidget(
        _wrap(
          StatefulBuilder(
            builder: (context, setState) {
              return SegmentedSeekBar(
                position: position,
                duration: const Duration(seconds: 15),
                segments: _segments(),
                onSeek: (target) => setState(() => position = target),
                style: _style,
                segmentLabel: (i) => 'Ayah $i',
                repeatLabel: (c, t) => 'Repeat $c of $t',
                unavailableLabel: 'Unavailable',
              );
            },
          ),
        ),
      );
      await tester.pump();

      var node = tester.getSemantics(find.byType(SegmentedSeekBar));
      expect(node.value, contains('0:02'));

      // Parent drives optimistic pending seek (like pendingSeekTarget).
      position = const Duration(seconds: 10);
      await tester.pumpWidget(
        _wrap(
          SegmentedSeekBar(
            position: position,
            duration: const Duration(seconds: 15),
            segments: _segments(),
            onSeek: (_) {},
            style: _style,
            segmentLabel: (i) => 'Ayah $i',
            repeatLabel: (c, t) => 'Repeat $c of $t',
            unavailableLabel: 'Unavailable',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(_style.thumbTweenDuration);

      node = tester.getSemantics(find.byType(SegmentedSeekBar));
      expect(node.value, contains('0:10'));

      // SeekFailed clears pending — parent reverts to confirmed position.
      position = const Duration(seconds: 2);
      await tester.pumpWidget(
        _wrap(
          SegmentedSeekBar(
            position: position,
            duration: const Duration(seconds: 15),
            segments: _segments(),
            onSeek: (_) {},
            style: _style,
            segmentLabel: (i) => 'Ayah $i',
            repeatLabel: (c, t) => 'Repeat $c of $t',
            unavailableLabel: 'Unavailable',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(_style.thumbTweenDuration);

      node = tester.getSemantics(find.byType(SegmentedSeekBar));
      expect(node.value, contains('0:02'));
      expect(node.value, isNot(contains('0:10')));
    });

    testWidgets('drag snaps to ayah start and calls onSeek', (tester) async {
      final seeks = <Duration>[];
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 320,
            child: SegmentedSeekBar(
              position: Duration.zero,
              duration: const Duration(seconds: 15),
              segments: _segments(),
              onSeek: seeks.add,
              style: _style,
              segmentLabel: (i) => 'Ayah $i',
              repeatLabel: (c, t) => 'Repeat $c of $t',
              unavailableLabel: 'Unavailable',
            ),
          ),
        ),
      );
      await tester.pump();

      final bar = find.byType(SegmentedSeekBar);
      final barBox = tester.renderObject<RenderBox>(bar);
      final width = barBox.size.width;
      final thumbRadius = _style.thumbRadius;
      const targetValue = 0.6;
      final targetDx = thumbRadius + targetValue * (width - thumbRadius * 2);
      final gesture = await tester.startGesture(
        barBox.localToGlobal(Offset(thumbRadius, barBox.size.height / 2)),
      );
      await gesture.moveTo(
        barBox.localToGlobal(Offset(targetDx, barBox.size.height / 2)),
      );
      await gesture.up();
      await tester.pump();

      expect(seeks, hasLength(1));
      expect(seeks.single.inMilliseconds, 5000);
    });

    testWidgets('buffered ranges render SegmentedTrackPainter segments', (
      tester,
    ) async {
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
            segmentLabel: (i) => 'Ayah $i',
            repeatLabel: (c, t) => 'Repeat $c of $t',
            unavailableLabel: 'Unavailable',
          ),
        ),
      );
      await tester.pump();

      final painter = tester.widget<CustomPaint>(find.byType(CustomPaint));
      final p = painter.painter! as SegmentedTrackPainter;
      expect(p.bufferedRanges, hasLength(2));
      expect(p.enabled, isTrue);
    });

    testWidgets('repeat pins thumb and shows badge before final pass', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          SegmentedSeekBar(
            position: const Duration(seconds: 4),
            duration: const Duration(seconds: 15),
            segments: _segments(),
            repeat: const RepeatStatus(
              current: 1,
              total: 3,
              segmentIndex: 1,
            ),
            onSeek: (_) {},
            style: _style,
            segmentLabel: (i) => 'Ayah $i',
            repeatLabel: (c, t) => 'Repeat $c of $t',
            unavailableLabel: 'Unavailable',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Repeat 1 of 3'), findsOneWidget);
      final node = tester.getSemantics(find.byType(SegmentedSeekBar));
      expect(node.value, contains('Repeat 1 of 3'));
    });

    testWidgets('final repeat pass follows playback position', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SegmentedSeekBar(
            position: const Duration(seconds: 4),
            duration: const Duration(seconds: 15),
            segments: _segments(),
            repeat: const RepeatStatus(
              current: 3,
              total: 3,
              segmentIndex: 1,
            ),
            onSeek: (_) {},
            style: _style,
            segmentLabel: (i) => 'Ayah $i',
            repeatLabel: (c, t) => 'Repeat $c of $t',
            unavailableLabel: 'Unavailable',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Repeat 3 of 3'), findsNothing);
      final node = tester.getSemantics(find.byType(SegmentedSeekBar));
      expect(node.value, contains('0:04'));
    });

    testWidgets('drag shows magnified lens near thumb', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SegmentedSeekBar(
            position: Duration.zero,
            duration: const Duration(seconds: 15),
            segments: _segments(),
            onSeek: (_) {},
            style: _style,
            segmentLabel: (i) => 'Ayah $i',
            repeatLabel: (c, t) => 'Repeat $c of $t',
            unavailableLabel: 'Unavailable',
          ),
        ),
      );
      await tester.pump();

      final center = tester.getCenter(find.byType(SegmentedSeekBar));
      final gesture = await tester.startGesture(center);
      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();
      await tester.pump(_style.revealDuration);

      final painter = tester.widget<CustomPaint>(find.byType(CustomPaint));
      final p = painter.painter! as SegmentedTrackPainter;
      expect(p.revealStrength, greaterThan(0));
      expect(p.lensLayouts, isNotEmpty);
      final focus = p.lensLayouts.firstWhere((l) => l.isFocus);
      expect(focus.rect.height, greaterThan(_style.trackHeight));

      await gesture.up();
      await tester.pump();
    });

    testWidgets('lens reappears after pointer exit and re-enter', (
      tester,
    ) async {
      final gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await tester.pumpWidget(
        _wrap(
          SegmentedSeekBar(
            position: const Duration(seconds: 7),
            duration: const Duration(seconds: 15),
            segments: _segments(),
            onSeek: (_) {},
            style: _style,
            segmentLabel: (i) => 'Ayah $i',
            repeatLabel: (c, t) => 'Repeat $c of $t',
            unavailableLabel: 'Unavailable',
          ),
        ),
      );
      await tester.pump();

      final center = tester.getCenter(find.byType(SegmentedSeekBar));
      await gesture.addPointer(location: center);
      await tester.pump();
      await gesture.moveTo(center + const Offset(40, 0));
      await tester.pump();
      await tester.pump(_style.revealDuration);

      var painter = tester.widget<CustomPaint>(find.byType(CustomPaint));
      var p = painter.painter! as SegmentedTrackPainter;
      expect(p.revealStrength, greaterThan(0.9));
      expect(p.lensLayouts, isNotEmpty);

      await gesture.moveTo(center + const Offset(0, -80));
      await tester.pump();
      await tester.pump(_style.revealDuration);

      painter = tester.widget<CustomPaint>(find.byType(CustomPaint));
      p = painter.painter! as SegmentedTrackPainter;
      expect(p.revealStrength, lessThan(0.05));

      await gesture.moveTo(center + const Offset(40, 0));
      await tester.pump();
      await tester.pump(_style.revealDuration);

      painter = tester.widget<CustomPaint>(find.byType(CustomPaint));
      p = painter.painter! as SegmentedTrackPainter;
      expect(p.revealStrength, greaterThan(0.9));
      expect(p.lensLayouts, isNotEmpty);
    });

    testWidgets('hover shows magnified lens on desktop', (tester) async {
      final gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await tester.pumpWidget(
        _wrap(
          SegmentedSeekBar(
            position: const Duration(seconds: 7),
            duration: const Duration(seconds: 15),
            segments: _segments(),
            onSeek: (_) {},
            style: _style,
            segmentLabel: (i) => 'Ayah $i',
            repeatLabel: (c, t) => 'Repeat $c of $t',
            unavailableLabel: 'Unavailable',
          ),
        ),
      );
      await tester.pump();

      final center = tester.getCenter(find.byType(SegmentedSeekBar));
      await gesture.addPointer(location: center);
      await tester.pump();
      await gesture.moveTo(center + const Offset(40, 0));
      await tester.pump();
      await tester.pump(_style.revealDuration);

      final painter = tester.widget<CustomPaint>(find.byType(CustomPaint));
      final p = painter.painter! as SegmentedTrackPainter;
      expect(p.revealStrength, greaterThan(0));
      expect(p.lensLayouts, isNotEmpty);
      expect(
        p.lensLayouts.any((l) => l.isFocus),
        isTrue,
      );
    });

    testWidgets('hover tooltip anchors at cursor not thumb', (tester) async {
      final gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await tester.pumpWidget(
        _wrap(
          SegmentedSeekBar(
            position: const Duration(seconds: 7),
            duration: const Duration(seconds: 15),
            segments: _segments(),
            onSeek: (_) {},
            style: _style,
            segmentLabel: (i) => 'Ayah $i',
            repeatLabel: (c, t) => 'Repeat $c of $t',
            unavailableLabel: 'Unavailable',
          ),
        ),
      );
      await tester.pump();

      final bar = find.byType(SegmentedSeekBar);
      final center = tester.getCenter(bar);
      final barBox = tester.renderObject<RenderBox>(bar);
      final barWidth = barBox.size.width;
      final thumbRadius = _style.thumbRadius;
      final thumbCenter = thumbRadius + (7 / 15) * (barWidth - thumbRadius * 2);
      final ayah3Center = (12.5 / 15) * barWidth;
      final hoverOffset = Offset(ayah3Center - barWidth / 2, 0);

      expect((thumbCenter - ayah3Center).abs(), greaterThan(40));

      await gesture.addPointer(location: center);
      await tester.pump();
      await gesture.moveTo(center + hoverOffset);
      await tester.pump();

      expect(find.text('Ayah 3'), findsOneWidget);

      final topLeft = barBox.localToGlobal(Offset.zero);
      final tooltipBox = tester.renderObject<RenderBox>(
        find.byKey(const Key('scrub-tooltip-positioned')),
      );
      final tooltipCenter = tooltipBox
          .localToGlobal(
            Offset(tooltipBox.size.width / 2, 0),
          )
          .dx;

      expect(tooltipCenter, closeTo(topLeft.dx + ayah3Center, 24));
      expect(
        (tooltipCenter - (topLeft.dx + thumbCenter)).abs(),
        greaterThan(30),
      );
    });

    testWidgets('drag tooltip anchors at thumb', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SegmentedSeekBar(
            position: Duration.zero,
            duration: const Duration(seconds: 15),
            segments: _segments(),
            onSeek: (_) {},
            style: _style,
            segmentLabel: (i) => 'Ayah $i',
            repeatLabel: (c, t) => 'Repeat $c of $t',
            unavailableLabel: 'Unavailable',
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(FTooltip), findsNothing);

      final center = tester.getCenter(find.byType(SegmentedSeekBar));
      final gesture = await tester.startGesture(center);
      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();

      expect(find.byKey(const Key('scrub-tooltip')), findsOneWidget);
      expect(find.text('Ayah 2'), findsOneWidget);

      final bar = find.byType(SegmentedSeekBar);
      final barBox = tester.renderObject<RenderBox>(bar);
      final barWidth = barBox.size.width;
      final thumbRadius = _style.thumbRadius;
      final topLeft = barBox.localToGlobal(Offset.zero);

      final tooltipBox = tester.renderObject<RenderBox>(
        find.byKey(const Key('scrub-tooltip-positioned')),
      );
      final tooltipCenter = tooltipBox
          .localToGlobal(
            Offset(tooltipBox.size.width / 2, 0),
          )
          .dx;

      final gestureCenter = tester.getCenter(bar) + const Offset(50, 0);
      final dragThumbCenter =
          thumbRadius +
          (gestureCenter.dx - topLeft.dx - thumbRadius).clamp(
            0.0,
            barWidth - thumbRadius * 2,
          );

      expect(tooltipCenter, closeTo(topLeft.dx + dragThumbCenter, 30));

      await gesture.up();
      await tester.pump();

      expect(find.byKey(const Key('scrub-tooltip')), findsNothing);
    });

    testWidgets('scrub tooltip falls back to formatted time without segments', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          SegmentedSeekBar(
            position: Duration.zero,
            duration: const Duration(seconds: 90),
            segments: const [],
            onSeek: (_) {},
            style: _style,
            segmentLabel: (i) => 'Ayah $i',
            repeatLabel: (c, t) => 'Repeat $c of $t',
            unavailableLabel: 'Unavailable',
          ),
        ),
      );
      await tester.pump();

      final center = tester.getCenter(find.byType(SegmentedSeekBar));
      final gesture = await tester.startGesture(center);
      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();

      expect(find.byKey(const Key('scrub-tooltip')), findsOneWidget);
      expect(
        find.textContaining(RegExp(r'^\d+:\d{2}(:\d{2})?$')),
        findsOneWidget,
      );

      await gesture.up();
      await tester.pump();

      expect(find.byKey(const Key('scrub-tooltip')), findsNothing);
    });

    testWidgets('RTL mirrors thumb center for early progress', (tester) async {
      const position = Duration(seconds: 3);
      const duration = Duration(seconds: 15);

      Future<Offset> thumbGlobal(TextDirection dir) async {
        await tester.pumpWidget(
          _wrap(
            SegmentedSeekBar(
              position: position,
              duration: duration,
              segments: _segments(),
              onSeek: (_) {},
              style: _style,
              segmentLabel: (i) => 'Ayah $i',
              repeatLabel: (c, t) => 'Repeat $c of $t',
              unavailableLabel: 'Unavailable',
            ),
            dir: dir,
          ),
        );
        await tester.pump();
        await tester.pump(_style.thumbTweenDuration);
        return tester.getCenter(find.byKey(const Key('seek-thumb')));
      }

      final ltr = await thumbGlobal(TextDirection.ltr);
      final rtl = await thumbGlobal(TextDirection.rtl);
      expect(rtl.dx, greaterThan(ltr.dx + 40));

      final painter = tester.widget<CustomPaint>(find.byType(CustomPaint));
      final p = painter.painter! as SegmentedTrackPainter;
      expect(p.isRtl, isTrue);
    });

    testWidgets('RTL seek snap still targets ayah start', (tester) async {
      final seeks = <Duration>[];
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 320,
            child: SegmentedSeekBar(
              position: Duration.zero,
              duration: const Duration(seconds: 15),
              segments: _segments(),
              onSeek: seeks.add,
              style: _style,
              segmentLabel: (i) => 'Ayah $i',
              repeatLabel: (c, t) => 'Repeat $c of $t',
              unavailableLabel: 'Unavailable',
            ),
          ),
          dir: TextDirection.rtl,
        ),
      );
      await tester.pump();

      final bar = find.byType(SegmentedSeekBar);
      final barBox = tester.renderObject<RenderBox>(bar);
      final width = barBox.size.width;
      final thumbRadius = _style.thumbRadius;
      // Timeline 0.6 maps near ayah 2 start (5s). In RTL that is left of center.
      const targetValue = 0.6;
      final targetDx =
          thumbRadius + (1.0 - targetValue) * (width - thumbRadius * 2);
      final gesture = await tester.startGesture(
        barBox.localToGlobal(
          Offset(width - thumbRadius, barBox.size.height / 2),
        ),
      );
      await gesture.moveTo(
        barBox.localToGlobal(Offset(targetDx, barBox.size.height / 2)),
      );
      await gesture.up();
      await tester.pump();

      expect(seeks, hasLength(1));
      expect(seeks.single.inMilliseconds, 5000);
    });

    testWidgets('thumb fades out at full lens reveal', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SegmentedSeekBar(
            position: const Duration(seconds: 7),
            duration: const Duration(seconds: 15),
            segments: _segments(),
            onSeek: (_) {},
            style: _style,
            segmentLabel: (i) => 'Ayah $i',
            repeatLabel: (c, t) => 'Repeat $c of $t',
            unavailableLabel: 'Unavailable',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(_style.thumbTweenDuration);

      expect(find.byKey(const Key('seek-thumb')), findsOneWidget);

      final center = tester.getCenter(find.byType(SegmentedSeekBar));
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: center);
      await tester.pump();
      await gesture.moveTo(center);
      await tester.pump();
      await tester.pump(_style.revealDuration);
      await tester.pump(_style.revealDuration);

      final painter = tester.widget<CustomPaint>(find.byType(CustomPaint));
      final p = painter.painter! as SegmentedTrackPainter;
      expect(p.revealStrength, greaterThan(0.9));
      expect(p.lensLayouts, isNotEmpty);
      expect(find.byKey(const Key('seek-thumb')), findsNothing);

      await gesture.removePointer();
      await tester.pump();
    });

    testWidgets('hover near boundary keeps focus until past dead zone', (
      tester,
    ) async {
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await tester.pumpWidget(
        _wrap(
          SegmentedSeekBar(
            position: const Duration(seconds: 2),
            duration: const Duration(seconds: 15),
            segments: _segments(),
            onSeek: (_) {},
            style: _style,
            segmentLabel: (i) => 'Ayah $i',
            repeatLabel: (c, t) => 'Repeat $c of $t',
            unavailableLabel: 'Unavailable',
          ),
        ),
      );
      await tester.pump();

      final bar = find.byType(SegmentedSeekBar);
      final barBox = tester.renderObject<RenderBox>(bar);
      final width = barBox.size.width;
      final ayah1Center = width * (2.5 / 15);
      final y = barBox.size.height / 2;

      await gesture.addPointer(
        location: barBox.localToGlobal(Offset(ayah1Center, y)),
      );
      await tester.pump();
      await gesture.moveTo(barBox.localToGlobal(Offset(ayah1Center, y)));
      await tester.pump();
      await tester.pump(_style.revealDuration);
      await tester.pump(_style.revealDuration);

      var painter = tester.widget<CustomPaint>(find.byType(CustomPaint));
      var p = painter.painter! as SegmentedTrackPainter;
      expect(p.lensLayouts, isNotEmpty);
      final focus1 = p.lensLayouts.firstWhere((l) => l.isFocus);
      expect(focus1.index, 1);
      final focusRight = focus1.rect.right;

      // Just past the focus pill edge — still inside 6px dead zone.
      await gesture.moveTo(
        barBox.localToGlobal(Offset(focusRight + 2, y)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));

      painter = tester.widget<CustomPaint>(find.byType(CustomPaint));
      p = painter.painter! as SegmentedTrackPainter;
      expect(p.lensLayouts.firstWhere((l) => l.isFocus).index, 1);

      // Past dead zone AND enough travel budget for one step.
      await gesture.moveTo(
        barBox.localToGlobal(Offset(ayah1Center + 40, y)),
      );
      await tester.pump();
      await tester.pump(_style.revealDuration);

      painter = tester.widget<CustomPaint>(find.byType(CustomPaint));
      p = painter.painter! as SegmentedTrackPainter;
      expect(p.lensLayouts.firstWhere((l) => l.isFocus).index, 2);

      await gesture.removePointer();
      await tester.pump();
    });

    testWidgets('drag start keeps playback focus before movement', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          SegmentedSeekBar(
            position: const Duration(seconds: 2),
            duration: const Duration(seconds: 15),
            segments: _segments(),
            onSeek: (_) {},
            style: _style,
            segmentLabel: (i) => 'Ayah $i',
            repeatLabel: (c, t) => 'Repeat $c of $t',
            unavailableLabel: 'Unavailable',
          ),
        ),
      );
      await tester.pump();

      final bar = find.byType(SegmentedSeekBar);
      final barBox = tester.renderObject<RenderBox>(bar);
      final width = barBox.size.width;
      // Press on ayah 3 region; drag needs a tiny move past touch slop.
      final ayah3Dx = width * (12.5 / 15);
      final gesture = await tester.startGesture(
        barBox.localToGlobal(Offset(ayah3Dx, barBox.size.height / 2)),
      );
      // Exceed pan touch slop so drag starts; stay within focus-hold dead zone.
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump();
      await tester.pump(_style.revealDuration);
      await tester.pump(_style.revealDuration);

      final painter = tester.widget<CustomPaint>(find.byType(CustomPaint));
      final p = painter.painter! as SegmentedTrackPainter;
      expect(p.revealStrength, greaterThan(0.9));
      expect(p.lensLayouts, isNotEmpty);
      expect(p.lensLayouts.firstWhere((l) => l.isFocus).index, 1);

      await gesture.up();
      await tester.pump();
    });

    testWidgets('slow hover advances one ayah per travel step', (tester) async {
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      const total = Duration(seconds: 25);
      final segments = _fiveSegments();
      await tester.pumpWidget(
        _wrap(
          SegmentedSeekBar(
            position: const Duration(seconds: 2),
            duration: total,
            segments: segments,
            onSeek: (_) {},
            style: _style,
            segmentLabel: (i) => 'Ayah $i',
            repeatLabel: (c, t) => 'Repeat $c of $t',
            unavailableLabel: 'Unavailable',
          ),
        ),
      );
      await tester.pump();

      final bar = find.byType(SegmentedSeekBar);
      final barBox = tester.renderObject<RenderBox>(bar);
      final width = barBox.size.width;
      final y = barBox.size.height / 2;

      // Start on ayah 1.
      var dx = width * (2.5 / 25);
      await gesture.addPointer(
        location: barBox.localToGlobal(Offset(dx, y)),
      );
      await tester.pump();
      await gesture.moveTo(barBox.localToGlobal(Offset(dx, y)));
      await tester.pump();
      await tester.pump(_style.revealDuration);
      await tester.pump(_style.revealDuration);

      var painter = tester.widget<CustomPaint>(find.byType(CustomPaint));
      var p = painter.painter! as SegmentedTrackPainter;
      expect(p.lensLayouts.firstWhere((l) => l.isFocus).index, 1);

      // Each ~34px crawl unlocks at most one ayah (never +3 in one small move).
      var prevFocus = 1;
      for (var i = 0; i < 6; i++) {
        dx += 34;
        if (dx >= width - 8) break;
        await gesture.moveTo(barBox.localToGlobal(Offset(dx, y)));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 40));
        painter = tester.widget<CustomPaint>(find.byType(CustomPaint));
        p = painter.painter! as SegmentedTrackPainter;
        final focus = p.lensLayouts.firstWhere((l) => l.isFocus).index;
        expect(
          focus - prevFocus,
          lessThanOrEqualTo(1),
          reason: 'step $i: focus jumped from $prevFocus to $focus',
        );
        prevFocus = focus;
      }

      await gesture.removePointer();
      await tester.pump();
    });
  });

  group('pastFocusHysteresis', () {
    test('requires travel past current edge into candidate', () {
      const current = Rect.fromLTRB(0, 0, 100, 10);
      const candidate = Rect.fromLTRB(100, 0, 200, 10);

      expect(
        pastFocusHysteresis(
          dx: 102,
          currentRect: current,
          candidateRect: candidate,
        ),
        isFalse,
      );
      expect(
        pastFocusHysteresis(
          dx: 106,
          currentRect: current,
          candidateRect: candidate,
        ),
        isTrue,
      );
      expect(
        pastFocusHysteresis(
          dx: 98,
          currentRect: candidate,
          candidateRect: current,
        ),
        isFalse,
      );
      expect(
        pastFocusHysteresis(
          dx: 94,
          currentRect: candidate,
          candidateRect: current,
        ),
        isTrue,
      );
    });
  });

  group('stepLimitedFocusListIndex', () {
    test('insufficient travel blocks even the first step', () {
      expect(
        stepLimitedFocusListIndex(
          currentListIndex: 49,
          candidateListIndex: 55,
          travelPx: 5,
          pxPerStep: 32,
        ),
        49,
      );
      expect(
        stepLimitedFocusListIndex(
          currentListIndex: 49,
          candidateListIndex: 50,
          travelPx: 31,
          pxPerStep: 32,
        ),
        49,
      );
    });

    test('one step of travel unlocks adjacent only', () {
      expect(
        stepLimitedFocusListIndex(
          currentListIndex: 49,
          candidateListIndex: 55,
          travelPx: 32,
          pxPerStep: 32,
        ),
        50,
      );
      expect(
        stepLimitedFocusListIndex(
          currentListIndex: 49,
          candidateListIndex: 40,
          travelPx: 40,
          pxPerStep: 32,
        ),
        48,
      );
    });

    test('large travel unlocks multi-step', () {
      expect(
        stepLimitedFocusListIndex(
          currentListIndex: 49,
          candidateListIndex: 55,
          travelPx: 96,
          pxPerStep: 32,
        ),
        52,
      );
      expect(
        stepLimitedFocusListIndex(
          currentListIndex: 10,
          candidateListIndex: 20,
          travelPx: 200,
          pxPerStep: 32,
        ),
        16,
      );
    });

    test('zero delta stays put', () {
      expect(
        stepLimitedFocusListIndex(
          currentListIndex: 5,
          candidateListIndex: 5,
          travelPx: 0,
          pxPerStep: 32,
        ),
        5,
      );
    });
  });

  group('layoutSeekLens RTL', () {
    test('mirrors chronological first segment to the right', () {
      final ltr = layoutSeekLens(
        segments: _fiveSegments(),
        trackWidth: 320,
        focusListIndex: 2,
        totalDurationMs: 25000,
        revealStrength: 1,
        trackHeight: 4,
      );
      final rtl = layoutSeekLens(
        segments: _fiveSegments(),
        trackWidth: 320,
        focusListIndex: 2,
        totalDurationMs: 25000,
        revealStrength: 1,
        trackHeight: 4,
        isRtl: true,
      );

      final ltrFirst = ltr.firstWhere((l) => l.index == 1);
      final rtlFirst = rtl.firstWhere((l) => l.index == 1);
      expect(ltrFirst.rect.left, lessThan(160));
      expect(rtlFirst.rect.right, greaterThan(160));
      expect(
        rtlFirst.rect.left,
        closeTo(320 - ltrFirst.rect.right, 0.01),
      );
      expect(
        rtl.firstWhere((l) => l.isFocus).rect.width,
        closeTo(ltr.firstWhere((l) => l.isFocus).rect.width, 0.01),
      );
    });
  });
}

