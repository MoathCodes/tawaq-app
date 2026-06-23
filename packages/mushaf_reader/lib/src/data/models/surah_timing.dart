import 'package:freezed_annotation/freezed_annotation.dart';

part 'surah_timing.freezed.dart';
part 'surah_timing.g.dart';

/// Start/end offsets (ms) of a single ayah inside a surah's audio file.
@freezed
abstract class AyahTiming with _$AyahTiming {
  /// Creates an [AyahTiming].
  const factory AyahTiming({
    /// Ayah number within the surah (the API may include 0 for an intro).
    required int ayah,

    /// Start offset in milliseconds into the surah MP3.
    required int startMs,

    /// End offset in milliseconds into the surah MP3.
    required int endMs,
  }) = _AyahTiming;

  /// Creates an [AyahTiming] from JSON (disk cache form).
  factory AyahTiming.fromJson(Map<String, dynamic> json) =>
      _$AyahTimingFromJson(json);
}

/// Ayah timing for a whole surah from a specific `read`.
@freezed
abstract class SurahTiming with _$SurahTiming {
  /// Creates a [SurahTiming].
  const factory SurahTiming({
    /// Surah number (1-114).
    required int surah,

    /// The ayat_timing `read` id these timings belong to.
    required int readId,

    /// Per-ayah timings ordered by ayah number.
    required List<AyahTiming> ayat,
  }) = _SurahTiming;

  const SurahTiming._();

  /// Creates a [SurahTiming] from JSON (disk cache form).
  factory SurahTiming.fromJson(Map<String, dynamic> json) =>
      _$SurahTimingFromJson(json);

  /// Timing for [ayahNumber], or null when absent.
  AyahTiming? forAyah(int ayahNumber) {
    for (final t in ayat) {
      if (t.ayah == ayahNumber) return t;
    }
    return null;
  }

  /// The ayah (number > 0) whose window contains [positionMs], or null.
  ///
  /// Ignores the optional ayah-0 intro so highlighting starts at ayah 1.
  /// Uses binary search over playable ayat (assumes non-overlapping windows
  /// sorted by [AyahTiming.startMs]).
  int? ayahAt(int positionMs) {
    final playable = _playableAyat;
    if (playable.isEmpty) return null;

    var lo = 0;
    var hi = playable.length - 1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      final timing = playable[mid];
      if (positionMs < timing.startMs) {
        hi = mid - 1;
      } else if (positionMs >= timing.endMs) {
        lo = mid + 1;
      } else {
        return timing.ayah;
      }
    }
    return null;
  }

  /// Total audio length in milliseconds: the largest ayah `endMs`. Used as a
  /// duration fallback/seed before the player reports its own duration.
  int get totalMs {
    var max = 0;
    for (final t in ayat) {
      if (t.ayah <= 0) continue;
      if (t.endMs > max) max = t.endMs;
    }
    return max;
  }

  /// Lowest playable ayah number (skips the optional ayah-0 intro).
  int? get firstAyah {
    int? min;
    for (final t in ayat) {
      if (t.ayah <= 0) continue;
      if (min == null || t.ayah < min) min = t.ayah;
    }
    return min;
  }

  List<AyahTiming> get _playableAyat {
    final playable = <AyahTiming>[];
    for (final t in ayat) {
      if (t.ayah > 0) playable.add(t);
    }
    return playable;
  }
}
