import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mushaf_reader/src/data/models/ayah_fragment.dart';

part 'line_model.freezed.dart';

@freezed
abstract class LineModel with _$LineModel {

  factory LineModel({
    required int index,
    required int start,
    required int end,
    required List<AyahFragment> fragments,
  }) = _LineModel;


}