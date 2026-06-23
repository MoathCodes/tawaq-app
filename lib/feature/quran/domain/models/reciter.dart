import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_pick_intent.dart';
import 'package:tawaq/feature/quran/domain/services/reciter_tags.dart';

part 'reciter.freezed.dart';
part 'reciter.g.dart';

/// A single recitation (moshaf/riwaya) for a [Reciter] from mp3quran.net.
@freezed
abstract class Moshaf with _$Moshaf {
  /// Creates a [Moshaf].
  const factory Moshaf({
    /// mp3quran moshaf id.
    required int id,

    /// Display name of the recitation (e.g. "حفص عن عاصم - مرتل").
    required String name,

    /// Base server URL ending in `/`. Surah files live at `$server${NNN}.mp3`.
    required String server,

    /// Surah numbers (1-114) this moshaf provides audio for.
    required List<int> surahList,

    /// Number of surahs available.
    required int surahTotal,

    /// `read` id from the ayat_timing API when this moshaf has ayah timing.
    int? timingReadId,
  }) = _Moshaf;

  const Moshaf._();

  /// Creates a [Moshaf] from JSON (disk cache form).
  factory Moshaf.fromJson(Map<String, dynamic> json) => _$MoshafFromJson(json);

  /// Whether ayah-by-ayah timing data is available for this moshaf.
  bool get hasTiming => timingReadId != null;

  /// Whether [surah] is available in this moshaf.
  bool hasSurah(int surah) => surahList.contains(surah);
}

/// A Quran reciter with one or more [Moshaf] recitations.
@freezed
abstract class Reciter with _$Reciter {
  /// Creates a [Reciter].
  const factory Reciter({
    /// mp3quran reciter id.
    required int id,

    /// Reciter display name (Arabic).
    required String name,

    /// Available recitations for this reciter.
    required List<Moshaf> moshaf,
  }) = _Reciter;

  const Reciter._();

  /// Creates a [Reciter] from JSON (disk cache form).
  factory Reciter.fromJson(Map<String, dynamic> json) =>
      _$ReciterFromJson(json);

  /// Whether any moshaf for this reciter has ayah timing.
  bool get hasTiming => moshaf.any((m) => m.hasTiming);

  /// The first moshaf, preferring one with timing data.
  Moshaf? get primaryMoshaf {
    if (moshaf.isEmpty) return null;
    for (final m in moshaf) {
      if (m.hasTiming) return m;
    }
    return moshaf.first;
  }

  /// Resolves [moshafId] within this reciter, or [primaryMoshaf] when unset.
  Moshaf? resolveMoshaf(int? moshafId) {
    if (moshafId != null) {
      for (final m in moshaf) {
        if (m.id == moshafId) return m;
      }
    }
    return primaryMoshaf;
  }

  /// Picks a moshaf based on playback [intent].
  Moshaf? resolveMoshafForIntent(
    int? moshafId,
    RecitationPickIntent intent,
  ) {
    if (intent == RecitationPickIntent.general) {
      return resolveMoshaf(moshafId);
    }
    final saved = resolveMoshaf(moshafId);
    if (saved != null && saved.hasTiming) return saved;
    return _bestTimedMoshaf(preferred: saved) ?? saved;
  }

  Moshaf? _bestTimedMoshaf({Moshaf? preferred}) {
    if (moshaf.isEmpty) return null;
    final timed = moshaf.where((m) => m.hasTiming).toList();
    if (timed.isEmpty) return null;

    if (preferred != null) {
      final tags = moshafTags(preferred.name);
      for (final m in timed) {
        final t = moshafTags(m.name);
        if (tags.riwayah != null && t.riwayah == tags.riwayah) return m;
      }
      for (final m in timed) {
        final t = moshafTags(m.name);
        if (tags.style != null && t.style == tags.style) return m;
      }
    }
    return timed.first;
  }
}
