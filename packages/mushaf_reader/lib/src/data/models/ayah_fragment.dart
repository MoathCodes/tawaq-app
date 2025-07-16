import 'package:freezed_annotation/freezed_annotation.dart';

part 'ayah_fragment.freezed.dart';

@freezed
abstract class AyahFragment with _$AyahFragment {
  factory AyahFragment({
    required int ayahId,
    required int start,
    required int end,
  }) = _AyahFragment;
}
