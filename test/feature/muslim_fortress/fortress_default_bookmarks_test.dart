import 'package:flutter_test/flutter_test.dart';
import 'package:hisn_elmoslem/hisn_elmoslem.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_default_bookmarks.dart';

void main() {
  group('fortress default bookmarks', () {
    late HisnClient client;

    setUp(() async {
      client = await HisnClient.open();
    });

    tearDown(() {
      client.close();
    });

    test('all fragments resolve to exactly one chapter each', () {
      expect(fortressDefaultBookmarkFragments, hasLength(8));

      for (final fragment in fortressDefaultBookmarkFragments) {
        final matches = client.titles.byNameFragments([fragment]);
        expect(
          matches,
          hasLength(1),
          reason: 'Expected one chapter for fragment: $fragment',
        );
      }
    });
  });
}
