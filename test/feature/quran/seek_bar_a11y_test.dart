import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_state.dart';
import 'package:tawaq/feature/quran/domain/services/recitation_timeline.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/recitation_seek_bar.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

/// Minimal theme + l10n wrapper so the seek bar renders without a full
/// ProviderScope. The seek bar is a plain StatefulWidget driven entirely by
/// its constructor props.
Widget _wrap(Widget child, {TextDirection dir = TextDirection.ltr}) {
  final theme = buildAppTheme(
    palette: AppPalette.zinc,
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

SurahTiming _timing() => const SurahTiming(
      surah: 1,
      readId: 1,
      ayat: [
        AyahTiming(ayah: 1, startMs: 0, endMs: 5000),
        AyahTiming(ayah: 2, startMs: 5000, endMs: 10000),
        AyahTiming(ayah: 3, startMs: 10000, endMs: 15000),
      ],
    );

void main() {
  group('RecitationSeekBar a11y + buffered segment', () {
    testWidgets('disabled when duration is zero; semantics reports unavailable',
        (tester) async {
      final seeks = <Duration>[];
      await tester.pumpWidget(
        _wrap(RecitationSeekBar(
          playback: const RecitationState(),
          timeline: null,
          onSeek: seeks.add,
        )),
      );
      await tester.pumpAndSettle();

      // The seek bar reports the "unavailable" string and is disabled.
      final node = tester.getSemantics(find.byType(RecitationSeekBar));
      expect(
        node.flagsCollection.isEnabled,
        Tristate.isFalse,
      );
      expect(node.value, contains('No reciter is available'));
      expect(seeks, isEmpty);
    });

    testWidgets(
      'enabled and semantics announce snapped ayah + position',
      (tester) async {
        final timeline = RecitationTimeline(timing: _timing());
        await tester.pumpWidget(
          _wrap(RecitationSeekBar(
            playback: const RecitationState(
              duration: Duration(seconds: 15),
              position: Duration(seconds: 7), // mid-ayah-2 window
            ),
            timeline: timeline,
            onSeek: (_) {},
          )),
        );
        await tester.pumpAndSettle();

        final node = tester.getSemantics(find.byType(RecitationSeekBar));
        expect(
          node.flagsCollection.isEnabled,
          Tristate.isTrue,
        );
        // Snapped position for ~7s (inside ayah 2, 5000–10000ms) snaps to the
        // nearest ayah *start*. 7s is closer to 5s than 10s → ayah 2 at 0:05.
        expect(node.value, contains('Ayah 2'));
        expect(node.value, contains('0:05'));
        expect(node.value, contains('0:15'));
      },
    );

    testWidgets(
      'drag snaps to nearest ayah and calls onSeek with snapped position',
      (tester) async {
        final seeks = <Duration>[];
        final timeline = RecitationTimeline(timing: _timing());
        await tester.pumpWidget(
          _wrap(RecitationSeekBar(
            playback: const RecitationState(
              duration: Duration(seconds: 15),
            ),
            timeline: timeline,
            onSeek: seeks.add,
          )),
        );
        await tester.pumpAndSettle();

        // Drag the thumb ~60% across (≈9s). 9s is closer to ayah 3's start
        // (10s) than ayah 2's (5s), so it snaps to 0:10.
        await tester.drag(
          find.byType(RecitationSeekBar),
          const Offset(320 * 0.6, 0),
        );
        await tester.pumpAndSettle();

        expect(seeks, hasLength(1));
        expect(seeks.single.inMilliseconds, 10000);
      },
    );

    testWidgets(
      'buffered ranges render a CustomPainter segment over the inactive track',
      (tester) async {
        await tester.pumpWidget(
          _wrap(RecitationSeekBar(
            playback: const RecitationState(
              duration: Duration(seconds: 100),
              position: Duration(seconds: 10),
            ),
            timeline: null,
            bufferedRanges: const [
              CacheRange(Duration.zero, Duration(seconds: 50)),
              CacheRange(Duration(seconds: 70), Duration(seconds: 90)),
            ],
            onSeek: (_) {},
          )),
        );
        await tester.pumpAndSettle();

        // The track painter is present and carries the two buffered fractions.
        final painter = tester.widget<CustomPaint>(find.byType(CustomPaint));
        final p = painter.painter;
        expect(p, isNotNull);
        expect(p, isA<SeekBarTrackPainter>());
        final track = p! as SeekBarTrackPainter;
        expect(track.bufferedRanges, hasLength(2));
        // Each fraction is ordered start < end.
        for (final (start, end) in track.bufferedRanges) {
          expect(end, greaterThan(start));
        }
        expect(track.enabled, isTrue);
      },
    );

    testWidgets(
      'ayah tooltip (FTooltip) is built while dragging',
      (tester) async {
        final timeline = RecitationTimeline(timing: _timing());
        await tester.pumpWidget(
          _wrap(RecitationSeekBar(
            playback: const RecitationState(
              duration: Duration(seconds: 15),
            ),
            timeline: timeline,
            onSeek: (_) {},
          )),
        );
        await tester.pumpAndSettle();

        // FTooltip wraps the seek bar's gesture area.
        expect(find.byType(FTooltip), findsOneWidget);

        // Start a drag — onHorizontalDragStart requests the tooltip show.
        final bar = tester.getCenter(find.byType(RecitationSeekBar));
        final gesture = await tester.startGesture(bar);
        await tester.pump(const Duration(milliseconds: 50));
        await gesture.moveBy(const Offset(120, 0));
        await tester.pump(const Duration(milliseconds: 200));

        // The seek bar still renders (no exceptions) during the drag.
        expect(find.byType(RecitationSeekBar), findsOneWidget);

        await gesture.up();
        await tester.pumpAndSettle();
      },
    );
  });
}
