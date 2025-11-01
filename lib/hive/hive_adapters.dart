import 'package:adhan_dart/adhan_dart.dart';
import 'package:hasanat/feature/prayer/data/models/prayer_completion.dart';
import 'package:hivez_flutter/hivez_flutter.dart';

part 'hive_adapters.g.dart';

@GenerateAdapters([
  AdapterSpec<PrayerCompletion>(),
  AdapterSpec<Prayer>(),
  AdapterSpec<CompletionStatus>(),
])
class HiveAdapters {}
