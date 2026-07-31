import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/feature/quran/data/models/quran_note.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_notes_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/study/notes_browser.dart';
import 'package:tawaq/l10n/app_localizations_en.dart';

QuranNoteEntry _entry({
  required int ayahId,
  required int surahNumber,
  required int numberInSurah,
  required String text,
  String ayahPreview = '',
}) {
  final now = DateTime(2026, 7, 31, 12);
  return QuranNoteEntry(
    ayahId: ayahId,
    note: QuranNote(text: text, createdAt: now, updatedAt: now),
    ayahPreview: ayahPreview,
    surahNumber: surahNumber,
    numberInSurah: numberInSurah,
  );
}

void main() {
  group('filterQuranNotes', () {
    final entries = [
      _entry(
        ayahId: 262,
        surahNumber: 2,
        numberInSurah: 255,
        text: 'أشعر بسكينة غريبة',
        ayahPreview: 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ',
      ),
      _entry(
        ayahId: 2932,
        surahNumber: 18,
        numberInSurah: 10,
        text: 'دعاء بسيط لكنه شامل',
        ayahPreview: 'رَبَّنَا آتِنَا مِن لَّدُنكَ رَحْمَةً',
      ),
      _entry(
        ayahId: 4630,
        surahNumber: 55,
        numberInSurah: 13,
        text: 'تتكرر في السورة',
        ayahPreview: 'فَبِأَيِّ آلَاءِ رَبِّكُمَا تُكَذِّبَانِ',
      ),
    ];

    test('returns all entries for empty query', () {
      expect(
        filterQuranNotes(entries, '', (_) => 'unused'),
        entries,
      );
    });

    test('matches note text with Arabic normalization', () {
      final result = filterQuranNotes(
        entries,
        'اشعر بسكينه',
        (_) => '',
      );
      expect(result, hasLength(1));
      expect(result.single.ayahId, 262);
    });

    test('matches ayah preview ignoring diacritics', () {
      final result = filterQuranNotes(
        entries,
        'لا اله الا هو',
        (_) => '',
      );
      expect(result, hasLength(1));
      expect(result.single.ayahId, 262);
    });

    test('matches surah name via callback', () {
      final result = filterQuranNotes(
        entries,
        'الكهف',
        (surah) => switch (surah) {
          2 => 'البقرة',
          18 => 'الكهف',
          55 => 'الرحمن',
          _ => '',
        },
      );
      expect(result, hasLength(1));
      expect(result.single.ayahId, 2932);
    });

    test('returns empty when nothing matches', () {
      expect(
        filterQuranNotes(entries, 'xyz-no-match', (_) => ''),
        isEmpty,
      );
    });
  });

  group('noteTimeLabel', () {
    final l10n = AppLocalizationsEn();
    final now = DateTime(2026, 7, 31, 15);

    test('today', () {
      expect(
        noteTimeLabel(l10n, DateTime(2026, 7, 31, 8), now: now),
        l10n.noteTimeToday,
      );
    });

    test('yesterday', () {
      expect(
        noteTimeLabel(l10n, DateTime(2026, 7, 30, 20), now: now),
        l10n.noteTimeYesterday,
      );
    });

    test('days ago', () {
      expect(
        noteTimeLabel(l10n, DateTime(2026, 7, 29, 12), now: now),
        l10n.noteTimeDaysAgo(2),
      );
      expect(
        noteTimeLabel(l10n, DateTime(2026, 7, 26, 12), now: now),
        l10n.noteTimeDaysAgo(5),
      );
    });

    test('weeks ago', () {
      expect(
        noteTimeLabel(l10n, DateTime(2026, 7, 24, 12), now: now),
        l10n.noteTimeWeeksAgo(1),
      );
      expect(
        noteTimeLabel(l10n, DateTime(2026, 7, 17, 12), now: now),
        l10n.noteTimeWeeksAgo(2),
      );
    });

    test('months ago', () {
      // More than 4 weeks so the weeks bucket does not win.
      expect(
        noteTimeLabel(l10n, DateTime(2026, 6, 15, 12), now: now),
        l10n.noteTimeMonthsAgo(1),
      );
    });

    test('years ago', () {
      expect(
        noteTimeLabel(l10n, DateTime(2025, 7, 1, 12), now: now),
        l10n.noteTimeYearsAgo(1),
      );
    });
  });
}
