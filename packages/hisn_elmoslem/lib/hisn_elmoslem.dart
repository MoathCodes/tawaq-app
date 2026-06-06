/// Hisn al-Muslim — pure Dart access to Fortress of the Muslim content.
///
/// ```dart
/// import 'package:hisn_elmoslem/hisn_elmoslem.dart';
///
/// void main() async {
///   final client = await HisnClient.open();
///
///   final titles = client.titles.all();
///   final morning = client.titles.byNameFragments([
///     HisnFeaturedTitles.morning,
///   ]).firstOrNull;
///
///   if (morning != null) {
///     final items = client.contents.byTitleId(morning.id);
///     for (final item in items) {
///       for (final line in item.lines) {
///         switch (line) {
///           case HisnPlainLine(:final text):
///             print(text);
///           case HisnQuranLine(:final presentation):
///             switch (presentation) {
///               case HisnQuranSingleAyah(:final range):
///                 print('Ayah ${range.surah}:${range.startAyah}');
///               case HisnQuranMushafPages(:final pages):
///                 print('Pages $pages');
///               case HisnQuranPassage(:final ranges):
///                 print('Passage $ranges');
///             }
///         }
///       }
///     }
///   }
///
///   client.close();
/// }
/// ```
library;

export 'src/client/hisn_client.dart';
export 'src/database/hisn_database.dart';
export 'src/models/content.dart';
export 'src/models/enums.dart';
export 'src/models/models.dart';
export 'src/data/mushaf_page_resolver.dart';
export 'src/models/quran_presentation.dart';
export 'src/parsers/quran_text_parser.dart';
export 'src/parsers/quran_presentation_classifier.dart';
export 'src/parsers/uthmani_text_resolver.dart';
export 'src/services/filter_service.dart';
