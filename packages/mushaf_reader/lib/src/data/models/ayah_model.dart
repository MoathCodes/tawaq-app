import 'package:freezed_annotation/freezed_annotation.dart';

part 'ayah_model.freezed.dart';

@freezed
abstract class AyahModel with _$AyahModel {
  factory AyahModel({
    required int id,
    required int page,
    required int surah,
    required int numberInSurah,
    required String codeV4,
  }) = _AyahModel;
}
