import 'package:freezed_annotation/freezed_annotation.dart';

part 'recitation_models.freezed.dart';

/// Why the user is picking a reciter/moshaf — drives moshaf auto-resolution.
enum RecitationPickIntent {
  /// General listening (whole surah, drawer switch).
  general,

  /// Ayah-level playback (single ayah, range, highlight sync).
  ayahLevel,
}

/// When recitation should automatically stop ("sleep timer").
enum RecitationSleep {
  /// No sleep timer.
  off,

  /// Stop at the end of the currently playing ayah.
  endOfAyah,

  /// Stop at the end of the current selection/range.
  endOfRange,

  /// Stop at the end of the current surah.
  endOfSurah,

  /// Stop after 10 minutes.
  after10,

  /// Stop after 20 minutes.
  after20,

  /// Stop after 30 minutes.
  after30;

  /// Whether this is a wall-clock countdown (vs. a content boundary).
  bool get isCountdown => this == after10 || this == after20 || this == after30;

  /// Countdown duration for the timer-based options, else null.
  Duration? get countdown => switch (this) {
    RecitationSleep.after10 => const Duration(minutes: 10),
    RecitationSleep.after20 => const Duration(minutes: 20),
    RecitationSleep.after30 => const Duration(minutes: 30),
    _ => null,
  };
}

/// How the user scoped a memorization range in the range dialog.
enum RangeScopePreset {
  /// A single ayah (from = to).
  thisAyah,

  /// Ayah 1 through the last ayah of a surah.
  thisSurah,

  /// The juz containing the seed ayah.
  thisJuz,

  /// The hizb containing the seed ayah.
  thisHizb,

  /// Start at the seed ayah and continue to the end of the Quran.
  continueFromHere,

  /// Manually chosen endpoints.
  custom,
}

/// A surah-local ayah position used for cross-surah range playback.
@freezed
abstract class AyahReference with _$AyahReference {
  /// Creates an [AyahReference].
  const factory({
    required int surah,
    required int ayah,
  }) = _AyahReference;

  const new _();

  /// Global ayah order key for range comparisons (surah-major).
  int get globalOrder => surah * 1000 + ayah;

  /// Whether [other] is at or after this reference in Quran order.
  bool isBeforeOrEqual(AyahReference other) =>
      globalOrder <= other.globalOrder;

  /// Whether [other] is strictly after this reference.
  bool isBefore(AyahReference other) => globalOrder < other.globalOrder;
}
