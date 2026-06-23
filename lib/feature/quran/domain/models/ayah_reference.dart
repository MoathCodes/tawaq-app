import 'package:freezed_annotation/freezed_annotation.dart';

part 'ayah_reference.freezed.dart';

/// A surah-local ayah position used for cross-surah range playback.
@freezed
abstract class AyahReference with _$AyahReference {
  /// Creates an [AyahReference].
  const factory AyahReference({
    required int surah,
    required int ayah,
  }) = _AyahReference;

  const AyahReference._();

  /// Global ayah order key for range comparisons (surah-major).
  int get globalOrder => surah * 1000 + ayah;

  /// Whether [other] is at or after this reference in Quran order.
  bool isBeforeOrEqual(AyahReference other) =>
      globalOrder <= other.globalOrder;

  /// Whether [other] is strictly after this reference.
  bool isBefore(AyahReference other) => globalOrder < other.globalOrder;
}
