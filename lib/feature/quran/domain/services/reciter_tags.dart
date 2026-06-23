/// Recitation style of a moshaf, derived from its Arabic name.
enum RecitationStyle {
  /// Measured, melodic-but-plain recitation (مرتل).
  murattal,

  /// Embellished, tajwid-showcase recitation (مجوّد).
  mujawwad,
}

/// Canonical riwayah labels mapped to the substrings that identify them in a
/// moshaf name (mp3quran names read e.g. "حفص عن عاصم - مرتل").
const _riwayat = <String, List<String>>{
  'حفص': ['حفص'],
  'شعبة': ['شعبة'],
  'ورش': ['ورش'],
  'قالون': ['قالون'],
  'الدوري': ['الدوري', 'دوري'],
  'السوسي': ['السوسي', 'سوسي'],
  'قنبل': ['قنبل'],
  'البزي': ['البزي', 'بزي'],
  'خلف': ['خلف'],
  'خلاد': ['خلاد'],
  'ابن ذكوان': ['ابن ذكوان', 'ذكوان'],
  'هشام': ['هشام'],
};

/// Tags parsed from a moshaf [moshafName]: its recitation style and the
/// canonical riwayah label, either of which may be null when not recognized.
({RecitationStyle? style, String? riwayah}) moshafTags(String moshafName) {
  final name = moshafName.trim();

  RecitationStyle? style;
  if (name.contains('مجود') || name.contains('مجوّد')) {
    style = RecitationStyle.mujawwad;
  } else if (name.contains('مرتل')) {
    style = RecitationStyle.murattal;
  }

  String? riwayah;
  for (final entry in _riwayat.entries) {
    if (entry.value.any(name.contains)) {
      riwayah = entry.key;
      break;
    }
  }

  return (style: style, riwayah: riwayah);
}
