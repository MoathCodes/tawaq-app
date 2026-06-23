import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/core/layout/split_pane_constraints.dart';

void main() {
  group('resolveSplitExtents', () {
    test('keeps persisted widths when they fit', () {
      final result = resolveSplitExtents(
        totalWidth: 1200,
        sideWidth: 420,
        sideMin: kStudyPanelMinExtent,
        mainMin: kMainPaneMinExtent,
      );

      expect(result.sideExtent, 420);
      expect(result.mainExtent, 780);
      expect(result.sideExtent + result.mainExtent, 1200);
    });

    test('reproduces Hadith overflow with narrow container', () {
      // Naive math: (800 - 420).clamp(480, 1200) = 480 → sum 900 > 800.
      final result = resolveSplitExtents(
        totalWidth: 800,
        sideWidth: 420,
        sideMin: kStudyPanelMinExtent,
        mainMin: kMainPaneMinExtent,
      );

      expect(result.sideExtent + result.mainExtent, closeTo(800, 0.001));
      expect(result.mainExtent, kMainPaneMinExtent);
      expect(result.sideExtent, 320);
    });

    test('narrows an oversized persisted side panel', () {
      final result = resolveSplitExtents(
        totalWidth: 900,
        sideWidth: 600,
        sideMin: kStudyPanelMinExtent,
        mainMin: kMainPaneMinExtent,
      );

      expect(result.sideExtent + result.mainExtent, closeTo(900, 0.001));
      expect(result.mainExtent, kMainPaneMinExtent);
      expect(result.sideExtent, 420);
    });

    test('respects mainMax by widening the side pane', () {
      final result = resolveSplitExtents(
        totalWidth: 1600,
        sideWidth: 420,
        sideMin: kStudyPanelMinExtent,
        mainMin: kMainPaneMinExtent,
        mainMax: 900,
      );

      expect(result.mainExtent, 900);
      expect(result.sideExtent, 700);
      expect(result.sideExtent + result.mainExtent, 1600);
    });

    test('respects sideMax cap', () {
      final result = resolveSplitExtents(
        totalWidth: 1200,
        sideWidth: 700,
        sideMin: kStudyPanelMinExtent,
        mainMin: kMainPaneMinExtent,
        sideMax: 500,
      );

      expect(result.sideExtent, 500);
      expect(result.mainExtent, 700);
    });

    test('proportionally splits when container is below combined minimums', () {
      final result = resolveSplitExtents(
        totalWidth: 700,
        sideWidth: 420,
        sideMin: kStudyPanelMinExtent,
        mainMin: kMainPaneMinExtent,
      );

      expect(result.sideExtent + result.mainExtent, closeTo(700, 0.001));
      expect(result.sideExtent, closeTo(700 * 320 / 800, 0.001));
      expect(result.mainExtent, closeTo(700 * 480 / 800, 0.001));
    });

    test('returns zero extents for non-positive container width', () {
      final result = resolveSplitExtents(
        totalWidth: 0,
        sideWidth: 420,
        sideMin: kStudyPanelMinExtent,
        mainMin: kMainPaneMinExtent,
      );

      expect(result.sideExtent, 0);
      expect(result.mainExtent, 0);
    });
  });

  group('normalizeSplitExtentsForResizable', () {
    test('scales minimums when they consume the full container width', () {
      const totalWidth = 551.0;
      const sideMin = 280.0;
      const mainMin = 271.0;

      final result = normalizeSplitExtentsForResizable(
        totalWidth: totalWidth,
        sideExtent: sideMin,
        mainExtent: mainMin,
        sideMin: sideMin,
        mainMin: mainMin,
      );

      expect(result.sideMin + result.mainMin, closeTo(totalWidth - 1, 0.001));
      expect(
        result.sideExtent + result.mainExtent,
        closeTo(totalWidth, 0.001),
      );
      expect(
        result.sideExtent + result.mainExtent,
        greaterThan(result.sideMin + result.mainMin),
      );
    });

    test('preserves resolved extents when minimums already fit', () {
      final result = normalizeSplitExtentsForResizable(
        totalWidth: 1200,
        sideExtent: 420,
        mainExtent: 780,
        sideMin: kStudyPanelMinExtent,
        mainMin: kMainPaneMinExtent,
      );

      expect(result.sideExtent, 420);
      expect(result.mainExtent, 780);
      expect(result.sideMin, kStudyPanelMinExtent);
      expect(result.mainMin, kMainPaneMinExtent);
    });
  });

  group('migrateSidePanelWidthToRatio', () {
    test('converts a legacy pixel width to a ratio', () {
      final map = <String, dynamic>{'sidePanelWidth': 420};
      migrateSidePanelWidthToRatio(map);

      expect(map.containsKey('sidePanelWidth'), isFalse);
      expect(
        map['sidePanelRatio'],
        closeTo(420 / kSidePanelRatioMigrationWidth, 0.0001),
      );
    });

    test('clamps extreme legacy widths into the sane range', () {
      final tiny = <String, dynamic>{'sidePanelWidth': 50};
      migrateSidePanelWidthToRatio(tiny);
      expect(tiny['sidePanelRatio'], 0.15);

      final huge = <String, dynamic>{'sidePanelWidth': 9000};
      migrateSidePanelWidthToRatio(huge);
      expect(huge['sidePanelRatio'], 0.5);
    });

    test('leaves an already-migrated map untouched', () {
      final map = <String, dynamic>{'sidePanelRatio': 0.4, 'sidePanelWidth': 99};
      migrateSidePanelWidthToRatio(map);

      expect(map['sidePanelRatio'], 0.4);
      expect(map['sidePanelWidth'], 99);
    });

    test('is a no-op when no side-panel key is present', () {
      final map = <String, dynamic>{'other': 1};
      migrateSidePanelWidthToRatio(map);

      expect(map.containsKey('sidePanelRatio'), isFalse);
      expect(map, {'other': 1});
    });
  });
}
