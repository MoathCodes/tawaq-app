import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_dua_item.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/models/fortress_share_include.dart';

void main() {
  test('exact source duplicate is not presented as an additional virtue', () {
    const item = FortressDuaItem(
      contentId: 1,
      category: 'Synthetic fixture',
      text: 'Synthetic fixture body',
      targetCount: 1,
      lines: [],
      source: 'Synthetic attribution',
      virtue: ' Synthetic attribution ',
    );
    expect(item.hasVirtue, isTrue);
    expect(item.hasDistinctVirtue, isFalse);
    expect(item.virtue, ' Synthetic attribution ');
    expect(item.reference, 'Synthetic attribution');
  });

  test('available sourced virtue is included in the sharing defaults', () {
    final options = FortressShareOptions.defaults(
      hasSource: false,
      hasRepetition: false,
      hasVirtue: true,
    );
    expect(options.includes, {
      FortressShareInclude.virtue,
      FortressShareInclude.appName,
    });
  });

  test('defaults include available source and meaningful repetition', () {
    final options = FortressShareOptions.defaults(
      hasSource: true,
      hasRepetition: true,
    );
    expect(options.contains(FortressShareInclude.source), isTrue);
    expect(options.contains(FortressShareInclude.repetition), isTrue);
    expect(options.contains(FortressShareInclude.appName), isTrue);
  });

  test('defaults omit unavailable source and repetition', () {
    final options = FortressShareOptions.defaults(
      hasSource: false,
      hasRepetition: false,
    );
    expect(options.includes, {FortressShareInclude.appName});
  });
}
