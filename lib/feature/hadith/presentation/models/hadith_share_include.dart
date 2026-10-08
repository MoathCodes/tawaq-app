import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_judgment.dart';

enum HadithShareInclude {
  narrator,
  muhaddith,
  source,
  number,
  grade,
  takhrij,
  sharh,
  usul,
  appName,
}

class HadithShareOptions {
  const new(this.includes);

  factory defaults() {
    return const HadithShareOptions({
      HadithShareInclude.narrator,
      HadithShareInclude.source,
      HadithShareInclude.grade,
      HadithShareInclude.appName,
    });
  }

  final Set<HadithShareInclude> includes;

  bool contains(HadithShareInclude value) => includes.contains(value);

  HadithShareOptions copyWith(Set<HadithShareInclude> next) =>
      HadithShareOptions(next);

  HadithShareOptions constrained({
    required DetailedHadith hadith,
    required bool sharhAvailable,
    required bool usulAvailable,
  }) {
    final next = {...includes};
    if (!hasHadithMetadata(hadith.rawi)) {
      next.remove(HadithShareInclude.narrator);
    }
    if (!hasHadithMetadata(hadith.mohdith)) {
      next.remove(HadithShareInclude.muhaddith);
    }
    if (!hasHadithMetadata(hadith.book)) next.remove(HadithShareInclude.source);
    if (!hasHadithMetadata(hadith.numberOrPage)) {
      next.remove(HadithShareInclude.number);
    }
    if (hadithSourceRulings(hadith).isEmpty)
      next.remove(HadithShareInclude.grade);
    if (!hasHadithMetadata(hadith.takhrij)) {
      next.remove(HadithShareInclude.takhrij);
    }
    if (requiresHadithJudgment(hadith) &&
        hadithSourceRulings(hadith).isNotEmpty) {
      next.add(HadithShareInclude.grade);
    }
    if (!sharhAvailable) next.remove(HadithShareInclude.sharh);
    if (!usulAvailable) next.remove(HadithShareInclude.usul);
    return HadithShareOptions(next);
  }
}

/// Check both source fields: the expanded ruling may qualify a short grade.
bool requiresHadithJudgment(DetailedHadith hadith) =>
    hadith.verdictTone == VerdictTone.negative ||
    hadithSourceJudgmentTone(hadith) != HadithJudgmentTone.neutral;
