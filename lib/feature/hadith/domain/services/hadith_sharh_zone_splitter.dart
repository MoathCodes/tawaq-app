import 'package:tawaq/core/text/dorar_text_cleaner.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_sharh_zones.dart';

/// Splits raw Dorar sharh text into matn prefix, metadata, and commentary
/// zones.
abstract final class HadithSharhZoneSplitter {
  static final _rawiMarker = RegExp(r'الراوي\s*:');
  static final _takhrijEnd = RegExp(
    r'التخريج\s*:[\s\S]*?(?=\n\s*\n|\Z)',
  );
  static final _khulasaEnd = RegExp(
    r'خلاصة حكم المحدث\s*:[\s\S]*?(?=\n\s*\n|\Z)',
  );
  static final _sharhIdPlaceholder = RegExp(r'^\d{4,7}$');

  /// Splits [raw] into structural zones.
  static HadithSharhZones split(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const HadithSharhZones(commentary: '');
    }

    final text = raw.replaceAll('\r\n', '\n');
    final rawiMatch = _rawiMarker.firstMatch(text);
    if (rawiMatch == null) {
      return HadithSharhZones(commentary: _cleanCommentary(text));
    }

    final matnPrefix = text.substring(0, rawiMatch.start).trim();
    final afterRawi = text.substring(rawiMatch.start);

    final takhrijMatch = _takhrijEnd.firstMatch(afterRawi);
    final khulasaMatch = _khulasaEnd.firstMatch(afterRawi);
    final metadataEnd = takhrijMatch?.end ?? khulasaMatch?.end;

    if (metadataEnd == null) {
      return HadithSharhZones(
        matnPrefix: matnPrefix.isEmpty ? null : matnPrefix,
        metadata: _cleanMetadata(afterRawi.trim()),
        commentary: '',
      );
    }

    final metadata = afterRawi.substring(0, metadataEnd).trim();
    final commentary = afterRawi.substring(metadataEnd).trim();

    return HadithSharhZones(
      matnPrefix: matnPrefix.isEmpty ? null : matnPrefix,
      metadata: metadata.isEmpty ? null : _cleanMetadata(metadata),
      commentary: _cleanCommentary(commentary),
    );
  }

  static String _cleanMetadata(String input) {
    return DorarTextCleaner.cleanMetadataZone(input);
  }

  static String _cleanCommentary(String input) {
    final cleaned = DorarTextCleaner.cleanCommentaryZone(input);

    // Dorar sometimes returns another sharh ID instead of commentary text.
    if (_sharhIdPlaceholder.hasMatch(cleaned)) {
      return '';
    }

    return cleaned;
  }
}
