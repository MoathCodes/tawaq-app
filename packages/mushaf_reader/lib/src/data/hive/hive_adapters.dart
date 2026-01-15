import 'package:hive_ce/hive.dart';
import 'package:mushaf_reader/src/data/models/ayah_model.dart';
import 'package:mushaf_reader/src/data/models/juz_model.dart';
import 'package:mushaf_reader/src/data/models/page_layouts.dart';
import 'package:mushaf_reader/src/data/models/revelation_type.dart';
import 'package:mushaf_reader/src/data/models/surah_model.dart';

@GenerateAdapters([
  AdapterSpec<AyahModel>(),
  AdapterSpec<PageLayouts>(),
  AdapterSpec<JuzModel>(),
  AdapterSpec<SurahModel>(),
  AdapterSpec<RevelationType>(),
], firstTypeId: 379)
part 'hive_adapters.g.dart';
