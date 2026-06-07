import 'package:tawaq/feature/hadith/domain/models/hadith_sharh_metadata_fields.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_sharh_segment.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_sharh_zones.dart';

/// Parsed Dorar sharh ready for presentation.
class HadithSharhParsed {
  /// Creates a parsed sharh view model.
  const HadithSharhParsed({
    required this.zones,
    required this.segments,
    required this.metadataFields,
  });

  /// Structural zones (matn prefix, metadata block, commentary).
  final HadithSharhZones zones;

  /// Tokenized commentary segments.
  final List<HadithSharhSegment> segments;

  /// Parsed metadata header fields.
  final HadithSharhMetadataFields metadataFields;

  /// Whether the sharh has displayable metadata or matn prefix content.
  bool get hasMetadataContent =>
      zones.matnPrefix != null || metadataFields.hasAny;
}
