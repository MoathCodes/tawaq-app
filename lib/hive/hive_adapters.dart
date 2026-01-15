import 'package:adhan_dart/adhan_dart.dart';
import 'package:hasanat/feature/prayer/data/models/prayer_completion.dart';
import 'package:hivez_flutter/hivez_flutter.dart';

part 'hive_adapters.g.dart';

/// Class for generating Hive adapters.
@GenerateAdapters(
  [
    AdapterSpec<PrayerCompletion>(),
    AdapterSpec<Prayer>(),
    AdapterSpec<CompletionStatus>(),
  ],
)
class HiveAdapters {}
