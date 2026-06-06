import 'package:flutter_test/flutter_test.dart';
import 'package:hisn_elmoslem/hisn_elmoslem.dart';
import 'package:tawaq/feature/muslim_fortress/domain/services/fortress_time_recommendations.dart';

void main() {
  group('recommendTitleFragments', () {
    test('late night suggests sleep and evening', () {
      expect(
        recommendTitleFragments(now: DateTime(2026, 6, 3, 22)),
        [HisnFeaturedTitles.sleep, HisnFeaturedTitles.evening],
      );
    });

    test('morning hours suggest waking and morning', () {
      expect(
        recommendTitleFragments(now: DateTime(2026, 6, 3, 8)),
        [HisnFeaturedTitles.waking, HisnFeaturedTitles.morning],
      );
    });

    test('afternoon suggests evening adhkar', () {
      expect(
        recommendTitleFragments(now: DateTime(2026, 6, 3, 18)),
        [HisnFeaturedTitles.evening, HisnFeaturedTitles.sleep],
      );
    });
  });
}
