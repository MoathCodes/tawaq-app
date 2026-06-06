import '../database/hisn_database.dart';
import '../models/content.dart';

/// Resolves Quranic text from the bundled Uthmani database.
final class UthmaniTextResolver {
  /// Creates a resolver backed by [database].
  UthmaniTextResolver(this._database);

  final HisnDatabase _database;

  /// Fetches concatenated Uthmani Arabic for a verse range.
  String getArabicText({
    required int surah,
    required int startAyah,
    required int endAyah,
  }) {
    final result = _database.uthmani.select('''
SELECT text, ayah FROM arabic_text
WHERE sura = ? AND ayah BETWEEN ? AND ?
ORDER BY ayah
''', [surah, startAyah, endAyah]);

    if (result.isEmpty) return '';

    final buffer = StringBuffer();
    for (final row in result) {
      if (buffer.isNotEmpty) buffer.write(' ');
      buffer
        ..write(row['text'])
        ..write(' ')
        ..write(_toArabicNumeral(row['ayah']! as int));
    }
    return buffer.toString().trim();
  }

  /// Resolves all Quranic lines in [content] to plain Arabic text.
  HisnContent resolvePlainText(HisnContent content) {
    if (!content.isQuranic) return content;

    final resolvedLines = content.lines.map((line) {
      if (line is! HisnQuranLine) return line;

      final texts = <String>[];
      for (final range in line.ranges) {
        final text = getArabicText(
          surah: range.surah,
          startAyah: range.startAyah,
          endAyah: range.endAyah,
        );
        if (text.isNotEmpty) texts.add(' ﴿ $text ﴾');
      }

      return HisnPlainLine(texts.join('\n\n'));
    }).toList();

    return HisnContent(
      id: content.id,
      titleId: content.titleId,
      order: content.order,
      repeatCount: content.repeatCount,
      lines: resolvedLines,
      rawContent: content.rawContent,
      virtue: content.virtue,
      source: content.source,
      hokm: content.hokm,
      searchText: content.searchText,
      audio: content.audio,
      commentary: content.commentary,
    );
  }

  static String _toArabicNumeral(int number) {
    const easternArabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number
        .toString()
        .split('')
        .map((digit) => easternArabic[int.parse(digit)])
        .join();
  }
}

/// Extension to resolve plain text on content.
extension HisnContentPlainTextX on HisnContent {
  /// Returns content with [HisnQuranLine] replaced by resolved Arabic prose.
  HisnContent resolvePlainText(UthmaniTextResolver resolver) =>
      resolver.resolvePlainText(this);

  /// Joins all lines into a single plain-text string after Quranic resolution.
  String toPlainText(UthmaniTextResolver resolver) {
    final resolved = resolvePlainText(resolver);
    return resolved.lines
        .map((line) => switch (line) {
              HisnPlainLine(:final text) => text,
              HisnQuranLine() => '',
            })
        .where((text) => text.isNotEmpty)
        .join('\n\n');
  }
}
