import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_models.dart';
import 'package:tawaq/feature/quran/domain/models/reciter.dart';

/// Maps global endpoints to the first surah-local segment to load.
///
/// When [to] is null the range is open-ended and continues to the end of the
/// Quran.
({int surah, int startAyah, int endAyah}) firstSegmentForRange({
  required AyahReference from,
  required AyahReference? to,
  required MushafReaderController mushaf,
}) {
  final surah = from.surah;
  final ayahCount = mushaf.getSurahSync(surah)?.ayahCount ?? from.ayah;
  final endAyah = to != null && from.surah == to.surah ? to.ayah : ayahCount;
  return (surah: surah, startAyah: from.ayah, endAyah: endAyah);
}

/// Returns the next segment after finishing [currentSurah] in a global range.
///
/// When [to] is null the range is open-ended and continues to the end of the
/// Quran.
({int surah, int startAyah, int endAyah})? nextSegmentForRange({
  required AyahReference from,
  required AyahReference? to,
  required int currentSurah,
  required MushafReaderController mushaf,
}) {
  final nextSurah = currentSurah + 1;
  if (to != null) {
    if (nextSurah > to.surah) return null;
    if (nextSurah < from.surah) return null;
  } else if (nextSurah > 114) {
    return null;
  }

  final startAyah = nextSurah == from.surah ? from.ayah : 1;
  final ayahCount = mushaf.getSurahSync(nextSurah)?.ayahCount ?? 1;
  final endAyah = to != null && nextSurah == to.surah ? to.ayah : ayahCount;
  return (surah: nextSurah, startAyah: startAyah, endAyah: endAyah);
}

/// Whether [from]/[to] span whole surah(s): ayah 1 of [from.surah] through the
/// last ayah of [to.surah] (same or different surahs).
bool isWholeSurahEndpoints(
  AyahReference from,
  AyahReference? to,
  MushafReaderController mushaf,
) {
  if (to == null) return false;
  if (from.surah > to.surah) return false;
  if (from.ayah != 1) return false;
  final toCount = mushaf.getSurahSync(to.surah)?.ayahCount;
  return toCount != null && to.ayah == toCount;
}

/// Whether a surah-local segment covers the full surah file.
bool isFullSurahSegment({
  required int surah,
  required int startAyah,
  required int endAyah,
  required MushafReaderController mushaf,
}) {
  if (startAyah != 1) return false;
  final count = mushaf.getSurahSync(surah)?.ayahCount;
  return count != null && endAyah == count;
}

/// Whether the resolved range requires ayah-by-ayah timing data.
bool rangeNeedsAyahTiming({
  required RangeScopePreset preset,
  required AyahReference from,
  required AyahReference? to,
  required MushafReaderController mushaf,
}) {
  switch (preset) {
    case RangeScopePreset.thisSurah:
      return false;
    case RangeScopePreset.continueFromHere:
      if (from.ayah == 1) return false;
      return true;
    case RangeScopePreset.thisAyah:
    case RangeScopePreset.thisJuz:
    case RangeScopePreset.thisHizb:
    case RangeScopePreset.custom:
      return !isWholeSurahEndpoints(from, to, mushaf);
  }
}

/// Whether the global [to] endpoint has been reached in [surah]/[endAyah].
///
/// A null [to] means the range continues to the end of the Quran.
bool isGlobalRangeComplete({
  required AyahReference? to,
  required int surah,
  required int endAyah,
  required MushafReaderController mushaf,
}) {
  if (to == null) {
    final ayahCount = mushaf.getSurahSync(surah)?.ayahCount ?? endAyah;
    return surah == 114 && endAyah >= ayahCount;
  }
  return surah > to.surah || (surah == to.surah && endAyah >= to.ayah);
}

/// Juz number for a surah-local ayah reference.
Future<int?> juzNumberForAyah(
  MushafReaderController mushaf,
  int surah,
  int ayah,
) async {
  final a = await mushaf.getAyahBySurah(surah, ayah);
  return a.juz;
}

/// Hizb number for a surah-local ayah reference.
Future<int?> hizbNumberForAyah(
  MushafReaderController mushaf,
  int surah,
  int ayah,
) async {
  final a = await mushaf.getAyahBySurah(surah, ayah);
  return a.hizb;
}

Future<({AyahReference from, AyahReference to})?> _boundsToAyahRange({
  required MushafReaderController mushaf,
  required ({int startAyahId, int endAyahId}) bounds,
}) async {
  final start = await mushaf.getAyah(bounds.startAyahId);
  final end = await mushaf.getAyah(bounds.endAyahId);
  return (
    from: AyahReference(
      surah: start.surahNumber,
      ayah: start.numberInSurah,
    ),
    to: AyahReference(
      surah: end.surahNumber,
      ayah: end.numberInSurah,
    ),
  );
}

/// Resolves juz [juzNumber] boundaries to global ayah references.
Future<({AyahReference from, AyahReference to})?> resolveJuzAyahRange({
  required MushafReaderController mushaf,
  required int juzNumber,
}) async {
  final bounds = mushaf.juzAyahBounds(juzNumber);
  if (bounds == null) return null;
  return _boundsToAyahRange(mushaf: mushaf, bounds: bounds);
}

/// Resolves hizb [hizbNumber] boundaries to global ayah references.
Future<({AyahReference from, AyahReference to})?> resolveHizbAyahRange({
  required MushafReaderController mushaf,
  required int hizbNumber,
}) async {
  final bounds = mushaf.hizbAyahBounds(hizbNumber);
  if (bounds == null) return null;
  return _boundsToAyahRange(mushaf: mushaf, bounds: bounds);
}

/// Outcome when a juz/hizb preset cannot be resolved.
enum DivisionResolveError {
  /// The seed ayah has no juz/hizb division metadata.
  numberNotFound,

  /// Division metadata exists but bounds could not be loaded.
  boundsNotFound,

  /// Unexpected failure while resolving a division preset.
  failed,
}

/// Resolved global ayah range for a juz or hizb preset.
typedef DivisionRange = ({AyahReference from, AyahReference to});

/// Resolves the juz containing [surah]/[ayah].
Future<({DivisionRange? range, DivisionResolveError? error})>
resolveJuzRangeForAyah(
  MushafReaderController mushaf,
  int surah,
  int ayah,
) async {
  try {
    final juzNum = await juzNumberForAyah(mushaf, surah, ayah);
    if (juzNum == null) {
      return (range: null, error: DivisionResolveError.numberNotFound);
    }
    final resolved = await resolveJuzAyahRange(
      mushaf: mushaf,
      juzNumber: juzNum,
    );
    if (resolved == null) {
      return (range: null, error: DivisionResolveError.boundsNotFound);
    }
    return (range: resolved, error: null);
  } on Object {
    return (range: null, error: DivisionResolveError.failed);
  }
}

/// Resolves the hizb containing [surah]/[ayah].
Future<({DivisionRange? range, DivisionResolveError? error})>
resolveHizbRangeForAyah(
  MushafReaderController mushaf,
  int surah,
  int ayah,
) async {
  try {
    final hizbNum = await hizbNumberForAyah(mushaf, surah, ayah);
    if (hizbNum == null) {
      return (range: null, error: DivisionResolveError.numberNotFound);
    }
    final resolved = await resolveHizbAyahRange(
      mushaf: mushaf,
      hizbNumber: hizbNum,
    );
    if (resolved == null) {
      return (range: null, error: DivisionResolveError.boundsNotFound);
    }
    return (range: resolved, error: null);
  } on Object {
    return (range: null, error: DivisionResolveError.failed);
  }
}

/// Intent produced from a range preset and resolved endpoints.
sealed class RecitationPlaybackIntent {
  const RecitationPlaybackIntent();
}

/// Play a whole surah from the beginning or [resumeFrom].
final class PlayWholeSurahIntent extends RecitationPlaybackIntent {
  /// Creates [PlayWholeSurahIntent].
  const PlayWholeSurahIntent({
    required this.reciter,
    required this.moshaf,
    required this.surah,
    this.resumeFrom,
  });

  final Reciter reciter;
  final Moshaf moshaf;
  final int surah;
  final Duration? resumeFrom;
}

/// Play a global ayah range starting at the first surah-local segment.
final class PlayAyahRangeIntent extends RecitationPlaybackIntent {
  /// Creates [PlayAyahRangeIntent].
  const PlayAyahRangeIntent({
    required this.reciter,
    required this.moshaf,
    required this.from,
    this.to,
    this.resumeFrom,
  });

  final Reciter reciter;
  final Moshaf moshaf;
  final AyahReference from;
  final AyahReference? to;
  final Duration? resumeFrom;
}

/// Maps a [RangeScopePreset] and resolved range endpoints to playback intent.
///
/// - Whole-surah selections (preset, `from.ayah == 1`, or full-surah endpoints)
///   map to [PlayWholeSurahIntent] when [from] and [to] share a surah.
/// - Cross-surah full-surah endpoint spans use [PlayAyahRangeIntent] so playback
///   can chain consecutive whole-surah files without timings.
/// - Partial ranges and open-ended continue require ayah timing.
RecitationPlaybackIntent playbackIntentForPreset({
  required RangeScopePreset preset,
  required Reciter reciter,
  required Moshaf moshaf,
  required AyahReference from,
  required MushafReaderController mushafReader,
  AyahReference? to,
}) {
  if (!rangeNeedsAyahTiming(
    preset: preset,
    from: from,
    to: to,
    mushaf: mushafReader,
  )) {
    if (to == null || from.surah == to.surah) {
      return PlayWholeSurahIntent(
        reciter: reciter,
        moshaf: moshaf,
        surah: from.surah,
      );
    }
    return PlayAyahRangeIntent(
      reciter: reciter,
      moshaf: moshaf,
      from: from,
      to: to,
    );
  }

  if (preset == RangeScopePreset.continueFromHere) {
    return PlayAyahRangeIntent(
      reciter: reciter,
      moshaf: moshaf,
      from: from,
      to: to,
    );
  }

  return PlayAyahRangeIntent(
    reciter: reciter,
    moshaf: moshaf,
    from: from,
    to: to,
  );
}
