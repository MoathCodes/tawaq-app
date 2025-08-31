import 'package:flutter/material.dart';

// Performance utilities for mushaf reader optimization
class PerformanceUtils {
  // Cache for Hindu-Arabic number conversion
  static final Map<int, String> _numberCache = <int, String>{};

  // Cache for font family names
  static final Map<int, String> _fontFamilyCache = <int, String>{};

  // Common text styles cache
  static final Map<String, TextStyle> _textStyleCache = <String, TextStyle>{};

  /// Clear caches if needed (for memory management)
  static void clearCaches() {
    _numberCache.clear();
    _fontFamilyCache.clear();
    _textStyleCache.clear();
  }

  /// Cache text styles to avoid recreation
  static TextStyle getCachedTextStyle(
    String key,
    TextStyle Function() builder,
  ) {
    return _textStyleCache.putIfAbsent(key, builder);
  }

  /// Get font family with caching
  static String getFontFamilyForPage(int pageNumber) {
    return _fontFamilyCache.putIfAbsent(pageNumber, () {
      return 'QuranPage_${pageNumber.toString().padLeft(3, '0')}';
    });
  }

  /// Preload font families for all pages
  static void preloadFontFamilies() {
    for (int i = 1; i <= 604; i++) {
      getFontFamilyForPage(i);
    }
  }

  /// Preload common numbers (1-604) for page numbers
  static void preloadPageNumbers() {
    for (int i = 1; i <= 604; i++) {
      toHinduArabicNumber(i);
    }
  }

  /// Convert number to Hindu-Arabic numerals with caching
  static String toHinduArabicNumber(int number) {
    return _numberCache.putIfAbsent(number, () {
      return number
          .toString()
          .replaceAll('0', '٠')
          .replaceAll('1', '١')
          .replaceAll('2', '٢')
          .replaceAll('3', '٣')
          .replaceAll('4', '٤')
          .replaceAll('5', '٥')
          .replaceAll('6', '٦')
          .replaceAll('7', '٧')
          .replaceAll('8', '٨')
          .replaceAll('9', '٩');
    });
  }
}
