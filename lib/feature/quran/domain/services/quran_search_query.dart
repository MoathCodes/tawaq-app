import 'package:tawaq/core/text/arabic_search_normalize.dart';

/// Normalizes picker search text without changing Quran source or display text.
String normalizeQuranSearchQuery(String query) {
  final digits = query.replaceAllMapped(RegExp('[٠-٩]'), (match) {
    return (match[0]!.codeUnitAt(0) - 0x0660).toString();
  });
  return normalizeArabicForSearch(digits.toLowerCase().trim());
}
