/// How often a title is recited (from the `freq` column).
enum HisnRecurrence {
  /// Daily (`d`).
  daily,

  /// Weekly (`w`).
  weekly,

  /// Monthly (`m`).
  monthly,

  /// Yearly (`y`).
  yearly;

  /// Parses the database `freq` code.
  static HisnRecurrence fromDb(String code) => switch (code) {
        'd' => daily,
        'w' => weekly,
        'm' => monthly,
        'y' => yearly,
        _ => daily,
      };

  /// Database `freq` code.
  String get dbCode => switch (this) {
        daily => 'd',
        weekly => 'w',
        monthly => 'm',
        yearly => 'y',
      };
}

/// Search matching strategy.
enum HisnSearchMode {
  /// Single substring match (`LIKE %query%`).
  typical,

  /// All words must appear.
  allWords,

  /// Any word may appear.
  anyWords,
}

/// Whether to search titles or contents.
enum HisnSearchTarget {
  /// Search chapter/title names.
  title,

  /// Search dhikr body text.
  content,
}

/// Authenticity / ruling (`hokm`) values stored in the database.
enum HisnAuthenticity {
  /// Quranic text.
  quran('قرآن'),

  /// Sahih (authentic).
  sahih('صحيح'),

  /// Hasan (good).
  hasan('حسن'),

  /// Da'eef (weak).
  daeif('ضعيف'),

  /// Mawdu' (fabricated).
  mawdu('موضوع'),

  /// Athar (trace/narration).
  athar('أثر');

  /// Creates an authenticity value from the database `hokm` string.
  const HisnAuthenticity(this.dbValue);

  /// Exact value stored in the `hokm` column.
  final String dbValue;

  /// Parses a database `hokm` string, or returns null if unknown/empty.
  static HisnAuthenticity? tryParse(String? hokm) {
    if (hokm == null || hokm.isEmpty) return null;
    for (final value in values) {
      if (value.dbValue == hokm) return value;
    }
    return null;
  }
}

/// Hadith source book filters (matched as substrings in `source`).
enum HisnSourceFilter {
  /// Quranic source marker.
  quran('سورة', isHokm: false),

  /// Sahih al-Bukhari.
  sahihBukhari('بخار', isHokm: false),

  /// Sahih Muslim.
  sahihMuslim('مسلم', isHokm: false),

  /// Sunan Abu Dawood.
  abuDawood('داود', isHokm: false),

  /// Jami` at-Tirmidhi.
  atTirmidhi('الترمذي', isHokm: false),

  /// Sunan an-Nasa'i.
  anNasai('نسا', isHokm: false),

  /// Sunan Ibn Majah.
  ibnMajah('ماجه', isHokm: false),

  /// Muwatta Malik.
  malik('موط', isHokm: false),

  /// Sunan ad-Darami.
  adDarami('دارم', isHokm: false),

  /// Musnad Ahmad.
  ahmad('أحمد', isHokm: false),

  /// Ibn Sunni.
  ibnSunny('السني', isHokm: false),

  /// Al-Hakim.
  hakim('حاكم', isHokm: false),

  /// Al-Bayhaqi.
  bayhaqi('بيهق', isHokm: false),

  /// At-Tabarani.
  atTabarani('طبران', isHokm: false),

  /// Athar.
  atharSource('أثر', isHokm: false);

  /// Creates a source filter.
  const HisnSourceFilter(this.lookupWord, {required this.isHokm});

  /// Substring to match in `source` or `hokm`.
  final String lookupWord;

  /// Whether this filter applies to `hokm` instead of `source`.
  final bool isHokm;
}
