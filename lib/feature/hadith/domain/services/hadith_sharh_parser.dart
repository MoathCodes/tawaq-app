import 'package:tawaq/feature/hadith/domain/models/hadith_sharh_parsed.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_sharh_segment.dart';
import 'package:tawaq/feature/hadith/domain/services/hadith_sharh_metadata_parser.dart';
import 'package:tawaq/feature/hadith/domain/services/hadith_sharh_segment_tokenizer.dart';
import 'package:tawaq/feature/hadith/domain/services/hadith_sharh_zone_splitter.dart';

/// Composes zone split, segment tokenization, and metadata parsing.
abstract final class HadithSharhParser {
  /// Parses raw Dorar sharh text into a presentation view model.
  static HadithSharhParsed parse(String raw) {
    final zones = HadithSharhZoneSplitter.split(raw);
    final segments = zones.commentary.isEmpty
        ? const <HadithSharhSegment>[]
        : HadithSharhSegmentTokenizer.tokenize(zones.commentary);
    final metadataFields = HadithSharhMetadataParser.parse(zones.metadata);

    return HadithSharhParsed(
      zones: zones,
      segments: segments,
      metadataFields: metadataFields,
    );
  }
}
