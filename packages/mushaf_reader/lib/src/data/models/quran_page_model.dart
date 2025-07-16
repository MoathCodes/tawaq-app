import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mushaf_reader/src/data/models/line_model.dart';
import 'package:mushaf_reader/src/data/models/surah_block.dart';

part 'quran_page_model.freezed.dart';

@freezed
abstract class QuranPageModel with _$QuranPageModel {
  factory QuranPageModel({
    required int pageNumber,
    required String glyphText,
    required List<LineModel> lines,
    required List<SurahBlock> surahs,
    required int juzNumber,
  }) = _QuranPageModel;
}
