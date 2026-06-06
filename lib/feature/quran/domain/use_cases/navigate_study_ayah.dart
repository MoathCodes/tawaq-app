/// Last global ayah id in the standard Mushaf (Al-Fatiha:1 … An-Nas:6).
const kMaxQuranAyahId = 6236;

/// Computes the next study-mode ayah id after applying [delta], or null if unchanged.
int? nextStudyAyahId({
  required int? currentAyahId,
  required int delta,
}) {
  if (currentAyahId == null) return null;

  final newAyahId = (currentAyahId + delta).clamp(1, kMaxQuranAyahId);
  if (newAyahId == currentAyahId) return null;
  return newAyahId;
}
