import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/feature/quran/domain/services/ayah_reference_logic.dart';

Surah _surah({String? arabic, String? english}) => Surah(
  number: 21,
  glyph: '',
  hasBasmalah: true,
  nameArabic: arabic,
  nameEnglish: english,
);

void main() {
  test('returns no placeholder while surah metadata is unavailable', () {
    expect(
      AyahReferenceLogic.surahName(
        null,
        21,
        preferArabic: false,
        fallbackName: '',
      ),
      isEmpty,
    );
    expect(
      AyahReferenceLogic.surahName(
        _surah(),
        21,
        preferArabic: false,
        fallbackName: '',
      ),
      isEmpty,
    );
  });

  test('prefers the current locale and falls back to the other real name', () {
    final surah = _surah(arabic: 'طه', english: 'Ta-Ha');

    expect(
      AyahReferenceLogic.surahName(
        surah,
        21,
        preferArabic: true,
        fallbackName: '',
      ),
      'طه',
    );
    expect(
      AyahReferenceLogic.surahName(
        surah,
        21,
        preferArabic: false,
        fallbackName: '',
      ),
      'Ta-Ha',
    );
    expect(
      AyahReferenceLogic.surahName(
        _surah(arabic: 'طه'),
        21,
        preferArabic: false,
        fallbackName: '',
      ),
      'طه',
    );
    expect(
      AyahReferenceLogic.surahName(
        _surah(english: 'Ta-Ha'),
        21,
        preferArabic: true,
        fallbackName: '',
      ),
      'Ta-Ha',
    );
  });
}
