import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/feature/quran/domain/services/surah_name_logic.dart';

Surah _surah({String? arabic, String? english}) => Surah(
  number: 21,
  glyph: '',
  hasBasmalah: true,
  nameArabic: arabic,
  nameEnglish: english,
);

void main() {
  test('returns no placeholder while surah metadata is unavailable', () {
    expect(localizedSurahName(null, preferArabic: false), isNull);
    expect(
      localizedSurahName(_surah(), preferArabic: false),
      isNull,
    );
  });

  test('prefers the current locale and falls back to the other real name', () {
    final surah = _surah(arabic: 'طه', english: 'Ta-Ha');

    expect(localizedSurahName(surah, preferArabic: true), 'طه');
    expect(localizedSurahName(surah, preferArabic: false), 'Ta-Ha');
    expect(
      localizedSurahName(_surah(arabic: 'طه'), preferArabic: false),
      'طه',
    );
    expect(
      localizedSurahName(_surah(english: 'Ta-Ha'), preferArabic: true),
      'Ta-Ha',
    );
  });
}
