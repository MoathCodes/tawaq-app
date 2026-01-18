import 'package:hive_ce/hive.dart';
import 'package:mushaf_reader/src/data/models/ayah.dart';
import 'package:mushaf_reader/src/data/models/juz.dart';
import 'package:mushaf_reader/src/data/models/page_layouts.dart';
import 'package:mushaf_reader/src/data/models/revelation_type.dart';
import 'package:mushaf_reader/src/data/models/surah.dart';

@GenerateAdapters([
  AdapterSpec<Ayah>(),
  AdapterSpec<PageLayouts>(),
  AdapterSpec<Juz>(),
  AdapterSpec<Surah>(),
  AdapterSpec<RevelationType>(),
], firstTypeId: 379)
part 'hive_adapters.g.dart';
