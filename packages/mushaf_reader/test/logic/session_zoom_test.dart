import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf_reader/src/data/models/mushaf_style.dart';
import 'package:mushaf_reader/src/logic/mushaf_reader_controller.dart';

import '../test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MushafReaderController session zoom', () {
    late MushafReaderController controller;

    setUp(() {
      controller = MushafReaderController.withRepository(
        repository: MockQuranRepository(),
        initialPage: 1,
      );
    });

    tearDown(() {
      controller.dispose();
    });

    test('nudgeReadingBoost clamps to scale min/max', () {
      const scale = MushafScale(
        readingBoost: 1,
        minReadingBoost: 0.9,
        maxReadingBoost: 1.12,
      );
      controller.nudgeReadingBoost(1, scale: scale);
      expect(controller.sessionReadingBoost.value, 1.12);
      controller.nudgeReadingBoost(-10, scale: scale);
      expect(controller.sessionReadingBoost.value, 0.9);
    });

    test('resetSessionReadingBoost clears override', () {
      const scale = MushafScale(readingBoost: 1.08);
      controller.nudgeReadingBoost(0.02, scale: scale);
      expect(controller.sessionReadingBoost.value, isNotNull);
      controller.resetSessionReadingBoost();
      expect(controller.sessionReadingBoost.value, isNull);
      expect(controller.effectiveReadingBoost(scale: scale), 1.08);
    });
  });
}
