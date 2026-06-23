import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/feature/quran/domain/models/ayah_reference.dart';

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

  /// Manually chosen endpoints.
  custom,
}

/// Maps global endpoints to the first surah-local segment to load.
({int surah, int startAyah, int endAyah}) firstSegmentForRange({
  required AyahReference from,
  required AyahReference to,
  required MushafReaderController mushaf,
}) {
  final surah = from.surah;
  final ayahCount = mushaf.getSurahSync(surah)?.ayahCount ?? from.ayah;
  final endAyah = from.surah == to.surah ? to.ayah : ayahCount;
  return (surah: surah, startAyah: from.ayah, endAyah: endAyah);
}

/// Returns the next segment after finishing [currentSurah] in a global range.
({int surah, int startAyah, int endAyah})? nextSegmentForRange({
  required AyahReference from,
  required AyahReference to,
  required int currentSurah,
  required MushafReaderController mushaf,
}) {
  final nextSurah = currentSurah + 1;
  if (nextSurah > to.surah) return null;
  if (nextSurah < from.surah) return null;

  final startAyah = nextSurah == from.surah ? from.ayah : 1;
  final ayahCount = mushaf.getSurahSync(nextSurah)?.ayahCount ?? 1;
  final endAyah = nextSurah == to.surah ? to.ayah : ayahCount;
  return (surah: nextSurah, startAyah: startAyah, endAyah: endAyah);
}

/// Whether the global [to] endpoint has been reached in [surah]/[endAyah].
bool isGlobalRangeComplete({
  required AyahReference to,
  required int surah,
  required int endAyah,
}) => surah > to.surah || (surah == to.surah && endAyah >= to.ayah);

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

/// Outcome of resolving a juz/hizb preset from a seed ayah.
sealed class DivisionRangeResolveResult {
  const DivisionRangeResolveResult();
}

/// Juz/hizb range resolved to global ayah endpoints.
final class DivisionRangeResolved extends DivisionRangeResolveResult {
  /// Creates a [DivisionRangeResolved].
  const DivisionRangeResolved({required this.from, required this.to});

  /// Range start.
  final AyahReference from;

  /// Range end.
  final AyahReference to;
}

/// The seed ayah has no juz/hizb division metadata.
final class DivisionNumberNotFound extends DivisionRangeResolveResult {
  /// Creates a [DivisionNumberNotFound].
  const DivisionNumberNotFound();
}

/// Division metadata exists but bounds could not be loaded.
final class DivisionBoundsNotFound extends DivisionRangeResolveResult {
  /// Creates a [DivisionBoundsNotFound].
  const DivisionBoundsNotFound();
}

/// Unexpected failure while resolving a division preset.
final class DivisionResolveFailed extends DivisionRangeResolveResult {
  /// Creates a [DivisionResolveFailed].
  const DivisionResolveFailed();
}

/// Resolves the juz containing [surah]/[ayah] to global ayah endpoints.
Future<DivisionRangeResolveResult> resolveJuzRangeForAyah(
  MushafReaderController mushaf,
  int surah,
  int ayah,
) async {
  try {
    final juzNum = await juzNumberForAyah(mushaf, surah, ayah);
    if (juzNum == null) return const DivisionNumberNotFound();
    final range = await resolveJuzAyahRange(mushaf: mushaf, juzNumber: juzNum);
    if (range == null) return const DivisionBoundsNotFound();
    return DivisionRangeResolved(from: range.from, to: range.to);
  } on Object {
    return const DivisionResolveFailed();
  }
}

/// Resolves the hizb containing [surah]/[ayah] to global ayah endpoints.
Future<DivisionRangeResolveResult> resolveHizbRangeForAyah(
  MushafReaderController mushaf,
  int surah,
  int ayah,
) async {
  try {
    final hizbNum = await hizbNumberForAyah(mushaf, surah, ayah);
    if (hizbNum == null) return const DivisionNumberNotFound();
    final range = await resolveHizbAyahRange(
      mushaf: mushaf,
      hizbNumber: hizbNum,
    );
    if (range == null) return const DivisionBoundsNotFound();
    return DivisionRangeResolved(from: range.from, to: range.to);
  } on Object {
    return const DivisionResolveFailed();
  }
}
