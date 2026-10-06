import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_judgment.dart';
import 'package:tawaq/feature/hadith/presentation/models/hadith_share_include.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/share/hadith_share_text.dart';
import 'package:tawaq/l10n/app_localizations.dart';

// Source warning strings copied from the user's evidence; bodies below are
// explicitly synthetic UI fixtures, not authenticated religious content.
const fixture = DetailedHadith(
  hadith: 'Synthetic fixture body — unchanged',
  rawi: '-',
  mohdith: 'Fixture scholar',
  book: 'Fixture book',
  numberOrPage: '151',
  grade: 'فيه أبو داود النخعي كذاب',
);

void main() {
  test('explicit source warnings distinguish hadith and chain emphasis', () {
    for (final judgment in [
      'ضعيف',
      'ضعيف جدًا',
      'موضوع',
      'كذب',
      'لا أصل له',
      'باطل',
      'weak',
      'fabricated',
    ]) {
      expect(
        hadithJudgmentTone(judgment),
        HadithJudgmentTone.weak,
        reason: judgment,
      );
    }
    for (final judgment in [
      'إسناده ضعيف',
      'ضعيف الإسناد',
      'فيه أبو داود النخعي كذاب',
      '[فيه] إبراهيم بن هشام ضعيف بل اتهمه بعضهم',
      'weak isnad',
    ]) {
      expect(
        hadithJudgmentTone(judgment),
        HadithJudgmentTone.chainWarning,
        reason: judgment,
      );
    }
    for (final judgment in [
      'صحيح',
      'حسن بشواهده',
      'ليس بضعيف',
      'ليس بموضوع',
      'ليس بكذب',
      'not weak',
      'Fixture source wording unknown',
      'ليس بصحيح في هذا السياق',
    ]) {
      expect(
        hadithJudgmentTone(judgment),
        HadithJudgmentTone.neutral,
        reason: judgment,
      );
    }
  });

  test('share constraints keep negative ruling despite caller removing it', () {
    for (final hadith in [
      fixture,
      fixture.copyWith(grade: 'ضعيف'),
      fixture.copyWith(grade: 'صحيح', explainGrade: 'إسناده ضعيف'),
    ]) {
      final options = const HadithShareOptions({HadithShareInclude.narrator})
          .constrained(
            hadith: hadith,
            sharhAvailable: false,
            usulAvailable: false,
          );
      expect(options.includes, {HadithShareInclude.grade});
      expect(requiresHadithJudgment(hadith), isTrue);
    }
    final authentic = fixture.copyWith(grade: 'صحيح');
    expect(
      const HadithShareOptions({})
          .constrained(
            hadith: authentic,
            sharhAvailable: false,
            usulAvailable: false,
          )
          .includes,
      isEmpty,
    );
  });

  test('text copy keeps complete ruling and skips missing metadata', () {
    for (final locale in [const Locale('ar'), const Locale('en')]) {
      final l10n = lookupAppLocalizations(locale);
      final text = hadithShareText(fixture, l10n);
      expect(text, startsWith(fixture.hadith));
      expect(text, contains('${l10n.hadithGradeExplanation}: ${fixture.hukm}'));
      expect(text, contains(fixture.mohdith));
      expect(text, contains(fixture.book));
      expect(text, isNot(contains(l10n.hadithNarrator)));
    }
  });
  test('only blank source placeholders are considered missing', () {
    for (final value in [null, '', '  ', '-', ' — ', '––']) {
      expect(hasHadithMetadata(value), isFalse);
    }
    for (final value in ['أبو هريرة', 'عبد الله - رضي الله عنه', '151']) {
      expect(hasHadithMetadata(value), isTrue);
    }
  });
}
