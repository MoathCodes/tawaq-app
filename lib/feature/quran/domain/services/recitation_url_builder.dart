/// Normalizes an mp3quran server/folder URL so trailing-slash differences
/// do not break timing-read linkage.
String normalizeRecitationServerUrl(String server) {
  final trimmed = server.trim();
  if (trimmed.isEmpty) return trimmed;
  return trimmed.endsWith('/') ? trimmed : '$trimmed/';
}

/// Builds the full-surah audio URL for an mp3quran moshaf server.
///
/// mp3quran serves one MP3 per surah at `$server${NNN}.mp3`, where `NNN` is the
/// surah number zero-padded to three digits, e.g.
/// `https://server6.mp3quran.net/akdr/001.mp3`.
String surahAudioUrl(String server, int surah) {
  final base = normalizeRecitationServerUrl(server);
  return '$base${surah.toString().padLeft(3, '0')}.mp3';
}
