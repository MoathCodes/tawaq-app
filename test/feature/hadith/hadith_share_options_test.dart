import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/feature/hadith/presentation/models/hadith_share_include.dart';

void main() {
  const hadith = DetailedHadith(
    hadith: 'matn',
    rawi: 'narrator',
    mohdith: 'scholar',
    book: 'book',
    numberOrPage: '10',
    grade: 'authentic',
    takhrij: 'takhrij',
    hasSharhMetadata: true,
    hasUsulHadith: true,
    hadithId: 'id',
  );

  test('defaults include core attribution and branding', () {
    final options = HadithShareOptions.defaults();
    expect(options.contains(HadithShareInclude.narrator), isTrue);
    expect(options.contains(HadithShareInclude.source), isTrue);
    expect(options.contains(HadithShareInclude.grade), isTrue);
    expect(options.contains(HadithShareInclude.appName), isTrue);
    expect(options.contains(HadithShareInclude.sharh), isFalse);
  });

  test('constrained options remove unavailable details', () {
    final options =
        const HadithShareOptions({
          HadithShareInclude.takhrij,
          HadithShareInclude.sharh,
          HadithShareInclude.usul,
        }).constrained(
          hadith: hadith.copyWith(takhrij: null),
          sharhAvailable: false,
          usulAvailable: false,
        );
    expect(options.includes, isEmpty);
  });
}
