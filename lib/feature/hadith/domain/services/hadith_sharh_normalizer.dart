import 'package:tawaq/core/text/arabic_text_normalizer.dart';
import 'package:tawaq/core/text/dorar_text_cleaner.dart';

/// Dorar sharh text normalization layered on tafsir typography fixes.
abstract final class HadithSharhNormalizer {
  static final _asciiQuote = RegExp('"([^"]+)"');

  /// Normalizes sharh commentary for display and tokenization.
  ///
  /// Preserves ASCII `"…"` quotes (Dorar pedagogical delimiter) while applying
  /// tafsir honorific and punctuation fixes.
  static String normalize(String text) {
    if (text.isEmpty) return text;

    final preserved = <String>[];
    var masked = text.replaceAllMapped(_asciiQuote, (match) {
      preserved.add(match.group(0)!);
      return '<<<SHQ${preserved.length - 1}>>>';
    });

    masked = ArabicTextNormalizer.normalize(masked);

    for (var i = 0; i < preserved.length; i++) {
      masked = masked.replaceAll('<<<SHQ$i>>>', preserved[i]);
    }

    return DorarTextCleaner.collapseWhitespace(
      DorarTextCleaner.stripArtifacts(masked),
    );
  }
}
