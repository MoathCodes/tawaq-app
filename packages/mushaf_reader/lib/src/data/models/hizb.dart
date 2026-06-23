import 'package:freezed_annotation/freezed_annotation.dart';

part 'hizb.freezed.dart';

/// Represents a Hizb (half-juz) division of the Holy Quran.
///
/// The Quran has 30 Juzs and 60 Hizbs (2 per Juz). Bounds are derived from
/// per-ayah [Ayah.hizbQuarter] values (1–240) at hive generation time.
@freezed
abstract class Hizb with _$Hizb {
  /// Creates a [Hizb] with its number and denormalized start metadata.
  factory Hizb({
    /// The Hizb number (1–60).
    required int number,

    /// The global Ayah ID where this Hizb begins (1–6236).
    int? startAyahId,

    /// The global Ayah ID where this Hizb ends (1–6236).
    int? endAyahId,

    /// The Mushaf page where this Hizb begins (1–604).
    int? startPage,

    /// Surah number of the first ayah in this Hizb (1–114).
    int? startSurahNumber,

    /// Ayah number within [startSurahNumber] for the first ayah in this Hizb.
    int? startAyahInSurah,

    /// The first [Ayah.hizbQuarter] value in this Hizb (= `(number - 1) * 4 + 1`).
    int? startHizbQuarter,
  }) = _Hizb;

  const Hizb._();
}
