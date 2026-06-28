/// Arabic ordinal helpers for Quran Juz/Hizb divisions.
library;

const _arabicOnes = <String>[
  '',
  'الأول',
  'الثاني',
  'الثالث',
  'الرابع',
  'الخامس',
  'السادس',
  'السابع',
  'الثامن',
  'التاسع',
];

const _arabicTeens = <String>[
  'العاشر',
  'الحادي عشر',
  'الثاني عشر',
  'الثالث عشر',
  'الرابع عشر',
  'الخامس عشر',
  'السادس عشر',
  'السابع عشر',
  'الثامن عشر',
  'التاسع عشر',
];

const _arabicTens = <String>[
  '',
  '',
  'العشرون',
  'الثلاثون',
  'الأربعون',
  'الخمسون',
  'الستون',
];

const _arabicOnesAnd = <String>[
  '',
  'الحادي',
  'الثاني',
  'الثالث',
  'الرابع',
  'الخامس',
  'السادس',
  'السابع',
  'الثامن',
  'التاسع',
];

String _arabicOrdinal(int n) {
  if (n < 1 || n > 60) return '$n';
  if (n <= 9) return _arabicOnes[n];
  if (n < 20) return _arabicTeens[n - 10];
  final tens = n ~/ 10;
  final ones = n % 10;
  if (ones == 0) return _arabicTens[tens];
  return '${_arabicOnesAnd[ones]} و${_arabicTens[tens]}';
}

/// Arabic ordinal for Juz numbers 1–30 (الأول … الثلاثون).
String arabicJuzOrdinal(int n) => _arabicOrdinal(n);

/// Arabic ordinal for Hizb numbers 1–60 (الأول … الستون).
String arabicHizbOrdinal(int n) => _arabicOrdinal(n);
