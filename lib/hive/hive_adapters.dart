import 'package:adhan_dart/adhan_dart.dart';
import 'package:hivez_flutter/hivez_flutter.dart';
import 'package:tawaq/feature/hadith/data/models/hadith_favorite.dart';
import 'package:tawaq/feature/hadith/data/models/hadith_recent_search.dart';
import 'package:tawaq/feature/prayer/data/models/prayer_completion.dart';

part 'hive_adapters.g.dart';

/// Class for generating Hive adapters.
@GenerateAdapters(
  [
    AdapterSpec<PrayerCompletion>(),
    AdapterSpec<Prayer>(),
    AdapterSpec<CompletionStatus>(),
    AdapterSpec<HadithFavorite>(),
    AdapterSpec<HadithRecentSearch>(),
  ],
)
class HiveAdapters {}
