import 'package:tawaq/core/text/dorar_text_cleaner.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_sharh_metadata_fields.dart';

/// Parses Dorar sharh metadata zone text into structured header fields.
abstract final class HadithSharhMetadataParser {
  static final _labelRegex = RegExp(
    '(${HadithSharhMetadataLabel.displayOrder.map((label) => RegExp.escape(label.arabicLabel)).join('|')})\\s*:',
  );

  static const Map<HadithSharhMetadataLabel, _FieldKey> _labelToField = {
    HadithSharhMetadataLabel.rawi: _FieldKey.rawi,
    HadithSharhMetadataLabel.mohdith: _FieldKey.mohdith,
    HadithSharhMetadataLabel.source: _FieldKey.source,
    HadithSharhMetadataLabel.pageOrNumber: _FieldKey.pageOrNumber,
    HadithSharhMetadataLabel.grade: _FieldKey.grade,
    HadithSharhMetadataLabel.takhrij: _FieldKey.takhrij,
  };

  /// Parses a raw metadata zone string into [HadithSharhMetadataFields].
  static HadithSharhMetadataFields parse(String? rawMetadataZone) {
    if (rawMetadataZone == null || rawMetadataZone.trim().isEmpty) {
      return const HadithSharhMetadataFields();
    }

    final normalized = DorarTextCleaner.collapseMetadataForParsing(
      rawMetadataZone,
    );
    final matches = _labelRegex.allMatches(normalized).toList();
    if (matches.isEmpty) {
      return const HadithSharhMetadataFields();
    }

    String? rawi;
    String? mohdith;
    String? source;
    String? pageOrNumber;
    String? grade;
    String? takhrij;

    for (var i = 0; i < matches.length; i++) {
      final labelText = matches[i].group(1)!;
      final label = HadithSharhMetadataLabel.displayOrder.firstWhere(
        (entry) => entry.arabicLabel == labelText,
      );
      final field = _labelToField[label]!;

      final valueStart = matches[i].end;
      final valueEnd =
          i + 1 < matches.length ? matches[i + 1].start : normalized.length;
      final value = normalized.substring(valueStart, valueEnd).trim();
      if (value.isEmpty) continue;

      switch (field) {
        case _FieldKey.rawi:
          rawi = value;
        case _FieldKey.mohdith:
          mohdith = value;
        case _FieldKey.source:
          source = value;
        case _FieldKey.pageOrNumber:
          pageOrNumber = value;
        case _FieldKey.grade:
          grade = value;
        case _FieldKey.takhrij:
          takhrij = value;
      }
    }

    return HadithSharhMetadataFields(
      rawi: rawi,
      mohdith: mohdith,
      source: source,
      pageOrNumber: pageOrNumber,
      grade: grade,
      takhrij: takhrij,
    );
  }
}

enum _FieldKey {
  rawi,
  mohdith,
  source,
  pageOrNumber,
  grade,
  takhrij,
}
