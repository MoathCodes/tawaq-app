import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/models/fortress_share_include.dart';

void main() {
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
