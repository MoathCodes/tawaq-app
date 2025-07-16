import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mushaf_reader/src/data/models/ayah_fragment.dart';

part 'surah_block.freezed.dart';

@freezed
abstract class SurahBlock with _$SurahBlock {
  const factory SurahBlock({
    required int surahNumber,
    required String glyph,
    required int start,
    required int end,
    required bool hasBasmalah,
    required List<AyahFragment> ayahs,
  }) = _SurahBlock;
}
