import 'package:dorar_hadith/dorar_hadith.dart';

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
    if (hadith.rawi.trim().isEmpty) next.remove(HadithShareInclude.narrator);
    if (hadith.mohdith.trim().isEmpty) {
      next.remove(HadithShareInclude.muhaddith);
    }
    if (hadith.book.trim().isEmpty) next.remove(HadithShareInclude.source);
    if (hadith.numberOrPage.trim().isEmpty) {
      next.remove(HadithShareInclude.number);
    }
    if (hadith.hukm.trim().isEmpty) next.remove(HadithShareInclude.grade);
    if ((hadith.takhrij ?? '').trim().isEmpty) {
      next.remove(HadithShareInclude.takhrij);
    }
    if (!sharhAvailable) next.remove(HadithShareInclude.sharh);
    if (!usulAvailable) next.remove(HadithShareInclude.usul);
    return HadithShareOptions(next);
  }
}
