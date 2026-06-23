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
