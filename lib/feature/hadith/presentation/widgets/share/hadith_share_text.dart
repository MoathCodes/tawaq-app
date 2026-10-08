import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_judgment.dart';
import 'package:tawaq/l10n/app_localizations.dart';

/// Copy the complete source text and attribution independently of image options.
/// The source ruling is always included when available.
String hadithShareText(DetailedHadith hadith, AppLocalizations l10n) {
  final lines = <String>[hadith.hadith, ''];
  void field(String label, String value) {
    if (hasHadithMetadata(value)) lines.add('$label: $value');
  }

  for (final ruling in hadithSourceRulings(hadith)) {
    field(
      ruling.expanded ? l10n.hadithGradeExplanation : l10n.hadithGrade,
      ruling.text,
    );
  }
  field(l10n.hadithNarrator, hadith.rawi);
  field(l10n.hadithMuhaddith, hadith.mohdith);
  field(l10n.hadithSource, hadith.book);
  field(l10n.hadithNumberOrPage, hadith.numberOrPage);
  field(l10n.hadithTakhrij, hadith.takhrij ?? '');
  return lines.join('\n');
}
