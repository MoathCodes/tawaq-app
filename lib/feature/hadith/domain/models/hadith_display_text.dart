import 'package:dorar_hadith/dorar_hadith.dart';

/// Dorar category listings prefix narration with a presentation dash.
/// Restrict the display projection to that verified endpoint. The record and
/// its source document stay unchanged, including their annotation offsets.
String hadithDisplayText(DetailedHadith hadith) {
  final uri = hadith.provenance?.sourceUri ?? hadith.content?.sourceUri;
  if (uri?.path.startsWith('/hadith-category/cat/') == true) {
    return hadith.hadith.replaceFirst(RegExp(r'^\s*-\s+'), '');
  }
  return hadith.hadith;
}
