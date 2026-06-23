import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/core/layout/split_pane_constraints.dart';

void main() {
  group('minSplitContainerWidth', () {
    test('sums side, main, and optional spacer minimums', () {
      expect(
        minSplitContainerWidth(
          sideMin: kStudyPanelMinExtent,
          mainMin: kMainPaneMinExtent,
        ),
        800,
      );
      expect(
        minSplitContainerWidth(
          sideMin: kStudyPanelMinExtent,
          mainMin: kMushafPaneMinExtent,
          spacer: 20,
        ),
        740,
      );
    });
  });

  group('canUseHorizontalSplit', () {
    const sideMin = kStudyPanelMinExtent;
    const mainMin = kMainPaneMinExtent;

    test('returns false below combined minimum (742)', () {
      expect(
        canUseHorizontalSplit(
          containerWidth: 742,
          sideMin: sideMin,
          mainMin: mainMin,
        ),
        isFalse,
      );
    });

    test('returns true at exact combined minimum (800)', () {
      expect(
        canUseHorizontalSplit(
          containerWidth: 800,
          sideMin: sideMin,
          mainMin: mainMin,
        ),
        isTrue,
      );
    });

    test('returns true above combined minimum (1024)', () {
      expect(
        canUseHorizontalSplit(
          containerWidth: 1024,
          sideMin: sideMin,
          mainMin: mainMin,
        ),
        isTrue,
      );
    });
  });
}
