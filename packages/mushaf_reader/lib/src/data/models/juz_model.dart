import 'package:freezed_annotation/freezed_annotation.dart';

part 'juz_model.freezed.dart';

@freezed
abstract class JuzModel with _$JuzModel {
  factory JuzModel({required int number, required String codeV4}) = _JuzModel;
  
}
