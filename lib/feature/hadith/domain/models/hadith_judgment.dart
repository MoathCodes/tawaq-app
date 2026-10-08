import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:tawaq/core/text/arabic_search_normalize.dart';

/// Presentation emphasis derived only from explicit words in the source ruling.
/// This is not an independent authentication of a hadith. Qualified and unknown
/// rulings retain their exact wording; no positive authenticity is inferred.
enum HadithJudgmentTone { neutral, weak, chainWarning }

HadithJudgmentTone hadithJudgmentTone(String judgment) {
  final text = normalizeArabicForSearch(judgment).toLowerCase();
  // Remove explicit negations before looking for negative source descriptors.
  final explicit = text
      .replaceAll(
        RegExp(
          r'(?:ليس|ليست|غير)\s+(?:ب)?(?:ضعيف|موضوع|منكر|باطل|متروك|كذاب|كذب)(?=\s|$|[،.])',
        ),
        '',
      )
      .replaceAll(RegExp(r'\b(?:not|non)[ -](?:weak|fabricated|forged)\b'), '');
  bool mentions(String pattern) =>
      RegExp('(?:^|[\\s،؛:().\\[\\]])(?:$pattern)(?=\\s|[،؛:().\\[\\]]|\$)')
          .hasMatch(explicit);
  if (mentions(
    'موضوع|كذب|مكذوب|باطل|منكر|متروك|لا يصح|لا يثبت|لا اصل له|ضعيف جدا|fabricated|forged|very weak',
  )) {
    return HadithJudgmentTone.weak;
  }
  if (mentions(
    'كذاب|يكذب|متهم|يضع (?:الحديث|الاحاديث)|(?:اسناد|سند|فيه|رجاله).*ضعيف|ضعيف.*(?:اسناد|سند)|weak (?:chain|isnad)',
  )) {
    return HadithJudgmentTone.chainWarning;
  }
  if (mentions('ضعيف|ضعيفا|واه|weak')) {
    return HadithJudgmentTone.weak;
  }
  return HadithJudgmentTone.neutral;
}

/// Upstream missing-value placeholders are absent metadata, not attribution.
bool hasHadithMetadata(String? value) =>
    value != null &&
    value.trim().isNotEmpty &&
    !RegExp(r'^[-–—ـ]+$').hasMatch(value.trim());

/// Combine both supplied rulings without inferring authenticity from a filter.
HadithJudgmentTone hadithSourceJudgmentTone(HadithBase hadith) {
  final tones = [
    hadithJudgmentTone(hadith.grade),
    if (hadith is DetailedHadith) hadithJudgmentTone(hadith.explainGrade ?? ''),
  ];
  if (tones.contains(HadithJudgmentTone.weak)) return HadithJudgmentTone.weak;
  if (tones.contains(HadithJudgmentTone.chainWarning)) {
    return HadithJudgmentTone.chainWarning;
  }
  return HadithJudgmentTone.neutral;
}

/// Meaningful source rulings, in source-field order, without interpretation.
List<({bool expanded, String text})> hadithSourceRulings(HadithBase hadith) {
  final expanded = hadith is DetailedHadith ? hadith.explainGrade : null;
  return [
    if (hasHadithMetadata(hadith.grade)) (expanded: false, text: hadith.grade),
    if (hasHadithMetadata(expanded) && expanded != hadith.grade)
      (expanded: true, text: expanded!),
  ];
}

/// Compact display retains both supplied rulings when they differ.
String hadithRulingText(HadithBase hadith) =>
    hadithSourceRulings(hadith).map((ruling) => ruling.text).join('\n');
